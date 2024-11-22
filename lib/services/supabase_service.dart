import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
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

  static Future<int> storeBook(OpenLibraryBook book) async {
    final existingBookId = await _fetchPreExisting(book);
    if (existingBookId != null) return existingBookId;

    final String? coverKey = book.openLibCoverId.ifExists(coverPath);
    if (book.openLibCoverId != null && book.coverArtS != null) {
      _storeCoverArtS(coverKey!, book.coverArtS!);
    }

    final PostgrestMap result = await _booksClient
        .insert({
          _SupaBook.titleCol: book.title,
          _SupaBook.authorCol: book.firstAuthor,
          _SupaBook.yearPublishedCol: book.yearFirstPublished,
          _SupaBook.coverIdCol: book.openLibCoverId,
          _SupaBook.coverKeyCol: coverKey,
        })
        .select()
        .single();
    return _SupaBook(result).supaId;
  }

  static Future<int?> _fetchPreExisting(OpenLibraryBook book) async {
    try {
      final PostgrestMap? existingBookMatch = await _booksClient
          .select(_SupaBook.idCol)
          .eq(_SupaBook.titleCol, book.title)
          .eq(_SupaBook.authorCol, book.firstAuthor)
          .limit(1)
          .maybeSingle();
      return existingBookMatch.ifExists((data) => _SupaBook(data).supaId);
    } on StorageException catch (e) {
      print('pre-existing book query error $e');
      return null;
    }
  }

  static Future<void> _storeCoverArtS(String key, Uint8List data) async {
    try {
      await _coverArtClient.uploadBinary(key, data);
    } on StorageException catch (e) {
      if (e.error == 'Duplicate') {
        print('WARN: art $key is duplicate (which is probably fine)');
      }
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
}

class SupabaseLibraryService {
  static final _libraryClient = _base.from('library');

  static Future<void> addBook(OpenLibraryBook book, BookFormat bookType) async {
    final int bookId = await SupabaseBookService.storeBook(book);
    final int? libraryBookId =
        await findExistingLibraryBookId(bookId, bookType) ??
            await _libraryClient.insert({
              _SupaLibrary.bookIdCol: bookId,
              _SupaLibrary.userIdCol: SupabaseAuthService.loggedInUserId,
              _SupaLibrary.formatCol: bookType.name,
            });
    // TODO(feature) Store a reading Status event (started book).
    //  Requires data model, Postgres table, and all the associated
    //  de/serialization.
  }

  static Future<int?> findExistingLibraryBookId(
      int bookId, BookFormat bookType) async {
    final PostgrestMap? preExistQuery = await _libraryClient
        .select(_SupaLibrary.supaIdCol)
        .eq(_SupaLibrary.bookIdCol, bookId)
        .eq(_SupaLibrary.userIdCol, SupabaseAuthService.loggedInUserId!)
        .eq(_SupaLibrary.formatCol, bookType.name)
        .limit(1)
        .maybeSingle();
    return preExistQuery.ifExists((res) => _SupaLibrary(res).supaId);
  }

  static Future<List<LibraryBook>> myBooks() async {
    final List<_SupaLibrary> library = await _SupaLibrary.forLoggedInUser();
    return Future.wait(library.map((_SupaLibrary myBook) async {
      final int bookId = myBook.bookId;
      final _SupaBook supaBook = await _SupaLibrary.bookById(bookId);
      final Uint8List? cover = await supaBook.coverKey
          .ifExists<Future<Uint8List?>>(SupabaseBookService.getCoverArt);
      final List<ProgressEvent> progressHistory =
          await SupabaseProgressService.history(bookId);
      return LibraryBook(
        myBook.supaId,
        Book(
          supaBook.supaId,
          supaBook.title,
          supaBook.author,
          supaBook.yearPublished,
          supaBook.coverId,
          cover,
        ),
        supaBook.createdAt,
        progressHistory,
        [],
// TODO fill in.
        myBook.format,
        myBook.length,
      );
    }));
  }

  static Future<void> updateFormat(
    LibraryBook libraryBook,
    BookFormat? updatedFormat,
  ) async {
    try {
      print('updating format');
      await _base
          .from('library')
          .update({_SupaLibrary.formatCol: updatedFormat?.name}).eq(
              _SupaLibrary.supaIdCol, libraryBook.supaId);
    } catch (e) {
      print('update format exception: $e');
      rethrow;
    }
  }
}

class _SupaLibrary {
  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  int get bookId => rawData[bookIdCol];
  static final String bookIdCol = 'book_id';

  int get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  BookFormat? get format => (rawData[formatCol] as String?).ifExists(
      (str) => BookFormat.values.firstWhere((BookFormat v) => v.name == str));
  static final String formatCol = 'format';

  int? get length => rawData[lengthCol];
  static final String lengthCol = 'length';

  const _SupaLibrary(this.rawData);

  final PostgrestMap rawData;

  static Future<List<_SupaLibrary>> forLoggedInUser() async {
    final PostgrestList rawData = await _base
        .from('library')
        .select()
        .eq('user_id', SupabaseAuthService.loggedInUserId!);
    return rawData.mapL(_SupaLibrary.new);
  }

  static Future<_SupaBook> bookById(int bookId) async => _SupaBook(
      await _base.from('books').select().eq(_SupaBook.idCol, bookId).single());
}

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

class _SupaProgress {
  const _SupaProgress(this.rawData);

  final PostgrestMap rawData;

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  int get libraryBookId => rawData[libraryBookIdCol];
  static final String libraryBookIdCol = 'library_book_id';

  int get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  ProgressEventFormat get format =>
      ProgressEventFormat.map[rawData[formatCol]]!;
  static final String formatCol = 'format';

  int get progress => rawData[progressCol];
  static final String progressCol = 'progress';

  DateTime? get start => parseDateCol(rawData[startCol]);
  static final String startCol = 'start';

  DateTime? get end => parseDateCol(rawData[endCol]);
  static final String endCol = 'end';

  DateTime get endSafe => end ?? createdAt;
}

class SupabaseProgressService {
  static final SupabaseQueryBuilder _progressClient =
      _base.from('progress_events');

  static Future<void> updateProgress({
    required LibraryBook book,
    required int userInput,
    required ProgressEventFormat format,
    DateTime? start,
    DateTime? end,
  }) async {
    final progressUpdate = {
      _SupaProgress.libraryBookIdCol: book.book.supaId,
      _SupaProgress.userIdCol: SupabaseAuthService.loggedInUserId,
      _SupaProgress.formatCol: format.name,
      _SupaProgress.progressCol: userInput,
      _SupaProgress.startCol: start?.toIso8601String(),
      _SupaProgress.endCol: end?.toIso8601String(),
    };
    print('inserting progress update $progressUpdate');
    return await _progressClient.insert(progressUpdate);
  }

  static Future<List<ProgressEvent>> history(int bookId) async {
    final queryResults = await _progressClient
        .select()
        .eq(_SupaProgress.libraryBookIdCol, bookId)
        .eq(_SupaProgress.userIdCol, SupabaseAuthService.loggedInUserId!);
    return queryResults.map(_SupaProgress.new).mapL(
      (supaProgress) {
        return ProgressEvent(
          end: supaProgress.endSafe,
          progress: supaProgress.progress,
          format: supaProgress.format,
          start: supaProgress.start,
        );
      },
    );
  }
}

DateTime? parseDateCol(dynamic value) =>
    (value as String?).ifExists(DateTime.parse);
