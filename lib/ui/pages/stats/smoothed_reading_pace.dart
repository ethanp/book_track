import 'dart:math' as math;

import 'package:ethan_utils/ethan_utils.dart';

class const ReadingPacePoint({
  required final DateTime day,
  required final double percentPerDay,
});

class const SmoothedReadingPace({
  required final List<ReadingPacePoint> points,
  required final double currentPace,
  required final double maxPace,
}) {
  static const trailingWindowDays = 14;

  static const _smoothingHalfWindow = 14;

  static const _smoothingPasses = 5;

  static const empty = SmoothedReadingPace(
    points: [],
    currentPace: 0,
    maxPace: 0,
  );

  factory fromProgressDeltas(
    Iterable<MapEntry<DateTime, double>> progressDeltas, {
    DateTime? periodCutoff,
    DateTime? now,
  }) {
    final dailyPercentByDay = _positivePercentGainedByDay(progressDeltas);
    if (dailyPercentByDay.isEmpty) return empty;

    final earliestDay = dailyPercentByDay.keys.minBy<num>(
      (day) => day.millisecondsSinceEpoch,
    );
    final today = (now ?? DateTime.now()).startOfDay;
    final daysToShow = today.difference(earliestDay).inDays;

    final days = [
      for (var dayOffset = 0; dayOffset <= daysToShow; dayOffset++)
        earliestDay.shiftedByDays(dayOffset),
    ];
    final rawPace = [
      for (final day in days) _trailingAverage(day, dailyPercentByDay),
    ];
    final smoothedPace = _blurWithFiveCenteredPasses(rawPace);

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

    return SmoothedReadingPace(
      points: displayedPoints,
      currentPace: displayedPoints.last.percentPerDay,
      maxPace: maxPace > 0 ? maxPace : 1,
    );
  }

  static Map<DateTime, double> _positivePercentGainedByDay(
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

  static List<double> _blurWithFiveCenteredPasses(List<double> values) {
    var smoothed = values;
    for (var pass = 0; pass < _smoothingPasses; pass++) {
      smoothed = _centeredMovingAverage(smoothed);
    }
    return smoothed;
  }

  static List<double> _centeredMovingAverage(List<double> values) =>
      List.generate(
        values.length,
        (index) => _averageAcrossCenteredMonth(values, index),
      );

  static double _averageAcrossCenteredMonth(List<double> values, int index) {
    final firstIndex = math.max(0, index - _smoothingHalfWindow);
    final lastIndex = math.min(values.length - 1, index + _smoothingHalfWindow);
    var total = 0.0;
    for (var neighbor = firstIndex; neighbor <= lastIndex; neighbor++) {
      total += values[neighbor];
    }
    return total / (lastIndex - firstIndex + 1);
  }
}
