import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_service.dart';

class SupabaseFormatService {
  static final _client = supabase.from('library_book_formats');
  static final log = SimpleLogger(prefix: 'SupabaseFormatService');

  static Future<LibraryBookFormat> addFormat({
    required int libraryBookId,
    required BookFormat format,
    int? length,
  }) async {
    final result = await _client
        .insert({
          _SupaFormat.libraryBookIdCol: libraryBookId,
          _SupaFormat.userIdCol: SupabaseAuthService.loggedInUserId,
          _SupaFormat.formatCol: format.name,
          _SupaFormat.lengthCol: length,
        })
        .select()
        .single()
        .withRetry(log);
    return _SupaFormat(result).toLibraryBookFormat;
  }

  static Future<void> updateLength(int formatId, int length) => _client
      .update({_SupaFormat.lengthCol: length})
      .eq(_SupaFormat.supaIdCol, formatId)
      .withRetry(log);

  static Future<void> deleteFormat(int formatId) =>
      _client.delete().eq(_SupaFormat.supaIdCol, formatId).withRetry(log);

  static Future<void> reassignEvents(int fromFormatId, int toFormatId) =>
      supabase
          .from('progress_events')
          .update({'format_id': toFormatId})
          .eq('format_id', fromFormatId)
          .withRetry(log);

  static Future<List<LibraryBookFormat>> formatsForBook(
      int libraryBookId) async {
    final results = await _client
        .select()
        .eq(_SupaFormat.libraryBookIdCol, libraryBookId)
        .order(_SupaFormat.formatCol, ascending: true)
        .withRetry(log);
    return results.mapL((r) => _SupaFormat(r).toLibraryBookFormat);
  }

  static Future<Map<int, List<LibraryBookFormat>>> formatsForLibraryBooks(
      List<int> libraryBookIds) async {
    if (libraryBookIds.isEmpty) return {};

    final results = await _client
        .select()
        .filter(
            _SupaFormat.libraryBookIdCol, 'in', '(${libraryBookIds.join(',')})')
        .eq(_SupaFormat.userIdCol, SupabaseAuthService.loggedInUserId!)
        .order(_SupaFormat.formatCol, ascending: true)
        .withRetry(log);

    final Map<int, List<LibraryBookFormat>> formatsMap = {};
    for (final result in results) {
      final supaFormat = _SupaFormat(result);
      formatsMap
          .putIfAbsent(supaFormat.libraryBookId, () => [])
          .add(supaFormat.toLibraryBookFormat);
    }
    return formatsMap;
  }
}

class _SupaFormat {
  const _SupaFormat(this.rawData);

  final PostgrestMap rawData;

  LibraryBookFormat get toLibraryBookFormat => LibraryBookFormat(
        supaId: supaId,
        libraryBookId: libraryBookId,
        format: format,
        length: length,
      );

  int get supaId => rawData[supaIdCol];
  static const String supaIdCol = 'id';

  int get libraryBookId => rawData[libraryBookIdCol];
  static const String libraryBookIdCol = 'library_book_id';

  String get userId => rawData[userIdCol];
  static const String userIdCol = 'user_id';

  BookFormat get format =>
      BookFormat.values.firstWhere((fmt) => fmt.name == rawData[formatCol]);
  static const String formatCol = 'format';

  int? get length => rawData[lengthCol];
  static const String lengthCol = 'length';
}
