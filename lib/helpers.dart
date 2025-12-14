import 'dart:async';

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
  void call(Object? s, {bool error = false}) =>
      error ? _error(s) : debugPrint(_msg(s));

  void error(Object? s) => call(s, error: true);

  // The emoji is a workaround, since ANSI color-codes are not working with the
  // iOS simulator, so I can't just print it in red :(
  void _error(Object? obj) => debugPrint(_msg('⛔ERROR⛔: $obj'));

  String _msg(Object? s) => '${TimeHelpers.timestamp} $prefix: $s';
}

/// Extension for adding network retry capability to Futures.
extension NetworkRetry<T> on Future<T> {
  /// Retry this Future with exponential backoff on network errors.
  ///
  /// [maxRetries] defaults to 3, [initialDelay] defaults to 500ms.
  /// Only retries on transient network errors.
  Future<T> withNetworkRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    SimpleLogger? logger,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await this;
      } catch (e) {
        attempt++;

        if (!_isRetryableNetworkError(e) || attempt > maxRetries) {
          if (logger != null && attempt > maxRetries) {
            logger.error('Max retries ($maxRetries) reached: $e');
          }
          rethrow;
        }

        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
        );

        logger?.call(
          'Network error (attempt $attempt/$maxRetries), '
          'retrying in ${delay.inMilliseconds}ms: ${e.runtimeType}',
        );

        await Future.delayed(delay);
      }
    }
  }
}

/// Check if an error is a transient network issue worth retrying.
bool _isRetryableNetworkError(Object e) {
  // Check common network exception types
  final typeName = e.runtimeType.toString();
  if (typeName == 'SocketException' ||
      typeName == 'ClientException' ||
      typeName == 'TimeoutException' ||
      typeName == 'HttpException') {
    return true;
  }

  // Fallback: check error message for network-related keywords
  final msg = e.toString().toLowerCase();
  return msg.contains('connection closed') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('connection timeout') ||
      msg.contains('network is unreachable') ||
      msg.contains('failed host lookup') ||
      msg.contains('socket') ||
      msg.contains('timed out');
}
