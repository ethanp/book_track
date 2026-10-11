import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';

import 'day_of_week_chart.dart';

class const ReadingPatternsCard({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _card(_calculateData(books, periodCutoff));
  }

  Widget _card(_ReadingPatternsData data) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Reading Patterns', style: AppTextStyles.h3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Most Active Days (by progress)', style: AppTextStyles.h5),
            const SizedBox(height: AppSpacing.sm),
            if (data.activityByDayOfWeek.isEmpty)
              _emptyState()
            else
              DayOfWeekChart(activityByDay: data.activityByDayOfWeek),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'No reading activity in this period',
          style: AppTextStyles.bodySecondary,
        ),
      ),
    );
  }

  static _ReadingPatternsData _calculateData(
    List<LibraryBook> books,
    DateTime? periodCutoff,
  ) {
    final byDay = <int, double>{};
    for (final book in books) {
      final diffs = book.progressDiffs;
      for (final diff in diffs) {
        if (periodCutoff != null && diff.key.isBefore(periodCutoff)) continue;
        final weekday = diff.key.weekday;
        final percentDelta = diff.value;
        if (percentDelta > 0) {
          byDay[weekday] = (byDay[weekday] ?? 0) + percentDelta;
        }
      }
    }
    return _ReadingPatternsData(activityByDayOfWeek: byDay);
  }
}

class const _ReadingPatternsData({
  required final Map<int, double> activityByDayOfWeek,
});
