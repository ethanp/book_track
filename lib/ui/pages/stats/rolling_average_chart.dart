import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/books_progress_chart/chart_axis_label.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/smoothed_reading_pace.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class const RollingAverageChart({
  required final List<LibraryBook> books,
  final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final smoothedPace = SmoothedReadingPace.fromProgressDeltas(
      books
          .where((book) => book.formats.isNotEmpty)
          .expand((book) => book.progressDiffs),
      periodCutoff: periodCutoff,
    );

    if (smoothedPace.points.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        _currentPace(smoothedPace),
        Expanded(child: _paceTrend(smoothedPace)),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 40, color: AppColors.shimmer),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start reading to see your pace!',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _paceTrend(SmoothedReadingPace smoothedPace) {
    final spots = smoothedPace.points
        .map(
          (point) => FlSpot(
            point.day.millisecondsSinceEpoch.toDouble(),
            point.percentPerDay,
          ),
        )
        .toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final spanDays = (maxX - minX) / const Duration(days: 1).inMilliseconds;
    final axisInterval = spanDays <= 14
        ? const Duration(days: 2).inMilliseconds.toDouble()
        : spanDays <= 60
        ? const Duration(days: 7).inMilliseconds.toDouble()
        : const Duration(days: 30).inMilliseconds.toDouble();
    final yInterval = _percentTickOnSimpleNumbers(smoothedPace.maxPace);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: smoothedPace.maxPace * 1.1,
        minX: minX,
        maxX: maxX,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameSize: 20,
            axisNameWidget: ChartAxisLabel.nudgedIntoPlot(
              Text('% / day', style: AppTextStyles.yAxisName),
              shift: const Offset(20, -10),
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
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              minIncluded: false,
              reservedSize: 28,
              interval: axisInterval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return ChartAxisLabel.tiltedToClearNeighbors(
                  _monthTickLabelingJanuaryWithYear(date),
                  shift: const Offset(2, 2),
                  angleDegrees: 40,
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
                '$dateStr\n${_paceKeepingTenthsBelowTen(spot.y)}/day',
                const TextStyle(
                  color: Colors.white,
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

  Widget _monthTickLabelingJanuaryWithYear(DateTime date) {
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

  Widget _currentPace(SmoothedReadingPace smoothedPace) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Reading pace: ${_paceKeepingTenthsBelowTen(smoothedPace.currentPace)}/day',
        style: AppTextStyles.h5,
      ),
    );
  }
}

String _paceKeepingTenthsBelowTen(double value) =>
    value >= 10 ? '${value.round()}%' : '${value.toStringAsFixed(1)}%';

double _percentTickOnSimpleNumbers(double maxValue) {
  const steps = [1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0];
  final target = maxValue / 5;
  return steps.firstWhere((step) => step >= target, orElse: () => steps.last);
}
