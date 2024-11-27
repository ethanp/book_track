import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseProgressService {
  static final _progressClient = supabase.from('progress_events');

  static Future<void> updateProgress({
    required LibraryBook book,
    required int userInput,
    required ProgressEventFormat format,
    DateTime? start,
    DateTime? end,
  }) async =>
      await _progressClient.insert({
        _SupaProgress.libraryBookIdCol: book.supaId,
        _SupaProgress.userIdCol: SupabaseAuthService.loggedInUserId,
        _SupaProgress.formatCol: format.name,
        _SupaProgress.progressCol: userInput,
        // This is the date-time format that works well with Supabase/Postgres.
        _SupaProgress.startCol: start?.toIso8601String(),
        _SupaProgress.endCol: end?.toIso8601String(),
      }).captureStackTraceOnError();

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
