import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_per_month_chart.dart';
import 'package:book_track/ui/pages/stats/rolling_average_chart.dart';
import 'package:flutter/cupertino.dart';

enum ProgressViewMode { monthly, rolling }

class ProgressChartCard extends StatefulWidget {
  const ProgressChartCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  State<ProgressChartCard> createState() => _ProgressChartCardState();
}

class _ProgressChartCardState extends State<ProgressChartCard> {
  ProgressViewMode mode = ProgressViewMode.rolling;

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
          _modeToggle(),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
              child: mode == ProgressViewMode.monthly
                  ? ProgressPerMonthChart(
                      books: widget.books,
                      periodCutoff: widget.periodCutoff,
                    )
                  : RollingAverageChart(
                      books: widget.books,
                      periodCutoff: widget.periodCutoff,
                    ),
            ),
          ),
          _trendRow(),
        ],
      ),
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
          Text(
            trend.description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  _TrendData _calculateTrend() {
    // Compare reading volume: current calendar month vs previous calendar month
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;

    double currentMonthVolume = 0;
    double previousMonthVolume = 0;

    for (final book in widget.books) {
      if (book.formats.isEmpty) continue;
      final diffs = book.pagesDiffs();
      // Convert audiobook minutes to equivalent pages (5 mins = 1 page)
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

    // Estimate full month based on days elapsed
    final estimatedCurrentMonth = daysElapsed > 0
        ? currentMonthVolume / daysElapsed * daysInCurrentMonth
        : 0.0;

    if (previousMonthVolume == 0 && currentMonthVolume > 0) {
      return const _TrendData(
        emoji: '📈',
        description: 'Started reading this month!',
      );
    }
    if (previousMonthVolume == 0 && currentMonthVolume == 0) {
      return const _TrendData(
        emoji: '➡️',
        description: 'No recent reading activity',
      );
    }

    final trend = previousMonthVolume > 0
        ? estimatedCurrentMonth / previousMonthVolume
        : 1.0;

    if ((trend - 1.0).abs() < 0.05) {
      return const _TrendData(
        emoji: '➡️',
        description: 'On pace with last month',
      );
    }

    final percent = ((trend - 1) * 100).abs().round();
    if (trend > 1) {
      return _TrendData(
        emoji: '📈',
        description: 'On pace for $percent% more than last month',
      );
    } else {
      return _TrendData(
        emoji: '📉',
        description: 'On pace for $percent% less than last month',
      );
    }
  }

  Widget _modeToggle() {
    return CupertinoSlidingSegmentedControl<ProgressViewMode>(
      groupValue: mode,
      children: const {
        ProgressViewMode.monthly: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Monthly', style: TextStyle(fontSize: 13)),
        ),
        ProgressViewMode.rolling: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Momentum', style: TextStyle(fontSize: 13)),
        ),
      },
      onValueChanged: (value) {
        if (value != null) setState(() => mode = value);
      },
    );
  }
}

class _TrendData {
  const _TrendData({
    required this.emoji,
    required this.description,
  });

  final String emoji;
  final String description;
}
