import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_per_month_chart.dart';
import 'package:book_track/ui/pages/stats/rolling_average_chart.dart';
import 'package:flutter/cupertino.dart';

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 12),
            child: Text('Reading Progress', style: TextStyles.h3),
          ),
          _chartSection(
              'Momentum',
              RollingAverageChart(
                books: books,
                periodCutoff: periodCutoff,
              )),
          _chartSection(
              'Monthly',
              ProgressPerMonthChart(
                books: books,
                periodCutoff: periodCutoff,
              )),
          _trendRow(),
        ],
      ),
    );
  }

  Widget _chartSection(String label, Widget chart) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
            child: chart,
          ),
        ),
      ],
    );
  }

  Widget _trendRow() {
    final trend = _calculateTrend();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(trend.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(trend.description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  _TrendData _calculateTrend() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;

    double currentMonthVolume = 0;
    double previousMonthVolume = 0;

    for (final book in books) {
      if (book.formats.isEmpty) continue;
      final diffs = book.pagesDiffs();
      final conversionFactor = book.isAudiobook ? 1.0 / 5.0 : 1.0;

      for (final diff in diffs) {
        final value = diff.value * conversionFactor;
        if (!diff.key.isBefore(currentMonthStart)) {
          currentMonthVolume += value;
        } else if (!diff.key.isBefore(previousMonthStart) &&
            diff.key.isBefore(currentMonthStart)) {
          previousMonthVolume += value;
        }
      }
    }

    final estimatedCurrentMonth = daysElapsed > 0
        ? currentMonthVolume / daysElapsed * daysInCurrentMonth
        : 0.0;

    if (previousMonthVolume == 0 && currentMonthVolume > 0) {
      return const _TrendData(
          emoji: '📈', description: 'Started reading this month!');
    }
    if (previousMonthVolume == 0 && currentMonthVolume == 0) {
      return const _TrendData(
          emoji: '➡️', description: 'No recent reading activity');
    }

    final trend = previousMonthVolume > 0
        ? estimatedCurrentMonth / previousMonthVolume
        : 1.0;

    if ((trend - 1.0).abs() < 0.05) {
      return const _TrendData(
          emoji: '➡️', description: 'On pace with last month');
    }

    final percent = ((trend - 1) * 100).abs().round();
    return trend > 1
        ? _TrendData(
            emoji: '📈',
            description: 'On pace for $percent% more than last month')
        : _TrendData(
            emoji: '📉',
            description: 'On pace for $percent% less than last month');
  }
}

class _TrendData {
  const _TrendData({required this.emoji, required this.description});

  final String emoji;
  final String description;
}
