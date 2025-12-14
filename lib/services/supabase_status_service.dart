import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseStatusService {
  static final SupabaseQueryBuilder _statusClient = supabase.from('status');
  static final log = SimpleLogger(prefix: 'SupabaseStatusService');

  static Future<PostgrestMap> add(
    int libraryBookId,
    ReadingStatus status, [
    DateTime? dateTime,
  ]) async {
    dateTime ??= DateTime.now();
    return await _statusClient
        .insert({
          _SupaStatus.libraryBookIdCol: libraryBookId,
          _SupaStatus.statusCol: status.name,
          _SupaStatus.userIdCol: SupabaseAuthService.loggedInUserId,
          _SupaStatus.timeCol: dateTime.toIso8601String(),
        })
        .select()
        .single()
        .withRetry(log);
  }

  static Future<List<StatusEvent>> history(int libraryBookId) async {
    final queryResults = await _statusClient
        .select()
        .eq(_SupaStatus.libraryBookIdCol, libraryBookId)
        .eq(_SupaStatus.userIdCol, SupabaseAuthService.loggedInUserId!)
        .withRetry(log);
    final supaStatus = queryResults.map(_SupaStatus.new);
    final statuses = supaStatus.mapL((supaStatus) => StatusEvent(
          supaId: supaStatus.supaId,
          time: supaStatus.time,
          status: supaStatus.status,
        ));
    statuses.sort((a, b) => a.time.difference(b.time).inSeconds);
    return statuses;
  }

  static Future<void> delete(StatusEvent ev) => _statusClient
      .delete()
      .eq(_SupaStatus.supaIdCol, ev.supaId)
      .withRetry(log);

  static Future<Map<int, List<StatusEvent>>> historyForLibraryBooks(
      List<int> libraryBookIds) async {
    final queryResults = await _statusClient
        .select()
        .filter(
            _SupaStatus.libraryBookIdCol, 'in', '(${libraryBookIds.join(',')})')
        .eq(_SupaStatus.userIdCol, SupabaseAuthService.loggedInUserId!)
        .withRetry(log);

    final Map<int, List<StatusEvent>> statusEventsMap = {};
    for (final result in queryResults) {
      final supaStatus = _SupaStatus(result);
      statusEventsMap
          .putIfAbsent(supaStatus.libraryBookId, () => [])
          .add(StatusEvent(
            supaId: supaStatus.supaId,
            time: supaStatus.time,
            status: supaStatus.status,
          ));
    }
    return statusEventsMap;
  }
}

class _SupaStatus {
  // static final SimpleLogger log = SimpleLogger(prefix: '_SupaStatus');

  int get supaId => rawData[supaIdCol];
  static final String supaIdCol = 'id';

  DateTime get createdAt => DateTime.parse(rawData[createdAtCol]);
  static final String createdAtCol = 'created_at';

  int get userId => rawData[userIdCol];
  static final String userIdCol = 'user_id';

  DateTime get time => DateTime.parse(rawData[timeCol]);
  static final String timeCol = 'time';

  ReadingStatus get status => (rawData[statusCol] as String?).map((str) {
        // Backward compatibility.
        if (str == 'completed') return ReadingStatus.finished;
        return ReadingStatus.values.firstWhere((v) => v.name == str);
      })!;
  static final String statusCol = 'status';

  int get libraryBookId => rawData[libraryBookIdCol];
  static final String libraryBookIdCol = 'library_book_id';

  const _SupaStatus(this.rawData);

  final PostgrestMap rawData;
}
