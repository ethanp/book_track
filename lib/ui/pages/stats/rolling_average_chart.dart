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
              reservedSize: 30,
              interval: max(data.maxScore / 4, 1),
              getTitlesWidget: (value, meta) => Text(
                value.round().toString(),
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
              reservedSize: 22,
              interval: const Duration(days: 30).inMilliseconds.toDouble(),
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
                  CupertinoColors.systemGreen.withOpacity(0.3),
                  CupertinoColors.systemGreen.withOpacity(0.05),
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
      ),
    );
  }

  Widget _currentScore(_RollingAverageData data) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Current Momentum: ${data.currentScore.round()}',
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
    // Collect all reading volume deltas with their dates
    final volumeDeltas = <MapEntry<DateTime, double>>[];
    for (final book in books) {
      if (book.formats.isEmpty) continue;
      // Get page diffs (which handles format conversion correctly)
      final diffs = book.pagesDiffs();
      for (final diff in diffs) {
        if (periodCutoff == null || diff.key.isAfter(periodCutoff)) {
          volumeDeltas.add(diff);
        }
      }
    }

    if (volumeDeltas.isEmpty) {
      return const _RollingAverageData(
          scores: [], currentScore: 0, maxScore: 0);
    }

    // Find the earliest reading date
    final earliestDate =
        volumeDeltas.map((e) => e.key).reduce((a, b) => a.isBefore(b) ? a : b);

    final today = DateTime.now();

    // Start calculating from 30 days after the earliest date
    // (since we need a 30-day window for the rolling average)
    final startDate = earliestDate.add(const Duration(days: 30));

    // Apply period cutoff if provided
    final effectiveStart =
        periodCutoff != null && periodCutoff.isAfter(startDate)
            ? periodCutoff
            : startDate;

    final daysToShow = today.difference(effectiveStart).inDays;

    final scores = <FlSpot>[];
    double maxScore = 0;

    // Calculate rolling average for each day from start to today
    for (int i = 0; i <= daysToShow; i++) {
      final date = effectiveStart.add(Duration(days: i));
      final score = _calculateScore(date, volumeDeltas);
      scores.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), score));
      if (score > maxScore) maxScore = score;
    }

    return _RollingAverageData(
      scores: scores,
      currentScore: scores.isNotEmpty ? scores.last.y : 0,
      maxScore: maxScore > 0 ? maxScore : 1,
    );
  }

  /// Calculate rolling score using step function weight decay.
  /// Full weight for last 7 days, then gradual decay to 0.1 at 30 days.
  /// Score is based on actual reading volume (pages/minutes), not just event count.
  static double _calculateScore(
      DateTime date, List<MapEntry<DateTime, double>> volumeDeltas) {
    final windowStart = date.subtract(const Duration(days: 30));
    double score = 0;

    for (final delta in volumeDeltas) {
      if (delta.key.isBefore(windowStart)) continue;
      if (delta.key.isAfter(date)) continue;

      final daysAgo = date.difference(delta.key).inDays;
      final weight = _calculateWeight(daysAgo);

      // Add volume * weight to score
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

