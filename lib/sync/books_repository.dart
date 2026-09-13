import 'dart:convert';
import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class BooksRepository(final PowerSyncDatabase _powerSync) {
  static const _uuid = Uuid();

  Future<Book> getBookById(String bookId) async {
    final bookRow = await _powerSync.get(
      'SELECT * FROM books WHERE id = ?',
      [bookId],
    );
    return _mapToBook(bookRow);
  }

  Future<String> getOrCreateBookId(OpenLibraryBook book) async {
    return await _existingBookId(
          title: book.title,
          author: book.firstAuthor,
        ) ??
        await _insertBook(
          title: book.title,
          author: book.firstAuthor,
          yearPublished: book.yearFirstPublished,
          coverId: book.openLibCoverId,
          coverArt:
              await BookUniverseService.coverBytes(
                book.openLibCoverId,
                OpenLibraryCoverSize.large,
              ) ??
              book.coverArt,
        );
  }

  Future<String> getOrCreateManualBookId({
    required String title,
    String? author,
    int? yearPublished,
  }) async {
    return await _existingBookId(title: title, author: author) ??
        await _insertBook(
          title: title,
          author: author,
          yearPublished: yearPublished,
        );
  }

  Future<void> updateAuthor(Book book, String updatedAuthor) async {
    await _powerSync.execute('UPDATE books SET author = ? WHERE id = ?', [
      updatedAuthor,
      book.id,
    ]);
  }

  Future<String?> _existingBookId({
    required String title,
    String? author,
  }) async {
    final bookRow = author != null && author.isNotEmpty
        ? await _powerSync.getOptional(
            'SELECT id FROM books WHERE title = ? AND author = ? LIMIT 1',
            [title, author],
          )
        : await _powerSync.getOptional(
            'SELECT id FROM books WHERE title = ? LIMIT 1',
            [title],
          );
    return bookRow?['id'] as String?;
  }

  Future<String> _insertBook({
    required String title,
    String? author,
    int? yearPublished,
    int? coverId,
    Uint8List? coverArt,
  }) async {
    final bookId = _uuid.v4();
    await _powerSync.upsert('books', {
      'id': bookId,
      'title': title,
      'author': author,
      'year_published': yearPublished,
      'cover_id': coverId,
      'cover_b64': coverArt == null || coverArt.isEmpty
          ? null
          : base64Encode(coverArt),
    });
    return bookId;
  }

  static Book _mapToBook(Map<String, dynamic> bookRow) {
    final coverB64 = bookRow['cover_b64'] as String?;
    return Book(
      bookRow['id'] as String,
      bookRow['title'] as String,
      bookRow['author'] as String?,
      bookRow['year_published'] as int?,
      bookRow['cover_id'] as int?,
      coverB64 == null || coverB64.isEmpty ? null : base64Decode(coverB64),
    );
  }
}
