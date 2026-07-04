import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';

class ReadingPatternsCard extends StatelessWidget {
  const ReadingPatternsCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    return AsyncStatsCard<_ReadingPatternsData>(
      cacheKey: '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}',
      compute: () => _calculateData(books, periodCutoff),
      loadingHeight: 220,
      builder: _buildCard,
    );
  }

  Widget _buildCard(_ReadingPatternsData data) {
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
              _DayOfWeekChart(activityByDay: data.activityByDayOfWeek),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
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

class _ReadingPatternsData {
  const _ReadingPatternsData({required this.activityByDayOfWeek});

  final Map<int, double> activityByDayOfWeek;
}

class _DayOfWeekChart extends StatelessWidget {
  const _DayOfWeekChart({required this.activityByDay});

  final Map<int, double> activityByDay;

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double barWidth = 30.0;
  static const double maxBarHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        activityByDay.values.isEmpty ? 1.0 : activityByDay.values.max;

    return SizedBox(
      height: maxBarHeight + 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final dayValue = activityByDay[weekday] ?? 0;
          return _dayBar(dayNames[index], dayValue, maxValue);
        }),
      ),
    );
  }

  Widget _dayBar(String day, double dayValue, double maxValue) {
    final fraction = maxValue > 0 ? dayValue / maxValue : 0.0;
    final barHeight = maxBarHeight * fraction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: barWidth,
          height: barHeight > 0 ? barHeight : 0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.teal.withValues(alpha: 0.4),
                AppColors.teal.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(day, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          '${dayValue.round()}%',
          style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
