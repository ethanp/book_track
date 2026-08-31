import 'package:ethan_utils/ethan_utils.dart';

extension NetworkRetry<T> on Future<T> {
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

        if (!_isTransientNetworkError(error) || attempt > maxRetries) {
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

bool _isTransientNetworkError(Object error) {
  final typeName = error.runtimeType.toString();
  if (typeName == 'SocketException' ||
      typeName == 'ClientException' ||
      typeName == 'TimeoutException' ||
      typeName == 'HttpException') {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('connection closed') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection timeout') ||
      message.contains('network is unreachable') ||
      message.contains('failed host lookup') ||
      message.contains('socket') ||
      message.contains('timed out');
}
