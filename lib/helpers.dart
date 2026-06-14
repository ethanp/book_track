import 'dart:async';

import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';


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
    ELogger? logger,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await this;
      } catch (error) {
        attempt++;

        if (!_isRetryableNetworkError(error) || attempt > maxRetries) {
          if (logger != null && attempt > maxRetries) {
            logger.error('Max retries ($maxRetries) reached: $error');
          }
          rethrow;
        }

        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
        );

        logger?.log(
          'Network error (attempt $attempt/$maxRetries), '
          'retrying in ${delay.inMilliseconds}ms: ${error.runtimeType}',
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
