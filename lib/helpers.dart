import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'extensions.dart';

class FlutterHelpers {
  static Widget transform({
    Offset? shift,
    double? angleDegrees,
    required Widget child,
  }) {
    Widget ret = child;
    if (shift != null) {
      ret = Transform.translate(offset: shift, child: ret);
    }
    if (angleDegrees != null) {
      ret = Transform.rotate(angle: angleDegrees.deg2rad, child: ret);
    }
    return ret;
  }

  static OutlinedBorder roundedRect({required double radius}) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}

class TimeHelpers {
  static final monthDayYear = DateFormat('MMM d, y').format;
  static final hourMinuteAmPm = DateFormat('h:mma').format;

  static String get timeLog => timeLogFormatter(DateTime.now());

  static String timeLogFormatter(DateTime dateTime) {
    final time = DateFormat('hh:mm:ss').format(dateTime);
    final millis = dateTime.millisecond.toString().padLeft(3, '0');
    return '$time:$millis';
  }
}
