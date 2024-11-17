import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _base = Supabase.instance.client;

class SupabaseAuthService {
  static final GoTrueClient _authClient = _base.auth;

  static bool get isLoggedOut => _authClient.currentSession == null;

  static String? get loggedInUserId => _authClient.currentSession?.user.id;

  static bool get isLoggedIn => !isLoggedOut;

  static Future<void> signOut() => _authClient.signOut();

  static Future<void> signIn(String trim, String passwordInput) {
    return _authClient.signInWithPassword(
      email: trim,
      password: passwordInput,
    );
  }

  static Future<void> signUp(String email, String password) =>
      _authClient.signUp(email: email, password: password);

  static StreamSubscription<AuthState> onAuthStateChange(
      {required void Function(AuthState) onEvent,
      required void Function(Object) onError}) {
    return _authClient.onAuthStateChange.listen(onEvent, onError: onError);
  }
}

class SupabaseBookService {
  static final _bucketClient = _base.storage;
  static final _coverArtClient = _bucketClient.from('cover_art');
  static final _booksClient = _base.from('books');

  static Future<PostgrestMap> storeBook(Book book) async {
    final PostgrestList preExistResponse = await _fetchPreExisting(book);
    if (preExistResponse.isNotEmpty) return preExistResponse.first;
    final String? coverStorageLoc = await book.coverArtS
        .ifExists<Future<String>>(
            (art) => _storeCoverArtS(book.openLibCoverId!, art));

    return await _booksClient
        .insert({
          _SupaBook.titleCol: book.title,
          _SupaBook.authorCol: book.author,
          _SupaBook.yearPublishedCol: book.yearFirstPublished,
          _SupaBook.lengthCol: book.bookLength,
          _SupaBook.coverIdCol: book.openLibCoverId,
          _SupaBook.coverKeyCol: coverStorageLoc,
        })
        .select()
        .single();
  }

  static Future<PostgrestList> _fetchPreExisting(Book book) async {
    PostgrestFilterBuilder<PostgrestList> preExistQuery =
        _booksClient.select('id');
    preExistQuery = preExistQuery.eq('title', book.title);
    if (book.author != null) {
      preExistQuery = preExistQuery.eq('author', book.author!);
    }
    if (book.openLibCoverId != null) {
      preExistQuery =
          preExistQuery.eq('openlib_cover_id', book.openLibCoverId!);
    }
    try {
      final PostgrestList preExistResponse = await preExistQuery.limit(1);
      return preExistResponse;
    } on StorageException catch (e) {
      print('pre-existing book query error $e');
      return [];
    }
  }

  static Future<String> _storeCoverArtS(int coverI, Uint8List data) =>
      _coverArtClient.uploadBinary('s/$coverI.jpg', data);

  static Future<Uint8List?> getCoverArt(String key) async {
    try {
      return await _coverArtClient.download(key);
    } on StorageException catch (e) {
      print('issue with the bucket: $e');
      return null;
    } catch (e) {
      print('strange error: $e');
      return null;
    }
  }
}

class SupabaseLibraryService {
  static Future<void> addBook(Book book, BookType bookType) async {
    final PostgrestMap storedBook = await SupabaseBookService.storeBook(book);
    final PostgrestList preExistQuery = await _base
        .from('library')
        .select('id')
        .eq('book_id', storedBook['id'])
        .eq('user_id', SupabaseAuthService.loggedInUserId!)
        .eq('format', bookType.name)
        .limit(1);
    if (preExistQuery.isNotEmpty) {
      print('library item already exists, not adding.');
      return;
    }
    return await _base.from('library').insert({
      'book_id': storedBook['id'],
      'user_id': SupabaseAuthService.loggedInUserId,
      'format': bookType.name,
    });
  }

  static Future<List<BookProgress>> myBooks() async {
    final List<_SupaLibrary> library = await _SupaLibrary.forLoggedInUser();
    return Future.wait(library.map((myBook) async {
      final int bookId = myBook.bookId;
      final _SupaBook supaBook = await _SupaLibrary.bookById(bookId);
      final Uint8List? cover = await supaBook.coverKey
          .ifExists<Future<Uint8List?>>(SupabaseBookService.getCoverArt);
      var book = Book(
        supaBook.title,
        supaBook.author,
        supaBook.yearPublished,
        myBook.format,
        supaBook.length,
        supaBook.coverId,
        cover,
      );
      final bookProgress =
          BookProgress(book, DateTime.now(), ProgressHistory([]));
      return bookProgress;
    }));
  }
}

class _SupaLibrary {
  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  int get bookId => rawData[bookIdCol];
  static final String bookIdCol = 'book_id';

  int get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  BookType? get format => (rawData[formatCol] as String?).ifExists(
      (str) => BookType.values.firstWhere((BookType v) => v.name == str));
  static final String formatCol = 'format';

  _SupaLibrary(this.rawData);

  final PostgrestMap rawData;

  static Future<List<_SupaLibrary>> forLoggedInUser() async {
    final PostgrestList rawData = await _base
        .from('library')
        .select()
        .eq('user_id', SupabaseAuthService.loggedInUserId!);
    return rawData.mapL(_SupaLibrary.new);
  }

  static Future<_SupaBook> bookById(int bookId) async =>
      _SupaBook(await _base.from('books').select().eq('id', bookId).single());
}

class _SupaBook {
  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  String get title => rawData[titleCol];
  static final String titleCol = 'title';

  String? get author => rawData[authorCol];
  static final String authorCol = 'author';

  int? get yearPublished => rawData[yearPublishedCol];
  static final String yearPublishedCol = 'first_year_published';

  int? get length => rawData[lengthCol];
  static final String lengthCol = 'length';

  int? get coverId => rawData[coverIdCol];
  static final String coverIdCol = 'openlib_cover_id';

  String? get coverKey => rawData[coverKeyCol];
  static final String coverKeyCol = 'small_cover_key';

  _SupaBook(this.rawData);

  final PostgrestMap rawData;
}
