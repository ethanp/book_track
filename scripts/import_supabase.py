#!/usr/bin/env python3
"""Copy Book Track rows from the old Supabase project into home-server Postgres."""

from __future__ import annotations

import base64
import csv
import io
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
INFRA_ROOT = APP_ROOT.parents[1] / "infra"
PAGE_SIZE = 1000
SUPABASE_REF = "oshnlbnwpbtjbjpqnuvl"


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


def _remote_host() -> str:
    host = os.environ.get("HOME_SERVER")
    if not host:
        host = _env_file_values(INFRA_ROOT / "tools" / ".env").get("HOME_SERVER")
    if not host:
        sys.exit("HOME_SERVER is not set")
    return f"ethan@{host}"


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
    keys = json.loads(completed.stdout)
    if not isinstance(keys, list):
        sys.exit("unexpected api-keys payload")
    for item in keys:
        if item.get("name") == "service_role" and item.get("api_key"):
            return item["api_key"]
    sys.exit("service_role key not in api-keys payload")


def _fetch_table(supabase_url: str, key: str, table: str) -> list[dict]:
    rows: list[dict] = []
    offset = 0
    while True:
        request = urllib.request.Request(
            f"{supabase_url}/rest/v1/{table}?select=*&order=id.asc",
            headers={
                "apikey": key,
                "Authorization": f"Bearer {key}",
                "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
                "Prefer": "count=exact",
            },
        )
        with urllib.request.urlopen(request) as response:
            page = json.load(response)
        if not isinstance(page, list) or not page:
            break
        rows.extend(page)
        if len(page) < PAGE_SIZE:
            break
        offset += PAGE_SIZE
    return rows


def _cover_bytes(supabase_url: str, key: str, cover_key: str | None) -> str | None:
    if not cover_key:
        return None
    request = urllib.request.Request(
        f"{supabase_url}/storage/v1/object/cover_art/{cover_key}",
        headers={"apikey": key, "Authorization": f"Bearer {key}"},
    )
    try:
        with urllib.request.urlopen(request) as response:
            return base64.b64encode(response.read()).decode("ascii")
    except urllib.error.HTTPError:
        return None


def _as_text_id(value: object) -> str | None:
    if value is None:
        return None
    return str(value)


def _as_int_flag(value: object) -> int:
    if value in (True, 1, "1", "t", "true", "True"):
        return 1
    return 0


def _csv(columns: list[str], mapped_rows: list[dict]) -> str:
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=columns, extrasaction="ignore")
    writer.writeheader()
    for mapped in mapped_rows:
        writer.writerow({column: mapped.get(column) for column in columns})
    return buffer.getvalue()


def _psql(sql: str, stdin: str | None = None) -> None:
    remote = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-i",
        str(Path.home() / ".ssh" / "id_ed25519"),
        _remote_host(),
        "cd /home/ethan/infra && docker compose --env-file .env.prod exec -T "
        "postgres psql -U book_track -d book_track "
        f"-c {json.dumps(sql)}",
    ]
    completed = subprocess.run(remote, input=stdin, text=True, check=False)
    if completed.returncode != 0:
        sys.exit(completed.returncode)


def _copy(table: str, columns: list[str], csv_text: str) -> int:
    copy_sql = (
        f"COPY {table} ({', '.join(columns)}) FROM STDIN WITH "
        "(FORMAT csv, HEADER true, NULL '')"
    )
    _psql(copy_sql, stdin=csv_text)
    return max(csv_text.count("\n") - 1, 0)


def main() -> None:
    supabase_url = _env_file_values(APP_ROOT / ".env").get("URL", "").rstrip("/")
    if not supabase_url:
        sys.exit("URL missing from book_track/.env")
    key = _service_role_key()
    books = _fetch_table(supabase_url, key, "books")
    library = _fetch_table(supabase_url, key, "library")
    formats = _fetch_table(supabase_url, key, "library_book_formats")
    events = _fetch_table(supabase_url, key, "progress_events")
    print(
        f"fetched books={len(books)} library={len(library)} "
        f"formats={len(formats)} events={len(events)}"
    )

    mapped_books = []
    for book in books:
        mapped_books.append(
            {
                "id": _as_text_id(book.get("id")),
                "title": book.get("title") or "",
                "author": book.get("author"),
                "year_published": book.get("first_year_published"),
                "cover_id": book.get("openlib_cover_id"),
                "cover_b64": _cover_bytes(
                    supabase_url, key, book.get("small_cover_key")
                ),
            }
        )

    mapped_library = [
        {
            "id": _as_text_id(row.get("id")),
            "book_id": _as_text_id(row.get("book_id")),
            "archived": _as_int_flag(row.get("archived")),
            "abandoned_at": row.get("abandoned_at"),
        }
        for row in library
    ]
    mapped_formats = [
        {
            "id": _as_text_id(row.get("id")),
            "library_book_id": _as_text_id(row.get("library_book_id")),
            "format_name": row.get("format"),
            "length": row.get("length"),
        }
        for row in formats
    ]
    mapped_events = []
    for row in events:
        format_id = _as_text_id(row.get("format_id"))
        if format_id in (None, "0"):
            continue
        mapped_events.append(
            {
                "id": _as_text_id(row.get("id")),
                "library_book_id": _as_text_id(row.get("library_book_id")),
                "format_id": format_id,
                "progress": row.get("progress"),
                "format_kind": row.get("format"),
                "started_at": row.get("started_at") or row.get("start"),
                "ended_at": row.get("end") or row.get("ended_at"),
            }
        )

    _psql(
        "TRUNCATE progress_events, library_book_formats, library_books, books"
    )
    book_columns = [
        "id",
        "title",
        "author",
        "year_published",
        "cover_id",
        "cover_b64",
    ]
    library_columns = ["id", "book_id", "archived", "abandoned_at"]
    format_columns = ["id", "library_book_id", "format_name", "length"]
    event_columns = [
        "id",
        "library_book_id",
        "format_id",
        "progress",
        "format_kind",
        "started_at",
        "ended_at",
    ]
    print(f"copied {_copy('books', book_columns, _csv(book_columns, mapped_books))} books")
    print(
        f"copied {_copy('library_books', library_columns, _csv(library_columns, mapped_library))} library_books"
    )
    print(
        f"copied {_copy('library_book_formats', format_columns, _csv(format_columns, mapped_formats))} formats"
    )
    print(
        f"copied {_copy('progress_events', event_columns, _csv(event_columns, mapped_events))} progress_events"
    )


if __name__ == "__main__":
    main()
