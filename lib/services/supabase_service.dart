import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_book_service.dart';

final SupabaseClient supabase = Supabase.instance.client;

class SupabaseLibraryService {
  static final _libraryClient = supabase.from('library');

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
      final Book supaBook = await SupabaseBookService.bookById(bookId);
      final progressHistory = await SupabaseProgressService.history(bookId);
      final statusHistory = await SupabaseStatusService.history(bookId);
      return LibraryBook(
        myBook.supaId,
        supaBook,
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
  static final SupabaseQueryBuilder _statusClient = supabase.from('status');

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
    final PostgrestList rawData = await supabase
        .from('library')
        .select()
        .eq('user_id', SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    return rawData.mapL(_SupaLibrary.new);
  }
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
      supabase.from('progress_events');

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
