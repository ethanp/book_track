import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
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
    final data =
        _RollingAverageData.fromBooks(books, periodCutoff: periodCutoff);

    if (data.scores.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        Expanded(child: _lineChart(data)),
        _currentScore(data),
      ],
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.graph_square,
              size: 40, color: CupertinoColors.systemGrey3),
          SizedBox(height: 8),
          Text('Start reading to build momentum!',
              style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _lineChart(_RollingAverageData data) {
    final minX = data.scores.first.x;
    final maxX = data.scores.last.x;
    final spanDays = (maxX - minX) / const Duration(days: 1).inMilliseconds;
    final axisInterval = spanDays <= 14
        ? const Duration(days: 2).inMilliseconds.toDouble()
        : spanDays <= 60
            ? const Duration(days: 7).inMilliseconds.toDouble()
            : const Duration(days: 30).inMilliseconds.toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: data.maxScore * 1.1,
        minX: minX,
        maxX: maxX,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: max(data.maxScore / 4, 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              maxIncluded: false,
              reservedSize: 36,
              interval: max(data.maxScore / 4, 1),
              getTitlesWidget: (value, meta) => Text(
                '${value.round()}%',
                style: const TextStyle(fontSize: 10),
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
              reservedSize: 22,
              interval: axisInterval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('MMM').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.scores,
            isCurved: true,
            curveSmoothness: 0.2,
            color: CupertinoColors.systemGreen,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemGreen.withValues(alpha: 0.3),
                  CupertinoColors.systemGreen.withValues(alpha: 0.05),
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
            left: BorderSide(color: CupertinoColors.black, width: 2),
            bottom: BorderSide(color: CupertinoColors.black, width: 2),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final dateStr = DateFormat('MMM d, yyyy').format(date);
              return LineTooltipItem(
                '$dateStr\n${spot.y.round()}%',
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

  Widget _currentScore(_RollingAverageData data) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Current Momentum: ${data.currentScore.round()}%',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RollingAverageData {
  const _RollingAverageData({
    required this.scores,
    required this.currentScore,
    required this.maxScore,
  });

  final List<FlSpot> scores;
  final double currentScore;
  final double maxScore;

  factory _RollingAverageData.fromBooks(
    List<LibraryBook> books, {
    DateTime? periodCutoff,
  }) {
    // Collect all progress deltas across full history for accurate window computation
    final progressDeltas = <MapEntry<DateTime, double>>[];
    for (final book in books) {
      if (book.formats.isEmpty) continue;
      for (final diff in book.progressDiffs) {
        if (diff.value > 0) progressDeltas.add(diff);
      }
    }

    if (progressDeltas.isEmpty) {
      return const _RollingAverageData(
          scores: [], currentScore: 0, maxScore: 0);
    }

    final earliestDate = progressDeltas
        .map((e) => e.key)
        .minBy<num>((d) => d.millisecondsSinceEpoch);

    final today = DateTime.now();
    final startDate = earliestDate.shiftedByDays(30);
    final daysToShow = today.difference(startDate).inDays;

    final allScores = <FlSpot>[];
    for (var dayOffset = 0; dayOffset <= daysToShow; dayOffset++) {
      final date = startDate.shiftedByDays(dayOffset);
      final score = _calculateScore(date, progressDeltas);
      allScores.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), score));
    }

    // Clip to the visible window defined by periodCutoff
    final displayedScores = periodCutoff == null
        ? allScores
        : allScores
            .where((spot) =>
                spot.x >= periodCutoff.millisecondsSinceEpoch.toDouble())
            .toList();

    if (displayedScores.isEmpty) {
      return const _RollingAverageData(
          scores: [], currentScore: 0, maxScore: 0);
    }

    final maxScore =
        displayedScores.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _RollingAverageData(
      scores: displayedScores,
      currentScore: displayedScores.last.y,
      maxScore: maxScore > 0 ? maxScore : 1,
    );
  }

  /// Calculate rolling score using step function weight decay.
  /// Full weight for last 7 days, then gradual decay to 0.1 at 30 days.
  /// Score is based on progress percentage, not page count.
  static double _calculateScore(
      DateTime date, List<MapEntry<DateTime, double>> progressDeltas) {
    final windowStart = date.shiftedByDays(-30);
    double score = 0;

    for (final delta in progressDeltas) {
      if (delta.key.isBefore(windowStart)) continue;
      if (delta.key.isAfter(date)) continue;

      final daysAgo = date.difference(delta.key).inDays;
      final weight = _calculateWeight(daysAgo);

      // Add progress * weight to score
      score += delta.value * weight;
    }

    return score;
  }

  /// Step function: full weight for 7 days, then decay.
  static double _calculateWeight(int daysAgo) {
    if (daysAgo <= 7) {
      return 1.0; // Full weight for last 7 days
    } else {
      // Gradual decay from 1.0 to 0.1 over days 8-30
      return 1.0 - ((daysAgo - 7) / 23 * 0.9);
    }
  }
}
