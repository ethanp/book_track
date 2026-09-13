import 'package:powersync/powersync.dart';

/// Mirrors [db/init.sql] Postgres tables. PowerSync adds `id` automatically.
const Schema bookTrackSchema = Schema([
  Table('books', [
    Column.text('title'),
    Column.text('author'),
    Column.integer('year_published'),
    Column.integer('cover_id'),
    Column.text('cover_b64'),
  ]),
  Table('library_books', [
    Column.text('book_id'),
    Column.integer('archived'),
    Column.text('abandoned_at'),
  ]),
  Table('library_book_formats', [
    Column.text('library_book_id'),
    Column.text('format_name'),
    Column.integer('length'),
  ]),
  Table('progress_events', [
    Column.text('library_book_id'),
    Column.text('format_id'),
    Column.integer('progress'),
    Column.text('format_kind'),
    Column.text('started_at'),
    Column.text('ended_at'),
  ]),
]);
