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
  static final monthNameAbbr = DateFormat('MMM').format;
  static final monthDayYear = DateFormat('MM/dd/yy').format;
  static final hourMinuteAmPm = DateFormat('h:mma').format;
  static final dateAndTime = DateFormat('MM/dd/yy h:mma').format;

  static String get timestamp => timestampFormatter(DateTime.now());

  static String timestampFormatter(DateTime dateTime) {
    final time = DateFormat('hha:mm:ss').format(dateTime);
    final millis = dateTime.millisecond.toString().padLeft(3, '0');
    return '$time.$millis';
  }
}

class SimpleLogger {
  const SimpleLogger({required this.prefix});

  final String prefix;

  /// [call] method is a special method in Dart that, when defined,
  /// allows instances of the class to be invoked like functions.
  void call(Object? s, {bool error = false}) =>
      error ? _error(s) : debugPrint(_msg(s));

  void error(Object? s) => call(s, error: true);

  // The emoji is a workaround, since ANSI color-codes are not working with the
  // iOS simulator, so I can't just print it in red :(
  void _error(Object? obj) => debugPrint(_msg('⛔ERROR⛔: $obj'));

  String _msg(Object? s) => '${TimeHelpers.timestamp} $prefix: $s';
}
