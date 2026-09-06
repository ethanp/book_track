import 'dart:math' show max;

import 'package:ethan_utils/ethan_utils.dart';

import 'package:book_track/data_model.dart';

/// Data class for reading activity statistics.
class const ReadingActivityData({
  required final Map<DateTime, int> activityByDay,
  required final int currentStreak,
  required final int longestStreak,
}) {
  int get maxDailyPercentDelta =>
      activityByDay.isEmpty ? 0 : activityByDay.values.max;
  /// Calculate reading activity based on progress percentage made per day.
  factory fromProgress(List<LibraryBook> books, {DateTime? periodCutoff}) {
    final activityByDay = <DateTime, int>{};
    final cutoffDate = periodCutoff.map((d) => d.startOfDay);

    for (final book in books) {
      // Use percentage mode to get % deltas directly
      final diffs = book.progressDiffs;
      for (final diff in diffs) {
        final date = diff.key.startOfDay;

        // Filter by period cutoff
        if (cutoffDate != null && date.isBefore(cutoffDate)) continue;

        final percentDelta = diff.value;
        if (percentDelta > 0) {
          activityByDay[date] =
              (activityByDay[date] ?? 0) + percentDelta.round();
        }
      }
    }

    final (current, longest) = _streaksIfReadTodayOrYesterday(
      activityByDay.keys.toList(),
    );

    return ReadingActivityData(
      activityByDay: activityByDay,
      currentStreak: current,
      longestStreak: longest,
    );
  }

  static (int current, int longest) _streaksIfReadTodayOrYesterday(
    List<DateTime> activeDays,
  ) {
    if (activeDays.isEmpty) return (0, 0);

    final sorted = activeDays.toList()..sort();
    final today = DateTime.now().startOfDay;
    final yesterday = today.shiftedByDays(-1);

    int currentStreak = 0;
    int longestStreak = 0;
    int runningStreak = 1;

    // Check if streak is active (today or yesterday has activity)
    final hasRecentActivity =
        sorted.last.sameDayAs(today) || sorted.last.sameDayAs(yesterday);

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        runningStreak++;
      } else if (diff > 1) {
        longestStreak = max(longestStreak, runningStreak);
        runningStreak = 1;
      }
      // diff == 0 means same day, keep runningStreak as is
    }
    longestStreak = max(longestStreak, runningStreak);

    // Current streak only counts if it's ongoing
    if (hasRecentActivity) {
      currentStreak = runningStreak;
    }

    return (currentStreak, longestStreak);
  }
}
