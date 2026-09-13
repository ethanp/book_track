import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class FormatsRepository(final PowerSyncDatabase _powerSync) {
  static const _uuid = Uuid();

  Future<LibraryBookFormat> addFormat({
    required String libraryBookId,
    required BookFormat format,
    int? length,
  }) async {
    final formatId = _uuid.v4();
    await _powerSync.upsert('library_book_formats', {
      'id': formatId,
      'library_book_id': libraryBookId,
      'format_name': format.name,
      'length': length,
    });
    return LibraryBookFormat(
      id: formatId,
      libraryBookId: libraryBookId,
      format: format,
      length: length,
    );
  }

  Future<void> updateLength(String formatId, int length) async {
    await _powerSync.execute(
      'UPDATE library_book_formats SET length = ? WHERE id = ?',
      [length, formatId],
    );
  }

  Future<void> deleteFormat(String formatId) async {
    await _powerSync.execute('DELETE FROM library_book_formats WHERE id = ?', [
      formatId,
    ]);
  }

  Future<void> reassignEvents(String fromFormatId, String toFormatId) async {
    await _powerSync.execute(
      'UPDATE progress_events SET format_id = ? WHERE format_id = ?',
      [toFormatId, fromFormatId],
    );
  }

  Future<Map<String, List<LibraryBookFormat>>> formatsForLibraryBooks(
    List<String> libraryBookIds,
  ) async {
    if (libraryBookIds.isEmpty) return {};
    final formatRows = await _powerSync.getAll(
      'SELECT * FROM library_book_formats ORDER BY format_name ASC',
    );
    final formatsByLibraryBookId = <String, List<LibraryBookFormat>>{};
    for (final formatRow in formatRows) {
      final format = _mapToFormat(formatRow);
      if (!libraryBookIds.contains(format.libraryBookId)) continue;
      formatsByLibraryBookId
          .putIfAbsent(format.libraryBookId, () => [])
          .add(format);
    }
    return formatsByLibraryBookId;
  }

  static LibraryBookFormat _mapToFormat(Map<String, dynamic> formatRow) {
    return LibraryBookFormat(
      id: formatRow['id'] as String,
      libraryBookId: formatRow['library_book_id'] as String,
      format: BookFormat.values.firstWhere(
        (bookFormat) => bookFormat.name == formatRow['format_name'],
      ),
      length: formatRow['length'] as int?,
    );
  }
}
