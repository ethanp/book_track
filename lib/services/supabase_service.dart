import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
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
    try {
      return _authClient.signInWithPassword(
        email: trim,
        password: passwordInput,
      );
    } on AuthException catch (e) {
      // Doing this captures the stack trace better.
      throw Exception(e);
    }
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
}

class SupabaseLibraryService {
  static final _libraryClient = _base.from('library');

  static Future<void> addBook(OpenLibraryBook book, BookFormat bookType) async {
    final int bookId = await SupabaseBookService.getOrCreateBookId(book);
    final int libraryBookId = await getOrCreateLibraryBookId(bookId, bookType);
    await SupabaseStatusService.add(libraryBookId, ReadingStatus.reading);
  }

  static Future<dynamic> getOrCreateLibraryBookId(
          int bookId, BookFormat bookType) async =>
      await existingLibraryBookId(bookId, bookType) ??
      await newLibraryBookId(bookId, bookType);

  static Future<int?> existingLibraryBookId(
      int bookId, BookFormat bookType) async {
    final PostgrestMap? preExistQuery = await _libraryClient
        .select(_SupaLibrary.supaIdCol)
        .eq(_SupaLibrary.bookIdCol, bookId)
        .eq(_SupaLibrary.userIdCol, SupabaseAuthService.loggedInUserId!)
        .eq(_SupaLibrary.formatCol, bookType.name)
        .limit(1)
        .maybeSingle()
        .captureStackTraceOnError();
    return preExistQuery.map(_SupaLibrary.new).map((res) => res.supaId);
  }

  static Future<dynamic> newLibraryBookId(int bookId, BookFormat bookType) =>
      _libraryClient.insert({
        _SupaLibrary.bookIdCol: bookId,
        _SupaLibrary.userIdCol: SupabaseAuthService.loggedInUserId,
        _SupaLibrary.formatCol: bookType.name,
      }).captureStackTraceOnError();

  static Future<List<LibraryBook>> myBooks() async {
    final List<_SupaLibrary> library = await _SupaLibrary.forLoggedInUser();
    return Future.wait(library.map((_SupaLibrary myBook) async {
      final int bookId = myBook.bookId;
      final _SupaBook supaBook = await _SupaLibrary.bookById(bookId);
      final Uint8List? cover = await supaBook.coverKey
          .map<Future<Uint8List?>>(SupabaseBookService.getCoverArt);
      final progressHistory = await SupabaseProgressService.history(bookId);
      final statusHistory = await SupabaseStatusService.history(bookId);
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
        statusHistory,
        myBook.format,
        myBook.length,
      );
    }));
  }

  static Future<void> updateFormat(
    LibraryBook libraryBook,
    BookFormat? updatedFormat,
  ) async =>
      await _libraryClient
          .update({_SupaLibrary.formatCol: updatedFormat?.name})
          .eq(_SupaLibrary.supaIdCol, libraryBook.supaId)
          .captureStackTraceOnError();

  // We use ON DELETE CASCADE on foreign keys referencing this column, so the
  //  application doesn't need to worry about cleaning it up in this case.
  static Future<void> remove(LibraryBook book) async => await _libraryClient
      .delete()
      .eq(_SupaLibrary.supaIdCol, book.supaId)
      .captureStackTraceOnError();
}

class SupabaseStatusService {
  static final SupabaseQueryBuilder _statusClient = _base.from('status');

  static Future<void> add(
    int libraryBookId,
    ReadingStatus status, [
    DateTime? dateTime,
  ]) async {
    dateTime ??= DateTime.now();
    return await _statusClient.insert({
      _SupaStatus.libraryBookIdCol: libraryBookId,
      _SupaStatus.statusCol: status.name,
      _SupaStatus.userIdCol: SupabaseAuthService.loggedInUserId,
      _SupaStatus.timeCol: dateTime.toIso8601String(),
    }).captureStackTraceOnError();
  }

  static Future<List<StatusEvent>> history(int bookId) async {
    final queryResults = await _statusClient
        .select()
        .eq(_SupaStatus.libraryBookIdCol, bookId)
        .eq(_SupaStatus.userIdCol, SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    final list = queryResults.map(_SupaStatus.new).mapL((supaStatus) =>
        StatusEvent(time: supaStatus.time, status: supaStatus.status));
    list.sort((a, b) => a.time.difference(b.time).inSeconds);
    return list;
  }
}

class _SupaStatus {
  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  int get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  DateTime get time => DateTime.parse(rawData[timeCol]);
  static final String timeCol = 'time';

  ReadingStatus get status => (rawData[statusCol] as String?)
      .map((str) => ReadingStatus.values.firstWhere((v) => v.name == str))!;
  static final String statusCol = 'status';

  int get libraryBookId => rawData[libraryBookIdCol];
  static final String libraryBookIdCol = 'library_book_id';

  const _SupaStatus(this.rawData);

  final PostgrestMap rawData;
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

  BookFormat? get format => (rawData[formatCol] as String?)
      .map((str) => BookFormat.values.firstWhere((v) => v.name == str));
  static final String formatCol = 'format';

  int? get length => rawData[lengthCol];
  static final String lengthCol = 'length';

  const _SupaLibrary(this.rawData);

  final PostgrestMap rawData;

  static Future<List<_SupaLibrary>> forLoggedInUser() async {
    final PostgrestList rawData = await _base
        .from('library')
        .select()
        .eq('user_id', SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    return rawData.mapL(_SupaLibrary.new);
  }

  static Future<_SupaBook> bookById(int bookId) async => _SupaBook(await _base
      .from('books')
      .select()
      .eq(_SupaBook.idCol, bookId)
      .single()
      .captureStackTraceOnError());
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
    return await _progressClient.insert({
      _SupaProgress.libraryBookIdCol: book.book.supaId,
      _SupaProgress.userIdCol: SupabaseAuthService.loggedInUserId,
      _SupaProgress.formatCol: format.name,
      _SupaProgress.progressCol: userInput,
      _SupaProgress.startCol: start?.toIso8601String(),
      _SupaProgress.endCol: end?.toIso8601String(),
    }).captureStackTraceOnError();
  }

  static Future<List<ProgressEvent>> history(int bookId) async {
    final queryResults = await _progressClient
        .select()
        .eq(_SupaProgress.libraryBookIdCol, bookId)
        .eq(_SupaProgress.userIdCol, SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    return queryResults
        .map(_SupaProgress.new)
        .mapL((supaProgress) => ProgressEvent(
              end: supaProgress.endSafe,
              progress: supaProgress.progress,
              format: supaProgress.format,
              start: supaProgress.start,
            ));
  }
}

DateTime? parseDateCol(value) => (value as String?).map(DateTime.parse);
