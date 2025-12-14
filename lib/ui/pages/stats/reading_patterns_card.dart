import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingPatternsCard extends ConsumerWidget {
  const ReadingPatternsCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countMode = ref.watch(statsCountModeProvider);
    return AsyncStatsCard<_ReadingPatternsData>(
      cacheKey:
          '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}-${countMode.name}',
      compute: () => _calculateData(books, periodCutoff, countMode),
      loadingHeight: 220,
      builder: (data) => _buildCard(data, countMode),
    );
  }

  Widget _buildCard(_ReadingPatternsData data, StatsCountMode countMode) {
    final subtitle = countMode == StatsCountMode.sessions
        ? 'Most Active Days (by updates)'
        : 'Most Active Days (by progress)';
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
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (data.activityByDayOfWeek.isEmpty)
              _emptyState()
            else
              _DayOfWeekChart(
                activityByDay: data.activityByDayOfWeek,
                isProgress: countMode == StatsCountMode.progress,
              ),
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
    StatsCountMode countMode,
  ) {
    if (countMode == StatsCountMode.sessions) {
      // Count sessions per day of week
      final allEvents = books
          .expand((b) => b.progressHistory)
          .where((e) => periodCutoff == null || e.end.isAfter(periodCutoff))
          .toList();

      final byDay = <int, double>{};
      for (final event in allEvents) {
        final weekday = event.end.weekday;
        byDay[weekday] = (byDay[weekday] ?? 0) + 1;
      }

      return _ReadingPatternsData(activityByDayOfWeek: byDay);
    } else {
      // Sum progress percentage made per day of week
      final byDay = <int, double>{};

      for (final book in books) {
        // Use percentage mode to get % deltas directly
        final diffs = book.pagesDiffs(percentage: true);
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
}

class _ReadingPatternsData {
  const _ReadingPatternsData({
    required this.activityByDayOfWeek,
  });

  final Map<int, double> activityByDayOfWeek;
}

class _DayOfWeekChart extends StatelessWidget {
  const _DayOfWeekChart({
    required this.activityByDay,
    this.isProgress = false,
  });

  final Map<int, double> activityByDay;
  final bool isProgress;

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double barWidth = 30.0;
  static const double maxBarHeight = 120.0;
  static const double spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        activityByDay.values.isEmpty ? 1.0 : activityByDay.values.reduce(max);

    return SizedBox(
      height: maxBarHeight + 40, // Add space for labels
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1; // 1=Monday
          final value = activityByDay[weekday] ?? 0;
          return _dayBar(dayNames[index], value, maxValue);
        }),
      ),
    );
  }

  Widget _dayBar(String day, double value, double maxValue) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    final barHeight = maxBarHeight * fraction;

    // Format the label based on mode
    final label = isProgress ? '${value.round()}%' : '${value.round()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bar
        Container(
          width: barWidth,
          height: barHeight > 0 ? barHeight : 0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                // Bottom (zero/x-axis) - more visible green
                CupertinoColors.systemGreen.withOpacity(0.5),
                // Top (max height) - richer green
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
        // Day label
        Text(
          day,
          style:
              const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 2),
        // Count label
        Text(
          label,
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
