import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime _bucketStart(DateTime date, ProgressAggregation agg) => switch (agg) {
      ProgressAggregation.daily => date.startOfDay,
      ProgressAggregation.weekly => date.shiftedByDays(-(date.weekday - 1)),
      ProgressAggregation.monthly => DateTime(date.year, date.month),
    };

class ProgressPerMonthChart extends StatelessWidget {
  ProgressPerMonthChart({
    required this.books,
    required this.period,
    super.key,
  })  : totalByPeriod = _progressByPeriod(
          books,
          period,
          'Total',
          CupertinoColors.systemGreen,
        ),
        audiobookByPeriod = _progressByPeriod(
          books.whereL((b) => b.isAudiobook),
          period,
          'Audio',
          CupertinoColors.systemOrange,
        ),
        visualByPeriod = _progressByPeriod(
          books.whereL((b) => !b.isAudiobook),
          period,
          'Visual',
          CupertinoColors.systemBlue,
        );

  final List<LibraryBook> books;
  final StatsPeriod period;

  final ProgressLine totalByPeriod;
  final ProgressLine audiobookByPeriod;
  final ProgressLine visualByPeriod;

  List<ProgressLine> get lines =>
      [totalByPeriod, audiobookByPeriod, visualByPeriod];

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

    final sortedPoints = (byBucket.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((entry) => ProgressDataPoint(entry.key, entry.value))
        .toList();
    return ProgressLine(data: sortedPoints, name: name, color: color);
  }

  static DateTime _advanceBucket(DateTime date, ProgressAggregation agg) =>
      switch (agg) {
        ProgressAggregation.daily => date.shiftedByDays(1),
        ProgressAggregation.weekly => date.shiftedByDays(7),
        ProgressAggregation.monthly => DateTime(date.year, date.month + 1),
      };

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static const double horizontalInterval = 100;

  @override
  Widget build(BuildContext context) {
    if (totalByPeriod.data.isEmpty) {
      return const Center(child: Text('No reading data in this period'));
    }
    return Stack(children: [
      lineChart(),
      chartLegend(),
    ]);
  }

  Widget lineChart() {
    final timespan = () {
      final pointTimes =
          lines.expand((line) => line.data).mapL((point) => point.date);
      return TimeSpan(beginning: pointTimes.min, end: pointTimes.max);
    }();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: lines
            .expand((line) => line.data)
            .mapL((point) => point.progress)
            .max,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: FlGridData(
          horizontalInterval: horizontalInterval,
          drawVerticalLine: false,
        ),
        titlesData: _labelAxes(timespan),
        lineTouchData: _touchData,
        lineBarsData: lines.mapL(_buildLine),
        borderData: FlBorderData(
            show: true,
            border: () {
              const borderSide =
                  BorderSide(color: CupertinoColors.black, width: 2);
              return const Border(left: borderSide, bottom: borderSide);
            }()),
      ),
    );
  }

  LineChartBarData _buildLine(ProgressLine line) {
    final agg = period.chartAggregation;
    final now = DateTime.now();
    final currentBucket = _bucketStart(now, agg);

    return LineChartBarData(
      spots: line.data.mapL((point) {
        final isCurrentBucket = point.date == currentBucket;
        final progress = switch (agg) {
          ProgressAggregation.monthly when isCurrentBucket =>
            _scaleMonthEstimate(point.progress, now),
          ProgressAggregation.weekly when isCurrentBucket =>
            _scaleWeekEstimate(point.progress, now),
          _ => point.progress,
        };
        return FlSpot(point.dateAsMillis, progress);
      }),
      isCurved: agg != ProgressAggregation.daily,
      curveSmoothness: .05,
      belowBarData:
          line == totalByPeriod ? _gradientFill() : BarAreaData(show: false),
      color: line.color.withValues(alpha: 0.7),
      dotData: const FlDotData(show: false),
    );
  }

  LineTouchData get _touchData => LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) {
            if (spots.isEmpty) return [];
            final date =
                DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt());
            final dateStr = _tooltipDateString(date);
            return spots.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final spot = entry.value;
              final line = lines[spot.barIndex];
              final lineColor = line.color.lerpWith(CupertinoColors.white, 0.5);
              final prefix = isFirst ? '$dateStr\n' : '';
              return LineTooltipItem(
                prefix,
                const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${line.name}: ${spot.y.round()}%',
                    style: TextStyle(color: lineColor),
                  ),
                ],
              );
            }).toList();
          },
        ),
      );

  String _tooltipDateString(DateTime date) {
    return switch (period.chartAggregation) {
      ProgressAggregation.monthly => DateFormat('MMM yyyy').format(date),
      ProgressAggregation.weekly =>
        'Week of ${DateFormat('MMM d').format(date)}',
      ProgressAggregation.daily => DateFormat('MMM d, yyyy').format(date),
    };
  }

  Widget chartLegend() {
    return Positioned(
      top: 0,
      right: 0,
      child: Card(
        elevation: 2,
        color: Colors.yellow[100]!.withValues(alpha: .7),
        shadowColor: Colors.green[100]!.withValues(alpha: .5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.mapL((l) => _legendItem(l.color, l.name)),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              color: color,
              margin: const EdgeInsets.only(right: 6)),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  double _scaleMonthEstimate(double progress, DateTime now) =>
      progress / now.day * _monthLength(now.month, now.year);

  double _scaleWeekEstimate(double progress, DateTime now) =>
      progress / now.weekday * 7;

  FlTitlesData _labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: ProgressPerMonthChart.progressAxisTitles(
          shiftTitle: const Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: _PeriodAxis(timespan, period).titles(),
      topTitles: noAxisTitles,
    );
  }

  static BarAreaData _gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          CupertinoColors.systemGreen.withValues(alpha: 0.15),
          CupertinoColors.systemGreen.withValues(alpha: 0.04),
        ],
        stops: const [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles progressAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameSize: 20,
      axisNameWidget: Transform.translate(
        offset: shiftTitle,
        child: Text('Progress %', style: TextStyles.sideAxisLabel),
      ),
      sideTitles: SideTitles(
        interval: horizontalInterval,
        reservedSize: 26,
        showTitles: true,
        maxIncluded: false,
        getTitlesWidget: (double value, TitleMeta meta) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Text(
            '${value.floor()}',
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
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

class ProgressLine {
  const ProgressLine({
    required this.data,
    required this.name,
    required this.color,
  });

  final List<ProgressDataPoint> data;
  final String name;
  final Color color;
}

class ProgressDataPoint {
  const ProgressDataPoint(this.date, this.progress);

  /// Start of the aggregation bucket (day, week, or month).
  final DateTime date;

  final double progress;

  double get dateAsMillis => date.millisecondsSinceEpoch.toDouble();
}

class _PeriodAxis {
  const _PeriodAxis(this.timespan, this.period);

  final TimeSpan timespan;
  final StatsPeriod period;

  AxisTitles titles() {
    return AxisTitles(
      axisNameWidget: _axisName(),
      sideTitles: _textLabels(),
      axisNameSize: 24,
    );
  }

  Widget _axisName() {
    return FlutterHelpers.transform(
      shift: const Offset(20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              'Starting ${TimeHelpers.monthDayYear(timespan.beginning)}',
              style: TextStyles.sideAxisLabelThin,
            ),
          ),
        ],
      ),
    );
  }

  SideTitles _textLabels() {
    return SideTitles(
      showTitles: true,
      minIncluded: false,
      maxIncluded: true,
      reservedSize: 26,
      interval: _tickIntervalMillis,
      getTitlesWidget: (double value, TitleMeta meta) {
        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
        if (!_shouldRenderLabel(date)) return const SizedBox.shrink();
        return FlutterHelpers.transform(
          shift: const Offset(2, 2),
          angleDegrees: 40,
          child: _labelText(date),
        );
      },
    );
  }

  double get _tickIntervalMillis {
    const oneDayMillis = 86400000.0;
    return switch (period) {
      StatsPeriod.week => oneDayMillis,
      StatsPeriod.month => oneDayMillis * 7,
      StatsPeriod.quarter => oneDayMillis * 14,
      StatsPeriod.sixMonths => oneDayMillis * 28,
      StatsPeriod.year || StatsPeriod.allTime => oneDayMillis,
    };
  }

  bool _shouldRenderLabel(DateTime date) {
    // Monthly mode: fire every day, only render on the 1st.
    if (period == StatsPeriod.year || period == StatsPeriod.allTime) {
      return date.day == 1;
    }
    return true;
  }

  Widget _labelText(DateTime date) {
    final agg = period.chartAggregation;
    if (agg == ProgressAggregation.monthly) {
      if (date.month == 1) {
        return Text(
          DateFormat('MMM yy').format(date),
          style: const TextStyle(letterSpacing: -.4, fontSize: 10),
        );
      }
      return Text(
        DateFormat('MMM').format(date),
        style: const TextStyle(letterSpacing: -.4, fontSize: 10),
      );
    }
    return Text(
      DateFormat('MMM d').format(date),
      style: const TextStyle(letterSpacing: -.4, fontSize: 10),
    );
  }
}
