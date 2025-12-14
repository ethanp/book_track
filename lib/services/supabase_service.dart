import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connects this app to its Supabase BaaS.
final SupabaseClient supabase = Supabase.instance.client;

/// Parses a data time from Postgres.
DateTime? parseDateCol(dynamic value) => (value as String?).map(DateTime.parse);

/// Extension to add retry with stack trace capture in one call.
extension SupabaseRetry<T> on Future<T> {
  /// Captures stack trace and retries on network errors.
  Future<T> withRetry(SimpleLogger? log) =>
      captureStackTraceOnError().withNetworkRetry(logger: log);
}
