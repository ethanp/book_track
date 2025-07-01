import 'package:book_track/extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connects this app to its Supabase BaaS.
final SupabaseClient supabase = Supabase.instance.client;

/// Parses a data time from Postgres.
DateTime? parseDateCol(dynamic value) => (value as String?).map(DateTime.parse);
