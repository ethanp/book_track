import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';

/// Shared stats utilities for filtering and grouping data.
class StatsUtils {
  StatsUtils._();

  /// Filter progress events to those after the cutoff date.
  static List<ProgressEvent> filterEventsByPeriod(
    List<ProgressEvent> events,
    DateTime cutoff,
  ) {
    return events.whereL((e) => e.end.isAfter(cutoff));
  }

  /// Filter books to those with activity after the cutoff date.
  static List<LibraryBook> filterBooksByPeriod(
    List<LibraryBook> books,
    DateTime cutoff,
  ) {
    return books
        .where((book) => book.progressHistory.any((e) => e.end.isAfter(cutoff)))
        .toList();
  }

  /// Group progress events by date (normalized to midnight).
  static Map<DateTime, List<ProgressEvent>> groupEventsByDate(
    List<ProgressEvent> events,
  ) {
    final map = <DateTime, List<ProgressEvent>>{};
    for (final event in events) {
      final date = event.end.startOfDay;
      map.putIfAbsent(date, () => []).add(event);
    }
    return map;
  }

  /// Get all progress events from a list of books.
  static List<ProgressEvent> allEvents(List<LibraryBook> books) {
    return books.expand((b) => b.progressHistory).toList();
  }
}
