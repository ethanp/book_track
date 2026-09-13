import 'package:book_track/data_model.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class ProgressEventsRepository(final PowerSyncDatabase _powerSync) {
  static const _uuid = Uuid();

  Future<void> addProgressEvent({
    required String libraryBookId,
    required String formatId,
    required int newValue,
    required ProgressEventFormat format,
    DateTime? end,
  }) async {
    final endedAt = end ?? DateTime.now();
    await _powerSync.upsert('progress_events', {
      'id': _uuid.v4(),
      'library_book_id': libraryBookId,
      'format_id': formatId,
      'progress': newValue,
      'format_kind': format.name,
      'started_at': null,
      'ended_at': endedAt.toIso8601String(),
    });
  }

  Future<void> updateProgressEvent({
    required ProgressEvent preexistingEvent,
    required int updatedValue,
    required ProgressEventFormat format,
    required String formatId,
    required DateTime end,
  }) async {
    await _powerSync.execute(
      'UPDATE progress_events SET format_id = ?, progress = ?, '
      'format_kind = ?, ended_at = ? WHERE id = ?',
      [
        formatId,
        updatedValue,
        format.name,
        end.toIso8601String(),
        preexistingEvent.id,
      ],
    );
  }

  Future<void> delete(ProgressEvent progressEvent) async {
    await _powerSync.execute('DELETE FROM progress_events WHERE id = ?', [
      progressEvent.id,
    ]);
  }

  Future<Map<String, List<ProgressEvent>>> historyForLibraryBooks(
    List<String> libraryBookIds,
  ) async {
    if (libraryBookIds.isEmpty) return {};
    final eventRows = await _powerSync.getAll(
      'SELECT * FROM progress_events ORDER BY ended_at ASC',
    );
    final eventsByLibraryBookId = <String, List<ProgressEvent>>{};
    for (final eventRow in eventRows) {
      final libraryBookId = eventRow['library_book_id'] as String;
      if (!libraryBookIds.contains(libraryBookId)) continue;
      eventsByLibraryBookId
          .putIfAbsent(libraryBookId, () => [])
          .add(_mapToProgressEvent(eventRow));
    }
    return eventsByLibraryBookId;
  }

  static ProgressEvent _mapToProgressEvent(Map<String, dynamic> eventRow) {
    return ProgressEvent(
      id: eventRow['id'] as String,
      formatId: eventRow['format_id'] as String,
      end: DateTime.parse(eventRow['ended_at'] as String).toLocal(),
      progress: eventRow['progress'] as int,
      format: ProgressEventFormat.map[eventRow['format_kind'] as String]!,
    );
  }
}
