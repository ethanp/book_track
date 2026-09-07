import 'dart:math' as math;

class const CenteredMovingAverage({
  required final int halfWindow,
  required final int passCount,
}) {
  List<double> smoothValues(List<double> values) {
    var smoothed = values;
    for (var pass = 0; pass < passCount; pass++) {
      smoothed = _oneCenteredPass(smoothed);
    }
    return smoothed;
  }

  List<double> _oneCenteredPass(List<double> values) => List.generate(
    values.length,
    (index) => _averageAcrossCenteredWindow(values, index),
  );

  double _averageAcrossCenteredWindow(List<double> values, int index) {
    final firstIndex = math.max(0, index - halfWindow);
    final lastIndex = math.min(values.length - 1, index + halfWindow);
    var total = 0.0;
    for (var neighbor = firstIndex; neighbor <= lastIndex; neighbor++) {
      total += values[neighbor];
    }
    return total / (lastIndex - firstIndex + 1);
  }
}
