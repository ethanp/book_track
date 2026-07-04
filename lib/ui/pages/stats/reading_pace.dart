import 'dart:math' as math;

import 'package:ethan_utils/ethan_utils.dart';

class ReadingPacePoint {
  const ReadingPacePoint({required this.day, required this.percentPerDay});

  final DateTime day;
  final double percentPerDay;
}

/// Smoothed reading pace: the trailing [trailingWindowDays]-day average of
/// daily percent-of-book read, then blurred into a readable trend line, with
/// one point per calendar day from the first reading day through today.
///
/// Two stages:
/// 1. Trailing average turns bursty per-event progress into a "percent per
///    day" rate; rest days count as zero, so the pace reflects consistency.
/// 2. A centered moving average, applied [_smoothingPasses] times, erases the
///    day-to-day ripples a boxcar window leaves when a reading day enters or
///    exits it — the same smoothing the workout load chart uses.
///
/// Callers pass raw per-event percent deltas (event day -> percent gained);
/// day-bucketing, averaging, smoothing, and period-clipping all happen here,
/// keeping this free of any UI, charting, or storage dependencies.
class ReadingPaceSeries {
  const ReadingPaceSeries({
    required this.points,
    required this.currentPace,
    required this.maxPace,
  });

  /// Trailing window whose average defines the raw daily pace before smoothing.
  static const trailingWindowDays = 7;

  /// Days on each side included in each smoothing pass — five plus the point
  /// itself is a centered 11-day window.
  static const _smoothingHalfWindow = 5;

  /// Repeated centered averaging approximates a Gaussian blur; more passes
  /// widen the blur and erase the bursty spikes left by big reading days.
  static const _smoothingPasses = 3;

  static const empty = ReadingPaceSeries(
    points: [],
    currentPace: 0,
    maxPace: 0,
  );

  final List<ReadingPacePoint> points;

  /// Smoothed pace for the most recent day, percent-of-book per day.
  final double currentPace;

  /// Largest pace among [points], floored at 1 so chart axes stay sane.
  final double maxPace;

  factory ReadingPaceSeries.fromProgressDeltas(
    Iterable<MapEntry<DateTime, double>> progressDeltas, {
    DateTime? periodCutoff,
    DateTime? now,
  }) {
    final dailyPercentByDay = _dailyPercentByDay(progressDeltas);
    if (dailyPercentByDay.isEmpty) return empty;

    final earliestDay = dailyPercentByDay.keys.minBy<num>(
      (day) => day.millisecondsSinceEpoch,
    );
    final today = (now ?? DateTime.now()).startOfDay;
    final daysToShow = today.difference(earliestDay).inDays;

    // Build and smooth across the full history so the trailing average and the
    // centered blur are both correct at the left edge of the shown window.
    final days = [
      for (var dayOffset = 0; dayOffset <= daysToShow; dayOffset++)
        earliestDay.shiftedByDays(dayOffset),
    ];
    final rawPace = [
      for (final day in days) _trailingAverage(day, dailyPercentByDay),
    ];
    final smoothedPace = _smoothed(rawPace);

    final allPoints = [
      for (var index = 0; index < days.length; index++)
        ReadingPacePoint(day: days[index], percentPerDay: smoothedPace[index]),
    ];

    final displayedPoints = periodCutoff == null
        ? allPoints
        : allPoints
              .where((point) => !point.day.isBefore(periodCutoff.startOfDay))
              .toList();

    if (displayedPoints.isEmpty) return empty;

    final maxPace = displayedPoints
        .map((point) => point.percentPerDay)
        .reduce((a, b) => a > b ? a : b);

    return ReadingPaceSeries(
      points: displayedPoints,
      currentPace: displayedPoints.last.percentPerDay,
      maxPace: maxPace > 0 ? maxPace : 1,
    );
  }

  /// Sums positive percent deltas per calendar day. Non-positive deltas (no
  /// progress, or a correction backwards) never lift the pace.
  static Map<DateTime, double> _dailyPercentByDay(
    Iterable<MapEntry<DateTime, double>> progressDeltas,
  ) {
    final dailyPercentByDay = <DateTime, double>{};
    for (final delta in progressDeltas) {
      if (delta.value <= 0) continue;
      final day = delta.key.startOfDay;
      dailyPercentByDay[day] = (dailyPercentByDay[day] ?? 0) + delta.value;
    }
    return dailyPercentByDay;
  }

  static double _trailingAverage(
    DateTime day,
    Map<DateTime, double> dailyPercentByDay,
  ) {
    var windowTotal = 0.0;
    for (var dayOffset = 0; dayOffset < trailingWindowDays; dayOffset++) {
      windowTotal += dailyPercentByDay[day.shiftedByDays(-dayOffset)] ?? 0;
    }
    return windowTotal / trailingWindowDays;
  }

  static List<double> _smoothed(List<double> values) {
    var smoothed = values;
    for (var pass = 0; pass < _smoothingPasses; pass++) {
      smoothed = _centeredMovingAverage(smoothed);
    }
    return smoothed;
  }

  static List<double> _centeredMovingAverage(List<double> values) =>
      List.generate(values.length, (index) => _windowAverage(values, index));

  static double _windowAverage(List<double> values, int index) {
    final firstIndex = math.max(0, index - _smoothingHalfWindow);
    final lastIndex = math.min(values.length - 1, index + _smoothingHalfWindow);
    var total = 0.0;
    for (var neighbor = firstIndex; neighbor <= lastIndex; neighbor++) {
      total += values[neighbor];
    }
    return total / (lastIndex - firstIndex + 1);
  }
}
