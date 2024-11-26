import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'book_universe_service.dart';
import 'supabase_service.dart';

class _SupaBook {
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

  const _SupaBook(this.rawData);

  final PostgrestMap rawData;
}

class SupabaseBookService {
  static final _bucketClient = supabase.storage;
  static final _coverArtClient = _bucketClient.from('cover_art');
  static final _booksClient = supabase.from('books');

  static final SimpleLogger log = SimpleLogger(prefix: 'SupabaseBookService');

  static Future<int> getOrCreateBookId(OpenLibraryBook book) async =>
      await existingBookId(book) ?? await storeBook(book);

  static Future<int> storeBook(OpenLibraryBook book) async {
    final String? coverKey = await storeCoverArtS(book);
    final _SupaBook result = await _storeBook(book, coverKey);
    return result.supaId;
  }

  static Future<_SupaBook> _storeBook(
      OpenLibraryBook book, String? coverKey) async {
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
        .captureStackTraceOnError();
    return _SupaBook(result);
  }

  static Future<int?> existingBookId(OpenLibraryBook book) async {
    try {
      final PostgrestMap? existingBookMatch = await _booksClient
          .select(_SupaBook.idCol)
          .eq(_SupaBook.titleCol, book.title)
          .eq(_SupaBook.authorCol, book.firstAuthor)
          .limit(1)
          .maybeSingle()
          .captureStackTraceOnError();
      return existingBookMatch.map(_SupaBook.new).map((book) => book.supaId);
    } on StorageException catch (e) {
      log('pre-existing book query error $e');
      return null;
    }
  }

  static Future<String?> storeCoverArtS(OpenLibraryBook book) async {
    final String? coverKey = book.openLibCoverId.map(coverPath);
    if (book.openLibCoverId == null || book.coverArtS == null) {
      log('INFO: No cover for ${book.title}');
      return null;
    }
    try {
      await _coverArtClient.uploadBinary(coverKey!, book.coverArtS!);
      return coverKey;
    } on StorageException catch (e) {
      if (e.error == 'Duplicate') {
        log('WARN: art $coverKey is duplicate (which is probably fine)');
      } else {
        log('WARN: Unknown error: $e');
      }
      return null;
    } catch (e) {
      log('ERROR: $e');
      return null;
    }
  }

  static String coverPath(int coverI) => 's/$coverI.jpg';

  static Future<Uint8List?> getCoverArt(String key) async {
    try {
      return await _coverArtClient.download(key);
    } on StorageException catch (e) {
      print('issue with the bucket: $e, $key');
      return null;
    } on ClientException catch (e) {
      print('http issue $e $key');
      return null;
    } catch (e) {
      print('strange error: $e');
      return null;
    }
  }

  static Future<Book> bookById(int bookId) async {
    final PostgrestMap rawData = await supabase
        .from('books')
        .select()
        .eq(_SupaBook.idCol, bookId)
        .single()
        .captureStackTraceOnError();
    final supaBook = _SupaBook(rawData);
    final coverArt =
        // Not sure why, but these angle brackets are necessary.¬
        await supaBook.coverKey.map<Future<Uint8List?>>(getCoverArt);
    return Book(
      supaBook.supaId,
      supaBook.title,
      supaBook.author,
      supaBook.yearPublished,
      supaBook.coverId,
      coverArt,
    );
  }
}
