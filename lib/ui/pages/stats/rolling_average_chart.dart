import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/reading_pace.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class RollingAverageChart extends StatelessWidget {
  const RollingAverageChart({
    required this.books,
    this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    final series = ReadingPaceSeries.fromProgressDeltas(
      books
          .where((book) => book.formats.isNotEmpty)
          .expand((book) => book.progressDiffs),
      periodCutoff: periodCutoff,
    );

    if (series.points.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        _currentPace(series),
        Expanded(child: _lineChart(series)),
      ],
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.graph_square,
              size: 40, color: AppColors.shimmer),
          SizedBox(height: AppSpacing.sm),
          Text('Start reading to see your pace!',
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }

  Widget _lineChart(ReadingPaceSeries series) {
    final spots = series.points
        .map((point) => FlSpot(
              point.day.millisecondsSinceEpoch.toDouble(),
              point.percentPerDay,
            ))
        .toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final spanDays = (maxX - minX) / const Duration(days: 1).inMilliseconds;
    final axisInterval = spanDays <= 14
        ? const Duration(days: 2).inMilliseconds.toDouble()
        : spanDays <= 60
            ? const Duration(days: 7).inMilliseconds.toDouble()
            : const Duration(days: 30).inMilliseconds.toDouble();
    final yInterval = _niceAxisInterval(series.maxPace);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: series.maxPace * 1.1,
        minX: minX,
        maxX: maxX,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameSize: 20,
            axisNameWidget: FlutterHelpers.transform(
              shift: const Offset(20, -10),
              child: Text('% / day', style: AppTextStyles.yAxisName),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              maxIncluded: false,
              reservedSize: 26,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Text(
                  '${value.round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              minIncluded: false,
              reservedSize: 28,
              interval: axisInterval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return FlutterHelpers.transform(
                  shift: const Offset(2, 2),
                  angleDegrees: 40,
                  child: _dateLabel(date),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.teal,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.3),
                  AppColors.teal.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: AppColors.textSecondary, width: 1.5),
            bottom: BorderSide(color: AppColors.textSecondary, width: 1.5),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final dateStr = DateFormat('MMM d, yyyy').format(date);
              return LineTooltipItem(
                '$dateStr\n${_formatDailyPercent(spot.y)}/day',
                const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Angled axis label; January carries a two-digit year suffix (e.g.
  /// "Jan 26") to mark the year boundary, matching the monthly chart.
  Widget _dateLabel(DateTime date) {
    final format = date.month == 1 ? 'MMM yy' : 'MMM';
    return Text(
      DateFormat(format).format(date),
      style: const TextStyle(
        letterSpacing: -.4,
        fontSize: 9,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _currentPace(ReadingPaceSeries series) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Reading pace: ${_formatDailyPercent(series.currentPace)}/day',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Formats a percent-per-day value. Small paces keep one decimal so a
/// "2.4%/day" reader isn't flattened to "2%/day".
String _formatDailyPercent(double value) =>
    value >= 10 ? '${value.round()}%' : '${value.toStringAsFixed(1)}%';

/// Rounds an axis step up to a friendly value (…, 2, 5, 10, 20, 25, …) so the
/// y-axis lands on simple numbers like "5%" rather than "6.1%".
double _niceAxisInterval(double maxValue) {
  const steps = [1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0];
  final target = maxValue / 5;
  return steps.firstWhere((step) => step >= target, orElse: () => steps.last);
}
