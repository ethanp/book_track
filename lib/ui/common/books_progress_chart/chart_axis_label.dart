import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/widgets.dart';

abstract final class ChartAxisLabel() {
  static Widget nudgedIntoPlot(Widget child, {required Offset shift}) =>
      Transform.translate(offset: shift, child: child);

  static Widget tiltedToClearNeighbors(
    Widget child, {
    required Offset shift,
    required double angleDegrees,
  }) => Transform.translate(
    offset: shift,
    child: Transform.rotate(angle: angleDegrees.deg2rad, child: child),
  );
}
