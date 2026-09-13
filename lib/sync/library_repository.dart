import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/sync/books_repository.dart';
import 'package:book_track/sync/formats_repository.dart';
import 'package:book_track/sync/progress_events_repository.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class LibraryRepository(final PowerSyncDatabase _powerSync) {
  static const _uuid = Uuid();

  final BooksRepository books = BooksRepository(_powerSync);
  final FormatsRepository formats = FormatsRepository(_powerSync);
  final ProgressEventsRepository progress = ProgressEventsRepository(
    _powerSync,
  );

  Future<List<LibraryBook>> myBooks() async {
    final libraryRows = await _powerSync.getAll('SELECT * FROM library_books');
    final libraryBookIds = [
      for (final libraryRow in libraryRows) libraryRow['id'] as String,
    ];
    final progressByLibraryBookId = await progress.historyForLibraryBooks(
      libraryBookIds,
    );
    final formatsByLibraryBookId = await formats.formatsForLibraryBooks(
      libraryBookIds,
    );
    final libraryBooks = <LibraryBook>[];
    for (final libraryRow in libraryRows) {
      final libraryBookId = libraryRow['id'] as String;
      libraryBooks.add(
        LibraryBook(
          libraryBookId,
          await books.getBookById(libraryRow['book_id'] as String),
          progressByLibraryBookId[libraryBookId] ?? [],
          formatsByLibraryBookId[libraryBookId] ?? [],
          (libraryRow['archived'] as int? ?? 0) == 1,
          (libraryRow['abandoned_at'] as String?) == null
              ? null
              : DateTime.parse(libraryRow['abandoned_at'] as String),
        ),
      );
    }
    return libraryBooks;
  }

  Future<void> addBook(
    OpenLibraryBook book,
    BookFormat bookFormat,
    int length,
  ) async {
    final bookId = await books.getOrCreateBookId(book);
    await _addBookToLibraryById(bookId, bookFormat, length);
  }

  Future<void> addManualBook({
    required String title,
    String? author,
    int? yearPublished,
    required BookFormat format,
    required int length,
  }) async {
    final bookId = await books.getOrCreateManualBookId(
      title: title,
      author: author,
      yearPublished: yearPublished,
    );
    await _addBookToLibraryById(bookId, format, length);
  }

  Future<void> remove(LibraryBook book) async {
    await _powerSync.execute(
      'DELETE FROM progress_events WHERE library_book_id = ?',
      [book.id],
    );
    await _powerSync.execute(
      'DELETE FROM library_book_formats WHERE library_book_id = ?',
      [book.id],
    );
    await _powerSync.execute('DELETE FROM library_books WHERE id = ?', [
      book.id,
    ]);
  }

  Future<void> archive(LibraryBook book) async {
    await _powerSync.execute(
      'UPDATE library_books SET archived = ? WHERE id = ?',
      [book.archived ? 0 : 1, book.id],
    );
  }

  Future<void> setAbandoned(
    LibraryBook book, {
    required bool abandoned,
  }) async {
    await _powerSync.execute(
      'UPDATE library_books SET abandoned_at = ? WHERE id = ?',
      [abandoned ? DateTime.now().toIso8601String() : null, book.id],
    );
  }

  Future<void> _addBookToLibraryById(
    String bookId,
    BookFormat bookFormat,
    int length,
  ) async {
    final libraryBookId = await _getOrCreateLibraryBookId(bookId);
    final format = await formats.addFormat(
      libraryBookId: libraryBookId,
      format: bookFormat,
      length: length,
    );
    await progress.addProgressEvent(
      libraryBookId: libraryBookId,
      formatId: format.id,
      newValue: 0,
      format: ProgressEventFormat.percent,
    );
  }

  Future<String> _getOrCreateLibraryBookId(String bookId) async {
    final existing = await _powerSync.getOptional(
      'SELECT id FROM library_books WHERE book_id = ? LIMIT 1',
      [bookId],
    );
    if (existing != null) return existing['id'] as String;
    final libraryBookId = _uuid.v4();
    await _powerSync.upsert('library_books', {
      'id': libraryBookId,
      'book_id': bookId,
      'archived': 0,
      'abandoned_at': null,
    });
    return libraryBookId;
  }
}
