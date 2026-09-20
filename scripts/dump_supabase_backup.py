#!/usr/bin/env python3
"""Dump the old hosted Book Track Supabase project (tables, auth, storage) locally."""

from __future__ import annotations

import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
PAGE_SIZE = 1000
SUPABASE_REF = "oshnlbnwpbtjbjpqnuvl"
KNOWN_TABLES = [
    "books",
    "library",
    "library_books",
    "library_book_formats",
    "progress_events",
    "user_settings",
    "profiles",
]


def _env_file_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def _json_from_cli(stdout: str) -> object:
    for index, char in enumerate(stdout):
        if char in "[{":
            return json.loads(stdout[index:])
    raise ValueError("no JSON in supabase CLI output")


def _service_role_key() -> str:
    completed = subprocess.run(
        [
            "supabase",
            "projects",
            "api-keys",
            "--project-ref",
            SUPABASE_REF,
            "-o",
            "json",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        sys.exit(completed.stderr or "supabase projects api-keys failed")
    keys = _json_from_cli(completed.stdout)
    if not isinstance(keys, list):
        sys.exit("unexpected api-keys payload")
    for item in keys:
        if not isinstance(item, dict):
            continue
        if item.get("name") == "service_role" and item.get("api_key"):
            return str(item["api_key"])
    sys.exit("service_role key not in api-keys payload")


def _headers(key: str) -> dict[str, str]:
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
    }


def _request_json(
    url: str,
    headers: dict[str, str],
    data: bytes | None = None,
    method: str = "GET",
) -> tuple[object, dict[str, str], int]:
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
            payload: object = json.loads(raw) if raw else None
            return payload, dict(response.headers.items()), response.status
    except urllib.error.HTTPError as error:
        body = error.read()
        raise RuntimeError(f"{method} {url} -> {error.code}: {body[:400]!r}") from error


def _write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, default=str) + "\n")


def _openapi_tables(openapi: object) -> list[str]:
    if not isinstance(openapi, dict):
        return []
    paths = openapi.get("paths")
    if not isinstance(paths, dict):
        return []
    tables: list[str] = []
    for path in paths:
        if not isinstance(path, str) or not path.startswith("/") or path.count("/") != 1:
            continue
        name = path[1:]
        if name.startswith("rpc/") or not name:
            continue
        tables.append(name)
    return sorted(set(tables))


def _fetch_table_rows(supabase_url: str, headers: dict[str, str], table: str) -> list[object]:
    rows: list[object] = []
    offset = 0
    while True:
        query = urllib.parse.urlencode({"select": "*", "order": "id.asc"})
        url = f"{supabase_url}/rest/v1/{table}?{query}"
        request_headers = {
            **headers,
            "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
            "Prefer": "count=exact",
        }
        try:
            payload, response_headers, _status = _request_json(url, request_headers)
        except RuntimeError as error:
            if "42703" in str(error) or "does not exist" in str(error):
                payload, response_headers, _status = _request_json(
                    f"{supabase_url}/rest/v1/{table}?select=*",
                    {
                        **headers,
                        "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
                        "Prefer": "count=exact",
                    },
                )
            else:
                raise
        if not isinstance(payload, list):
            raise RuntimeError(f"{table} did not return a JSON array")
        rows.extend(payload)
        if len(payload) < PAGE_SIZE:
            content_range = response_headers.get("Content-Range") or response_headers.get(
                "content-range"
            )
            suffix = f" ({content_range})" if content_range else ""
            print(f"  {table}: {len(rows)} rows{suffix}")
            return rows
        offset += PAGE_SIZE


def _download(url: str, headers: dict[str, str], dest: Path) -> None:
    request = urllib.request.Request(url, headers=headers)
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(request) as response, dest.open("wb") as out:
        while True:
            chunk = response.read(1024 * 256)
            if not chunk:
                break
            out.write(chunk)


def _list_storage_objects(
    supabase_url: str, headers: dict[str, str], bucket: str, prefix: str = ""
) -> list[dict]:
    objects: list[dict] = []
    offset = 0
    while True:
        payload, _, _ = _request_json(
            f"{supabase_url}/storage/v1/object/list/{urllib.parse.quote(bucket)}",
            {**headers, "Content-Type": "application/json"},
            data=json.dumps(
                {
                    "prefix": prefix,
                    "limit": 1000,
                    "offset": offset,
                }
            ).encode(),
            method="POST",
        )
        if payload is None:
            break
        if not isinstance(payload, list) or not payload:
            break
        page_files = 0
        for item in payload:
            if not isinstance(item, dict):
                continue
            name = item.get("name")
            if not isinstance(name, str) or not name:
                continue
            relative = f"{prefix}{name}"
            metadata = item.get("metadata")
            is_folder = metadata is None and item.get("id") is None
            if is_folder:
                objects.extend(
                    _list_storage_objects(
                        supabase_url, headers, bucket, f"{relative}/"
                    )
                )
                continue
            objects.append({**item, "path": relative})
            page_files += 1
        if len(payload) < 1000:
            break
        offset += len(payload)
        if page_files == 0:
            break
    return objects


def _default_backup_dir() -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return Path.home() / "Documents" / f"book_track_supabase_backup_{stamp}"


def main() -> None:
    supabase_url = (_env_file_values(APP_ROOT / ".env").get("URL") or "").rstrip("/")
    if not supabase_url:
        sys.exit("book_track/.env needs URL")

    backup_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else _default_backup_dir()
    backup_dir.mkdir(parents=True, exist_ok=True)
    tables_dir = backup_dir / "tables"
    storage_dir = backup_dir / "storage"
    tables_dir.mkdir(parents=True, exist_ok=True)

    key = _service_role_key()
    headers = _headers(key)

    try:
        users, _, _ = _request_json(f"{supabase_url}/auth/v1/admin/users", headers)
        _write_json(backup_dir / "auth_users.json", users)
    except Exception as error:
        print(f"Auth admin users unavailable: {error}")

    openapi_headers = {**headers, "Accept": "application/openapi+json"}
    discovered: list[str] = []
    try:
        openapi, _, _ = _request_json(f"{supabase_url}/rest/v1/", openapi_headers)
        _write_json(backup_dir / "openapi.json", openapi)
        discovered = _openapi_tables(openapi)
        print(f"OpenAPI tables: {', '.join(discovered) or '(none)'}")
    except Exception as error:
        print(f"OpenAPI unavailable: {error}")

    tables = list(dict.fromkeys([*discovered, *KNOWN_TABLES]))
    table_counts: dict[str, int | str] = {}
    for table in tables:
        try:
            rows = _fetch_table_rows(supabase_url, headers, table)
        except RuntimeError as error:
            message = str(error)
            if "404" in message:
                print(f"  {table}: missing")
                table_counts[table] = "missing"
                continue
            print(f"  {table}: error")
            _write_json(tables_dir / f"{table}.error.json", {"error": message})
            table_counts[table] = "error"
            continue
        _write_json(tables_dir / f"{table}.json", rows)
        table_counts[table] = len(rows)

    storage_manifest: dict[str, object] = {"buckets": [], "objects": {}}
    downloaded = 0
    try:
        buckets, _, _ = _request_json(f"{supabase_url}/storage/v1/bucket", headers)
        _write_json(backup_dir / "storage_buckets.json", buckets)
        storage_manifest["buckets"] = buckets
        if isinstance(buckets, list):
            for bucket in buckets:
                if not isinstance(bucket, dict):
                    continue
                bucket_id = bucket.get("id") or bucket.get("name")
                if not isinstance(bucket_id, str):
                    continue
                objects = _list_storage_objects(supabase_url, headers, bucket_id)
                storage_manifest["objects"][bucket_id] = [
                    {key: value for key, value in obj.items() if key != "metadata"}
                    for obj in objects
                ]
                print(f"  storage {bucket_id}: {len(objects)} objects")
                for obj in objects:
                    path = obj.get("path")
                    if not isinstance(path, str):
                        continue
                    dest = storage_dir / bucket_id / path
                    encoded = "/".join(
                        urllib.parse.quote(part) for part in path.split("/")
                    )
                    _download(
                        f"{supabase_url}/storage/v1/object/{urllib.parse.quote(bucket_id)}/{encoded}",
                        headers,
                        dest,
                    )
                    downloaded += 1
                    if downloaded % 50 == 0:
                        print(f"  downloaded {downloaded} files")
    except Exception as error:
        print(f"Storage unavailable: {error}")
        _write_json(backup_dir / "storage.error.json", {"error": str(error)})

    _write_json(backup_dir / "storage_manifest.json", storage_manifest)

    host = urllib.parse.urlparse(supabase_url).netloc
    manifest = {
        "dumped_at": datetime.now(timezone.utc).isoformat(),
        "supabase_host": host,
        "table_counts": table_counts,
        "storage_files_downloaded": downloaded,
        "backup_dir": str(backup_dir),
    }
    _write_json(backup_dir / "manifest.json", manifest)
    print(f"Wrote backup to {backup_dir}")
    print(json.dumps({k: table_counts[k] for k in table_counts}, indent=2))
    print(f"storage files: {downloaded}")


if __name__ == "__main__":
    main()
