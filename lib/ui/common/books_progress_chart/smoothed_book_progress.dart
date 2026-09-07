import 'dart:math' as math;

import 'package:ethan_utils/ethan_utils.dart';

class const BookProgressPoint({
  required final DateTime at,
  required final double percent,
});

class const SmoothedBookProgress({
  required final List<BookProgressPoint> points,
}) {
  static const _approachTowardLog = 0.6;

  factory fromLoggedPercents(List<BookProgressPoint> logged) {
    if (logged.length < 2) {
      return SmoothedBookProgress(points: logged);
    }
    return SmoothedBookProgress(points: _approachingDailyPoints(logged));
  }

  static List<BookProgressPoint> _approachingDailyPoints(
    List<BookProgressPoint> logged,
  ) {
    final ordered = logged.sortedOn((point) => point.at);
    final longTerm = _LongTermLogTrend.fromLogs(ordered);
    final firstDay = ordered.first.at.startOfDay;
    final dayCount = ordered.last.at.startOfDay.difference(firstDay).inDays;
    final approachingPercents = [
      for (var dayOffset = 0; dayOffset <= dayCount; dayOffset++)
        _approachingPercentOn(
          firstDay.shiftedByDays(dayOffset),
          ordered,
          longTerm,
        ),
    ];
    approachingPercents[0] = ordered.first.percent;
    final percents = _nondecreasingClamped(approachingPercents);
    return [
      for (var dayOffset = 0; dayOffset <= dayCount; dayOffset++)
        BookProgressPoint(
          at: firstDay.shiftedByDays(dayOffset),
          percent: percents[dayOffset],
        ),
    ];
  }

  static double _approachingPercentOn(
    DateTime day,
    List<BookProgressPoint> ordered,
    _LongTermLogTrend longTerm,
  ) {
    final longTermPercent = longTerm.percentAt(day);
    final loggedFill = _linearPercentAt(day, ordered);
    return longTermPercent +
        _approachTowardLog * (loggedFill - longTermPercent);
  }

  static List<double> _nondecreasingClamped(List<double> percents) {
    final raised = <double>[];
    var previous = 0.0;
    for (final percent in percents) {
      final next = math.max(previous, percent).clamp(0.0, 100.0).toDouble();
      raised.add(next);
      previous = next;
    }
    return raised;
  }

  static double _linearPercentAt(DateTime at, List<BookProgressPoint> ordered) {
    BookProgressPoint? before;
    BookProgressPoint? after;
    for (final point in ordered) {
      if (!point.at.isAfter(at)) before = point;
      if (after == null && point.at.isAfter(at)) after = point;
    }
    if (before == null) return ordered.first.percent;
    if (after == null) return ordered.last.percent;
    final spanMillis = after.at.difference(before.at).inMilliseconds;
    if (spanMillis <= 0) return after.percent;
    final along = at.difference(before.at).inMilliseconds / spanMillis;
    return before.percent + (after.percent - before.percent) * along;
  }
}

class const _LongTermLogTrend({
  required final DateTime firstDay,
  required final double percentAtFirstDay,
  required final double slopePerDay,
}) {
  factory fromLogs(List<BookProgressPoint> logs) {
    final firstDay = logs.first.at.startOfDay;
    final dayOffsets = [
      for (final log in logs)
        log.at.startOfDay.difference(firstDay).inDays.toDouble(),
    ];
    final percents = logs.mapL((log) => log.percent);
    final meanDayOffset = _mean(dayOffsets);
    final meanPercent = _mean(percents);
    var slopeNumerator = 0.0;
    var slopeDenominator = 0.0;
    for (var index = 0; index < logs.length; index++) {
      final dayOffsetFromMean = dayOffsets[index] - meanDayOffset;
      slopeNumerator += dayOffsetFromMean * (percents[index] - meanPercent);
      slopeDenominator += dayOffsetFromMean * dayOffsetFromMean;
    }
    final slopePerDay = slopeDenominator == 0
        ? 0.0
        : slopeNumerator / slopeDenominator;
    return _LongTermLogTrend(
      firstDay: firstDay,
      percentAtFirstDay: meanPercent - slopePerDay * meanDayOffset,
      slopePerDay: slopePerDay,
    );
  }

  double percentAt(DateTime at) =>
      percentAtFirstDay +
      slopePerDay * at.startOfDay.difference(firstDay).inDays;

  static double _mean(List<double> values) {
    var total = 0.0;
    for (final value in values) {
      total += value;
    }
    return total / values.length;
  }
}
