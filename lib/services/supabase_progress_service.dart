import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseProgressService {
  static final _progressClient = supabase.from('progress_events');

  /// [end] defaults to [DateTime.now].
  static Future<void> addProgressEvent({
    required int formatId,
    required int newValue,
    required ProgressEventFormat format,
    DateTime? start,
    DateTime? end,
  }) async =>
      await _progressClient.insert({
        _SupaProgress.formatIdCol: formatId,
        _SupaProgress.userIdCol: SupabaseAuthService.loggedInUserId,
        _SupaProgress.formatCol: format.name,
        _SupaProgress.progressCol: newValue,
        // This is the date-time format that works well with Supabase/Postgres.
        _SupaProgress.startCol: start?.toIso8601String(),
        _SupaProgress.endCol: (end ?? DateTime.now()).toIso8601String(),
      }).captureStackTraceOnError();

  static Future<void> updateProgressEvent({
    required ProgressEvent preexistingEvent,
    required int updatedValue,
    required ProgressEventFormat format,
    DateTime? start,
    required DateTime end,
  }) async =>
      await _progressClient
          .update({
            _SupaProgress.progressCol: updatedValue,
            _SupaProgress.formatCol: format.name,
            _SupaProgress.startCol: start?.toIso8601String(),
            _SupaProgress.endCol: end.toIso8601String(),
            // Out of lack of need thus far, we don't store "updated-at timestamp".
          })
          .eq(_SupaProgress.supaIdCol, preexistingEvent.supaId)
          .captureStackTraceOnError();

  static Future<List<ProgressEvent>> history(int bookId) async {
    final queryResults = await _progressClient
        .select()
        .eq(_SupaProgress.libraryBookIdCol, bookId)
        .eq(_SupaProgress.userIdCol, SupabaseAuthService.loggedInUserId!)
        .order(_SupaProgress.endCol, ascending: true)
        .captureStackTraceOnError();
    return queryResults.mapL((result) => _SupaProgress(result).toProgressEvent);
  }

  static Future<void> delete(ProgressEvent ev) async => await _progressClient
      .delete()
      .eq(_SupaProgress.supaIdCol, ev.supaId)
      .captureStackTraceOnError();

  static Future<Map<int, List<ProgressEvent>>> historyForLibraryBooks(
      List<int> libraryBookIds) async {
    if (libraryBookIds.isEmpty) return {};

    final queryResults = await _progressClient
        .select()
        .filter(_SupaProgress.libraryBookIdCol, 'in',
            '(${libraryBookIds.join(',')})')
        .eq(_SupaProgress.userIdCol, SupabaseAuthService.loggedInUserId!)
        .order(_SupaProgress.endCol, ascending: true)
        .captureStackTraceOnError();

    final Map<int, List<ProgressEvent>> progressEventsMap = {};
    for (final result in queryResults) {
      final supaProgress = _SupaProgress(result);
      progressEventsMap
          .putIfAbsent(supaProgress.libraryBookId, () => [])
          .add(supaProgress.toProgressEvent);
    }
    return progressEventsMap;
  }
}

class _SupaProgress {
  const _SupaProgress(this.rawData);

  final PostgrestMap rawData;

  // static SimpleLogger log = SimpleLogger(prefix: '_SupaProgress');

  ProgressEvent get toProgressEvent => ProgressEvent(
        supaId: supaId,
        formatId: formatId,
        end: end,
        progress: progress,
        format: format,
        start: start,
      );

  int get supaId => rawData[supaIdCol];
  static const String supaIdCol = 'id';

  /// Returns [createdAt] in device-local timezone.
  /// Original field set by Postgres to UTC.
  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]).toLocal();

  static const String createdAtCol = 'created_at';

  int get libraryBookId => rawData[libraryBookIdCol];
  static const String libraryBookIdCol = 'library_book_id';

  int get formatId => rawData[formatIdCol] ?? 0;
  static const String formatIdCol = 'format_id';

  String get userId => rawData[userIdCol];
  static const String userIdCol = 'user_id';

  ProgressEventFormat get format =>
      ProgressEventFormat.map[rawData[formatCol]]!;
  static const String formatCol = 'format';

  int get progress => rawData[progressCol];
  static const String progressCol = 'progress';

  DateTime? get start => parseDateCol(rawData[startCol]);
  static const String startCol = 'start';

  DateTime get end => parseDateCol(rawData[endCol])!;
  static const String endCol = 'end';
}
