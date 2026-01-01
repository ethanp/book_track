import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('Reading Patterns', style: TextStyles.h3)),
            const SizedBox(height: 16),
            const Text(
              'Most Active Days (by progress)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
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
          style: TextStyle(color: CupertinoColors.systemGrey),
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
  const _ReadingPatternsData({
    required this.activityByDayOfWeek,
  });

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
        activityByDay.values.isEmpty ? 1.0 : activityByDay.values.reduce(max);

    return SizedBox(
      height: maxBarHeight + 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final value = activityByDay[weekday] ?? 0;
          return _dayBar(dayNames[index], value, maxValue);
        }),
      ),
    );
  }

  Widget _dayBar(String day, double value, double maxValue) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
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
                CupertinoColors.systemGreen.withOpacity(0.5),
                CupertinoColors.systemGreen.withOpacity(0.85),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style:
              const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.round()}%',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
