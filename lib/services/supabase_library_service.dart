import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'book_universe_service.dart';
import 'supabase_auth_service.dart';
import 'supabase_book_service.dart';
import 'supabase_format_service.dart';
import 'supabase_progress_service.dart';
import 'supabase_service.dart';
import 'supabase_status_service.dart';

class SupabaseLibraryService {
  static final _libraryClient = supabase.from('library');
  static SimpleLogger log = SimpleLogger(prefix: 'SupabaseLibraryService');

  static Future<List<LibraryBook>> myBooks() async {
    final List<_SupaLibrary> library = await _forLoggedInUser();
    final List<int> libraryBookIds = library.map((e) => e.supaId).toList();

    final Map<int, List<ProgressEvent>> allProgressEvents =
        await SupabaseProgressService.historyForLibraryBooks(libraryBookIds);
    final Map<int, List<StatusEvent>> allStatusEvents =
        await SupabaseStatusService.historyForLibraryBooks(libraryBookIds);
    final Map<int, List<LibraryBookFormat>> allFormats =
        await SupabaseFormatService.formatsForLibraryBooks(libraryBookIds);

    final Iterable<Future<LibraryBook>> libraryBooks = library.map(
      (supaBook) => supaBook.toLibraryBook(
        allProgressEvents[supaBook.supaId] ?? [],
        allStatusEvents[supaBook.supaId] ?? [],
        allFormats[supaBook.supaId] ?? [],
      ),
    );
    return Future.wait(libraryBooks);
  }

  /// Add a book to the library with an initial format.
  /// [length] is required for new books.
  static Future<void> addBook(
    OpenLibraryBook book,
    BookFormat bookFormat,
    int length,
  ) async {
    final int bookId = await SupabaseBookService.getOrCreateBookId(book);
    final int libraryBookId = await _getOrCreateLibraryBookId(bookId);

    // Create the format entry
    final format = await SupabaseFormatService.addFormat(
      libraryBookId: libraryBookId,
      format: bookFormat,
      length: length,
    );

    // Add initial status
    await SupabaseStatusService.add(libraryBookId, ReadingStatus.reading);

    // Add initial progress event (0%)
    await SupabaseProgressService.addProgressEvent(
      formatId: format.supaId,
      newValue: 0,
      format: ProgressEventFormat.percent,
    );
  }

  static Future<void> remove(LibraryBook book) async =>
      // We use ON DELETE CASCADE on foreign keys referencing this column,
      //  so the application doesn't need to worry about cleaning it up here.
      await _libraryClient
          .delete()
          .eq(_SupaLibrary.supaIdCol, book.supaId)
          .captureStackTraceOnError();

  static Future<void> archive(LibraryBook book) async => await _libraryClient
      .update({_SupaLibrary.archivedCol: !book.archived})
      .eq(_SupaLibrary.supaIdCol, book.supaId)
      .captureStackTraceOnError();

  static Future<List<_SupaLibrary>> _forLoggedInUser() async {
    final PostgrestList rawData = await _libraryClient
        .select()
        .eq(_SupaLibrary.userIdCol, SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    return rawData.mapL(_SupaLibrary.new);
  }

  static Future<int> _getOrCreateLibraryBookId(int bookId) async =>
      await _existingLibraryBookId(bookId) ?? await _newLibraryBookId(bookId);

  static Future<int?> _existingLibraryBookId(int bookId) async {
    final PostgrestMap? preExistQuery = await _libraryClient
        .select(_SupaLibrary.supaIdCol)
        .eq(_SupaLibrary.bookIdCol, bookId)
        .eq(_SupaLibrary.userIdCol, SupabaseAuthService.loggedInUserId!)
        .limit(1)
        .maybeSingle()
        .captureStackTraceOnError();
    return preExistQuery.map(_SupaLibrary.new).map((res) => res.supaId);
  }

  static Future<int> _newLibraryBookId(int bookId) async {
    final PostgrestMap supaEntity = await _libraryClient
        .insert({
          _SupaLibrary.bookIdCol: bookId,
          _SupaLibrary.userIdCol: SupabaseAuthService.loggedInUserId,
        })
        .select(_SupaLibrary.supaIdCol)
        .limit(1)
        .single()
        .captureStackTraceOnError();
    return supaEntity[_SupaLibrary.supaIdCol];
  }
}

class _SupaLibrary {
  Future<LibraryBook> toLibraryBook(
    List<ProgressEvent> progressHistory,
    List<StatusEvent> statusHistory,
    List<LibraryBookFormat> formats,
  ) async =>
      LibraryBook(
        supaId,
        await SupabaseBookService.getBookById(bookId),
        progressHistory,
        statusHistory,
        formats,
        archived,
      );

  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]).toLocal();
  static final String createdAtCol = 'created_at';

  int get bookId => rawData[bookIdCol];
  static final String bookIdCol = 'book_id';

  String get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  bool get archived => rawData[archivedCol] ?? false;
  static final String archivedCol = 'archived';

  const _SupaLibrary(this.rawData);

  final PostgrestMap rawData;
}
