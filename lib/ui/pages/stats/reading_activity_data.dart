import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:flutter/material.dart' show DateUtils;

/// Data class for reading activity statistics.
class ReadingActivityData {
  const ReadingActivityData({
    required this.activityByDay,
    required this.currentStreak,
    required this.longestStreak,
  });

  final Map<DateTime, int> activityByDay;
  final int currentStreak;
  final int longestStreak;

  /// Calculate reading activity based on progress percentage made per day.
  factory ReadingActivityData.fromProgress(
    List<LibraryBook> books, {
    DateTime? periodCutoff,
  }) {
    final activityByDay = <DateTime, int>{};
    final cutoffDate =
        periodCutoff != null ? DateUtils.dateOnly(periodCutoff) : null;

    for (final book in books) {
      // Use percentage mode to get % deltas directly
      final diffs = book.progressDiffs;
      for (final diff in diffs) {
        final date = DateUtils.dateOnly(diff.key);

        // Filter by period cutoff
        if (cutoffDate != null && date.isBefore(cutoffDate)) continue;

        final percentDelta = diff.value;
        if (percentDelta > 0) {
          activityByDay[date] =
              (activityByDay[date] ?? 0) + percentDelta.round();
        }
      }
    }

    final (current, longest) = _calculateStreaks(activityByDay.keys.toList());

    return ReadingActivityData(
      activityByDay: activityByDay,
      currentStreak: current,
      longestStreak: longest,
    );
  }

  static (int current, int longest) _calculateStreaks(
      List<DateTime> activeDays) {
    if (activeDays.isEmpty) return (0, 0);

    final sorted = activeDays.toList()..sort();
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    int longestStreak = 0;
    int runningStreak = 1;

    // Check if streak is active (today or yesterday has activity)
    final hasRecentActivity = DateUtils.isSameDay(sorted.last, today) ||
        DateUtils.isSameDay(sorted.last, yesterday);

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
