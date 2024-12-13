import 'dart:io';

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
  void call(Object? s) => stdout.writeln(_msg(s));

  void error(Object? obj) => stderr.writeln(_red(_msg(obj)));

  String _msg(Object? s) => '${TimeHelpers.timestamp} $prefix: $s';

  static const String _redColor = '\x1B[31m';
  static const String _defaultColor = '\x1B[0m';

  String _red(String string) => '$_redColor$string$_defaultColor';
}
