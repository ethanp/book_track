import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseStatusService {
  static final SupabaseQueryBuilder _statusClient = supabase.from('status');

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
        .captureStackTraceOnError();
  }

  static Future<List<StatusEvent>> history(int libraryBookId) async {
    final queryResults = await _statusClient
        .select()
        .eq(_SupaStatus.libraryBookIdCol, libraryBookId)
        .eq(_SupaStatus.userIdCol, SupabaseAuthService.loggedInUserId!)
        .captureStackTraceOnError();
    final supaStatus = queryResults.map(_SupaStatus.new);
    final statuses = supaStatus.mapL((supaStatus) => StatusEvent(
          time: supaStatus.time,
          status: supaStatus.status,
        ));
    statuses.sort((a, b) => a.time.difference(b.time).inSeconds);
    return statuses;
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
