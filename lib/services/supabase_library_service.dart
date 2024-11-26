import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'book_universe_service.dart';
import 'supabase_auth_service.dart';
import 'supabase_book_service.dart';
import 'supabase_progress_service.dart';
import 'supabase_service.dart';
import 'supabase_status_service.dart';

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
    final libraryBooks = library.map((_SupaLibrary supaLibraryBook) async {
      final int bookId = supaLibraryBook.bookId;
      final Book book = await SupabaseBookService.bookById(bookId);
      final progressHistory = await SupabaseProgressService.history(bookId);
      final statusHistory = await SupabaseStatusService.history(bookId);
      return LibraryBook(
        supaLibraryBook.supaId,
        book,
        progressHistory,
        statusHistory,
        supaLibraryBook.format,
        supaLibraryBook.length,
      );
    });
    return Future.wait(libraryBooks);
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
