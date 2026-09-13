import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class const ProgressByPeriodChart({
  required final List<LibraryBook> books,
  required final StatsPeriod period,
}) extends StatefulWidget {
  @override
  State<ProgressByPeriodChart> createState() => _ProgressByPeriodChartState();
}

class _ProgressByPeriodChartState() extends State<ProgressByPeriodChart> {
  DateTime? _selectedBucket;

  _ProgressLines _progressLines() {
    return _ProgressLines(
      total: _progressByPeriod(
        widget.books,
        widget.period,
        'Total',
        EColors.success,
      ),
      audiobook: _progressByPeriod(
        widget.books.whereL((book) => book.isAudiobook),
        widget.period,
        'Audio',
        BookFormat.audiobook.color,
      ),
      visual: _progressByPeriod(
        widget.books.whereL((book) => !book.isAudiobook),
        widget.period,
        'Visual',
        BookFormat.paperback.color,
      ),
    );
  }

  static ProgressLine _progressByPeriod(
    List<LibraryBook> books,
    StatsPeriod period,
    String name,
    Color color,
  ) {
    final agg = period.chartAggregation;
    final periodCutoff = period.cutoffDate;
    final byBucket = <DateTime, double>{};

    for (final book in books) {
      for (final diff in book.progressDiffs) {
        if (periodCutoff != null && diff.key.isBefore(periodCutoff)) continue;
        if (diff.value <= 0) continue;
        final bucketDate = _bucketStart(diff.key, agg);
        byBucket[bucketDate] = (byBucket[bucketDate] ?? 0) + diff.value;
      }
    }

    if (agg != ProgressAggregation.monthly && periodCutoff != null) {
      var bucket = _bucketStart(periodCutoff, agg);
      final todayBucket = _bucketStart(DateTime.now(), agg);
      while (!bucket.isAfter(todayBucket)) {
        byBucket.putIfAbsent(bucket, () => 0);
        bucket = _advanceBucket(bucket, agg);
      }
    }

    final sortedPoints =
        (byBucket.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            .map((entry) => ProgressDataPoint(entry.key, entry.value))
            .toList();
    return ProgressLine(data: sortedPoints, name: name, color: color);
  }

  static DateTime _bucketStart(DateTime date, ProgressAggregation agg) =>
      switch (agg) {
        ProgressAggregation.daily => date.startOfDay,
        ProgressAggregation.weekly => date.shiftedByDays(-(date.weekday - 1)),
        ProgressAggregation.monthly => DateTime(date.year, date.month),
      };

  static DateTime _advanceBucket(DateTime date, ProgressAggregation agg) =>
      switch (agg) {
        ProgressAggregation.daily => date.shiftedByDays(1),
        ProgressAggregation.weekly => date.shiftedByDays(7),
        ProgressAggregation.monthly => DateTime(date.year, date.month + 1),
      };

  @override
  Widget build(BuildContext context) {
    final progressLines = _progressLines();
    if (progressLines.total.data.isEmpty) {
      return const Center(child: Text('No reading data in this period'));
    }
    return Column(
      children: [
        _legendRow(progressLines),
        if (_selectedBucket != null)
          _periodTotals(progressLines, _selectedBucket!),
        Expanded(child: _progressByPeriodLines(progressLines)),
      ],
    );
  }

  Widget _progressByPeriodLines(_ProgressLines progressLines) {
    final pointTimes = progressLines.lines
        .expand((line) => line.data)
        .mapL((point) => point.date);
    final timespan = TimeSpan(beginning: pointTimes.min, end: pointTimes.max);
    final maxProgress = progressLines.lines
        .expand((line) => line.data)
        .mapL((point) => point.progress)
        .max;
    final chartSeries = [
      for (final line in progressLines.lines)
        EChartSeries.line(
          id: line.name,
          points: [
            for (final point in line.data)
              EChartPoint(
                date: point.date,
                value: _extrapolatedProgress(point),
                id: point.date,
              ),
          ],
          color: line.color.withValues(alpha: 0.7),
          fillColor: line == progressLines.total
              ? EColors.success.withValues(alpha: 0.12)
              : null,
          label: line.name,
        ),
    ];
    return EChart<DateTime>(
      series: chartSeries,
      valueScale: EChartValueScale.nice(maxProgress, tickSuffix: '%'),
      start: timespan.beginning,
      end: timespan.end,
      onPointSelected: (selected) {
        setState(() => _selectedBucket = selected?.pointId);
      },
    );
  }

  double _extrapolatedProgress(ProgressDataPoint point) {
    final agg = widget.period.chartAggregation;
    final now = DateTime.now();
    final currentBucket = _bucketStart(now, agg);
    if (point.date != currentBucket) return point.progress;
    return switch (agg) {
      ProgressAggregation.monthly =>
        point.progress / now.day * _monthLength(now.month, now.year),
      ProgressAggregation.weekly => point.progress / now.weekday * 7,
      ProgressAggregation.daily => point.progress,
    };
  }

  Widget _periodTotals(_ProgressLines progressLines, DateTime bucket) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        '${_tooltipDateString(bucket)} · ${progressLines.lines.map((line) {
          final match = line.data.where((point) => point.date == bucket);
          final progress = match.isEmpty ? 0.0 : match.first.progress;
          return '${line.name} ${progress.round()}%';
        }).join(' · ')}',
        style: AppTextStyles.caption,
      ),
    );
  }

  String _tooltipDateString(DateTime date) {
    return switch (widget.period.chartAggregation) {
      ProgressAggregation.monthly => DateFormat('MMM yyyy').format(date),
      ProgressAggregation.weekly =>
        'Week of ${DateFormat('MMM d').format(date)}',
      ProgressAggregation.daily => DateFormat('MMM d, yyyy').format(date),
    };
  }

  Widget _legendRow(_ProgressLines progressLines) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: progressLines.lines.mapL(
          (line) => Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: _legendItem(line.color, line.name),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  static num _monthLength(int month, int year) => month == 2
      ? year % 4 == 0
            ? 29
            : 28
      : {9, 4, 6, 11}.contains(month)
      ? 30
      : 31;
}

class _ProgressLines({
  required final ProgressLine total,
  required final ProgressLine audiobook,
  required final ProgressLine visual,
}) {
  List<ProgressLine> get lines => [total, audiobook, visual];
}

class const ProgressLine({
  required final List<ProgressDataPoint> data,
  required final String name,
  required final Color color,
});

class const ProgressDataPoint(final DateTime date, final double progress);
