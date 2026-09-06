import 'dart:typed_data';

import 'package:ethan_utils/ethan_utils.dart';

import 'package:book_track/data_model.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'book_universe_service.dart';
import 'supabase_service.dart';

const _log = ELogger('SupabaseBookService');

class SupabaseBookService() {
  static final _bucketClient = supabase.storage;
  static final _coverArtClient = _bucketClient.from('cover_art');
  static final _booksClient = supabase.from('books');

  static Future<Book> getBookById(int bookId) async {
    final rawData = await supabase
        .from('books')
        .select()
        .eq(_SupaBook.idCol, bookId)
        .single()
        .withRetry(_log);
    final supaBook = _SupaBook(rawData);
    return Book(
      supaBook.supaId,
      supaBook.title,
      supaBook.author,
      supaBook.yearPublished,
      supaBook.coverId,
      await _coverArtFor(supaBook),
    );
  }

  static Future<int> getOrCreateBookId(OpenLibraryBook book) async =>
      await _existingBookId(book) ?? await _storeBookAndCover(book);

  /// Create a book from manual user input (no cover art).
  static Future<int> getOrCreateManualBookId({
    required String title,
    String? author,
    int? yearPublished,
  }) async =>
      await _existingManualBookId(title: title, author: author) ??
      await _storeManualBook(
        title: title,
        author: author,
        yearPublished: yearPublished,
      );

  static Future<int?> _existingManualBookId({
    required String title,
    String? author,
  }) async {
    try {
      var query = _booksClient
          .select(_SupaBook.idCol)
          .eq(_SupaBook.titleCol, title);
      if (author != null && author.isNotEmpty) {
        query = query.eq(_SupaBook.authorCol, author);
      }
      final PostgrestMap? existingBookMatch = await query
          .limit(1)
          .maybeSingle()
          .withRetry(_log);
      return existingBookMatch.map(_SupaBook.new).map((book) => book.supaId);
    } on StorageException catch (error) {
      _log.log('pre-existing manual book query error $error');
      return null;
    }
  }

  static Future<int> _storeManualBook({
    required String title,
    String? author,
    int? yearPublished,
  }) async {
    final PostgrestMap result = await _booksClient
        .insert({
          _SupaBook.titleCol: title,
          _SupaBook.authorCol: author,
          _SupaBook.yearPublishedCol: yearPublished,
        })
        .select()
        .single()
        .withRetry(_log);
    return _SupaBook(result).supaId;
  }

  static Future<int> _storeBookAndCover(OpenLibraryBook book) async {
    final String? coverKey = await _storeLargeCoverArt(book);
    final _SupaBook result = await _storeBook(book, coverKey);
    return result.supaId;
  }

  static Future<_SupaBook> _storeBook(
    OpenLibraryBook book,
    String? coverKey,
  ) async {
    final PostgrestMap result = await _booksClient
        .insert({
          _SupaBook.titleCol: book.title,
          _SupaBook.authorCol: book.firstAuthor,
          _SupaBook.yearPublishedCol: book.yearFirstPublished,
          _SupaBook.coverIdCol: book.openLibCoverId,
          _SupaBook.coverKeyCol: coverKey,
        })
        .select()
        .single()
        .withRetry(_log);
    return _SupaBook(result);
  }

  static Future<int?> _existingBookId(OpenLibraryBook book) async {
    try {
      final PostgrestMap? existingBookMatch = await _booksClient
          .select(_SupaBook.idCol)
          .eq(_SupaBook.titleCol, book.title)
          .eq(_SupaBook.authorCol, book.firstAuthor)
          .limit(1)
          .maybeSingle()
          .withRetry(_log);
      return existingBookMatch.map(_SupaBook.new).map((book) => book.supaId);
    } on StorageException catch (error) {
      _log.log('pre-existing book query error $error');
      return null;
    }
  }

  static Future<Uint8List?> _coverArtFor(_SupaBook supaBook) async {
    if (supaBook.coverId != null && !supaBook.hasLargeCoverKey) {
      return await _upgradeToLargeCover(supaBook);
    }
    return await supaBook.coverKey.map<Future<Uint8List?>>(_getCoverArt);
  }

  static Future<Uint8List?> _upgradeToLargeCover(_SupaBook supaBook) async {
    final int? coverId = supaBook.coverId;
    if (coverId == null) return null;
    final Uint8List? largeBytes = await BookUniverseService.coverBytes(
      coverId,
      OpenLibraryCoverSize.large,
    );
    if (largeBytes == null) {
      return await supaBook.coverKey.map<Future<Uint8List?>>(_getCoverArt);
    }
    final String coverKey = _largeCoverPath(coverId);
    if (!await _upsertCoverArt(coverKey, largeBytes)) {
      return largeBytes;
    }
    await _booksClient
        .update({_SupaBook.coverKeyCol: coverKey})
        .eq(_SupaBook.idCol, supaBook.supaId)
        .withRetry(_log);
    return largeBytes;
  }

  static Future<String?> _storeLargeCoverArt(OpenLibraryBook book) async {
    final int? coverId = book.openLibCoverId;
    if (coverId == null) {
      _log.log('No cover for ${book.title}');
      return null;
    }
    final Uint8List? largeBytes = await BookUniverseService.coverBytes(
      coverId,
      OpenLibraryCoverSize.large,
    );
    if (largeBytes == null) {
      _log.log('No large cover for ${book.title}');
      return null;
    }
    final String coverKey = _largeCoverPath(coverId);
    if (!await _upsertCoverArt(coverKey, largeBytes)) return null;
    return coverKey;
  }

  static Future<bool> _upsertCoverArt(String coverKey, Uint8List bytes) async {
    try {
      await _coverArtClient.uploadBinary(
        coverKey,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      return true;
    } on StorageException catch (error) {
      if (error.error == 'Duplicate') {
        _log.warn('art $coverKey is duplicate (which is probably fine)');
        return true;
      }
      _log.warn('Unknown error: $error');
      return false;
    } catch (error) {
      _log.error('Failed to store cover art', error);
      return false;
    }
  }

  static String _largeCoverPath(int coverId) => 'l/$coverId.jpg';

  static Future<Uint8List?> _getCoverArt(String key) async {
    try {
      return await _coverArtClient.download(key);
    } on StorageException catch (error) {
      _log.warn('issue with the bucket: $error, $key');
      return null;
    } on ClientException catch (error) {
      _log.warn('http issue $error $key');
      return null;
    } catch (error) {
      _log.error('strange error: $error', error);
      return null;
    }
  }

  static Future<void> updateAuthor(Book book, String updatedAuthor) =>
      _booksClient
          .update({_SupaBook.authorCol: updatedAuthor})
          .eq(_SupaBook.idCol, book.supaId!)
          .withRetry(_log);
}

class const _SupaBook(final PostgrestMap rawData) {
  int get supaId => rawData[idCol];
  static final String idCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  String get title => rawData[titleCol];
  static final String titleCol = 'title';

  String? get author => rawData[authorCol];
  static final String authorCol = 'author';

  int? get yearPublished => rawData[yearPublishedCol];
  static final String yearPublishedCol = 'first_year_published';

  int? get coverId => rawData[coverIdCol];
  static final String coverIdCol = 'openlib_cover_id';

  String? get coverKey => rawData[coverKeyCol];
  static final String coverKeyCol = 'small_cover_key';

  bool get hasLargeCoverKey {
    final String? key = coverKey;
    return key != null && key.startsWith('l/');
  }
}
