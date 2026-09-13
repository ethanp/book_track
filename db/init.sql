-- book_track schema for PowerSync (TEXT ids = client UUIDs)

CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT,
    year_published INTEGER,
    cover_id INTEGER,
    cover_b64 TEXT
);

CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);

CREATE TABLE IF NOT EXISTS library_books (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL REFERENCES books(id),
    archived INTEGER NOT NULL DEFAULT 0,
    abandoned_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_library_books_book_id ON library_books(book_id);

CREATE TABLE IF NOT EXISTS library_book_formats (
    id TEXT PRIMARY KEY,
    library_book_id TEXT NOT NULL REFERENCES library_books(id) ON DELETE CASCADE,
    format_name TEXT NOT NULL,
    length INTEGER
);

CREATE INDEX IF NOT EXISTS idx_library_book_formats_library_book_id
    ON library_book_formats(library_book_id);

CREATE TABLE IF NOT EXISTS progress_events (
    id TEXT PRIMARY KEY,
    library_book_id TEXT NOT NULL REFERENCES library_books(id) ON DELETE CASCADE,
    format_id TEXT NOT NULL REFERENCES library_book_formats(id),
    progress INTEGER NOT NULL,
    format_kind TEXT NOT NULL,
    started_at TEXT,
    ended_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_progress_events_library_book_id
    ON progress_events(library_book_id);
CREATE INDEX IF NOT EXISTS idx_progress_events_ended_at
    ON progress_events(ended_at);
