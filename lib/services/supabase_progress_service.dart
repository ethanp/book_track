import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseProgressService {
  static final _progressClient = supabase.from('progress_events');

  static Future<void> updateProgress({
    required int bookId,
    required int newValue,
    required ProgressEventFormat format,
    DateTime? start,
    DateTime? end,
  }) async =>
      await _progressClient.insert({
        _SupaProgress.libraryBookIdCol: bookId,
        _SupaProgress.userIdCol: SupabaseAuthService.loggedInUserId,
        _SupaProgress.formatCol: format.name,
        _SupaProgress.progressCol: newValue,
        // This is the date-time format that works well with Supabase/Postgres.
        _SupaProgress.startCol: start?.toIso8601String(),
        _SupaProgress.endCol: end?.toIso8601String(),
      }).captureStackTraceOnError();

  static Future<List<ProgressEvent>> history(int bookId) async {
    final queryResults = await _progressClient
        .select()
        .eq(_SupaProgress.libraryBookIdCol, bookId)
        .eq(_SupaProgress.userIdCol, SupabaseAuthService.loggedInUserId!)
        .order(_SupaProgress.endCol)
        .captureStackTraceOnError();
    return queryResults.mapL((result) => _SupaProgress(result).toProgressEvent);
  }

  static Future<void> delete(ProgressEvent ev) async => await _progressClient
      .delete()
      .eq(_SupaProgress.supaIdCol, ev.supaId)
      .captureStackTraceOnError();
}

class _SupaProgress {
  const _SupaProgress(this.rawData);

  final PostgrestMap rawData;

  // static SimpleLogger log = SimpleLogger(prefix: '_SupaProgress');

  ProgressEvent get toProgressEvent => ProgressEvent(
        supaId: supaId,
        end: endSafe,
        progress: progress,
        format: format,
        start: start,
      );

  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  /// Returns [createdAt] in device-local timezone.
  /// Original field set by Postgres to UTC.
  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]).toLocal();

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
