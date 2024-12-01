import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'book_universe_service.dart';
import 'supabase_auth_service.dart';
import 'supabase_book_service.dart';
import 'supabase_progress_service.dart';
import 'supabase_service.dart';
import 'supabase_status_service.dart';

class SupabaseLibraryService {
  static final _libraryClient = supabase.from('library');
  static SimpleLogger log = SimpleLogger(prefix: 'SupabaseLibraryService');

  static Future<List<LibraryBook>> myBooks() async {
    final List<_SupaLibrary> library = await _forLoggedInUser();
    final Iterable<Future<LibraryBook>> libraryBooks =
        library.map((supaBook) => supaBook.toLibraryBook);
    return Future.wait(libraryBooks);
  }

  static Future<void> addBook(OpenLibraryBook book, BookFormat bookType) async {
    final int bookId = await SupabaseBookService.getOrCreateBookId(book);
    final int libraryBookId =
        await _getOrCreateLibraryBookId(bookId, bookType, book.numPagesMedian);
    await SupabaseStatusService.add(libraryBookId, ReadingStatus.reading);
    await SupabaseProgressService.updateProgress(
      bookId: libraryBookId,
      newValue: 0,
      format: ProgressEventFormat.percent,
    );
  }

  static Future<void> updateFormat(
    LibraryBook libraryBook,
    BookFormat? updatedFormat,
  ) async =>
      await _libraryClient
          .update({_SupaLibrary.formatCol: updatedFormat?.name})
          .eq(_SupaLibrary.supaIdCol, libraryBook.supaId)
          .captureStackTraceOnError();

  static Future<void> updateLength(
    LibraryBook libraryBook,
    int updatedLength,
  ) async =>
      await _libraryClient
          .update({_SupaLibrary.lengthCol: updatedLength})
          .eq(_SupaLibrary.supaIdCol, libraryBook.supaId)
          .captureStackTraceOnError();

  static Future<void> remove(LibraryBook book) async =>
      // We use ON DELETE CASCADE on foreign keys referencing this column,
      //  so the application doesn't need to worry about cleaning it up here.
      await _libraryClient
          .delete()
          .eq(_SupaLibrary.supaIdCol, book.supaId)
          .captureStackTraceOnError();

  static Future<List<_SupaLibrary>> _forLoggedInUser() async {
    final PostgrestList rawData = await _libraryClient
        .select()
        .eq(_SupaLibrary.userIdCol, SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    return rawData.mapL(_SupaLibrary.new);
  }

  static Future<int> _getOrCreateLibraryBookId(
          int bookId, BookFormat bookType, int? numPagesMedian) async =>
      await _existingLibraryBookId(bookId, bookType) ??
      await _newLibraryBookId(bookId, bookType, numPagesMedian);

  static Future<int?> _existingLibraryBookId(
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

  static Future<int> _newLibraryBookId(
      int bookId, BookFormat bookType, int? numPagesMedian) async {
    final PostgrestMap supaEntity = await _libraryClient
        .insert({
          _SupaLibrary.bookIdCol: bookId,
          _SupaLibrary.userIdCol: SupabaseAuthService.loggedInUserId,
          _SupaLibrary.formatCol: bookType.name,
          _SupaLibrary.lengthCol: numPagesMedian,
        })
        .select(_SupaLibrary.supaIdCol)
        .limit(1)
        .single()
        .captureStackTraceOnError();
    return supaEntity[_SupaLibrary.supaIdCol];
  }
}

class _SupaLibrary {
  Future<LibraryBook> get toLibraryBook async => LibraryBook(
        supaId,
        await SupabaseBookService.getBookById(bookId),
        await SupabaseProgressService.history(supaId),
        await SupabaseStatusService.history(supaId),
        format,
        length,
      );

  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]).toLocal();
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
}
