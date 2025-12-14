import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// A reusable wrapper that loads stats card data asynchronously.
///
/// Shows a loading skeleton while computing, then displays the result.
/// Automatically recomputes when [cacheKey] changes.
class AsyncStatsCard<T> extends StatefulWidget {
  const AsyncStatsCard({
    required this.cacheKey,
    required this.compute,
    required this.builder,
    this.loadingHeight = 150,
    super.key,
  });

  /// Unique key for caching. Changes trigger recomputation.
  /// Example: '${books.length}-$periodCutoff-$showArchived'
  final String cacheKey;

  /// Function that computes the data. Runs in isolate if possible.
  final T Function() compute;

  /// Builder that creates the UI from computed data.
  final Widget Function(T data) builder;

  /// Height of the loading skeleton.
  final double loadingHeight;

  @override
  State<AsyncStatsCard<T>> createState() => _AsyncStatsCardState<T>();
}

class _AsyncStatsCardState<T> extends State<AsyncStatsCard<T>> {
  T? _cachedData;
  String? _cachedKey;
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _computeData();
  }

  @override
  void didUpdateWidget(AsyncStatsCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _computeData();
    }
  }

  Future<void> _computeData() async {
    if (_cachedKey == widget.cacheKey && _cachedData != null) {
      return; // Already computed
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Run computation in next microtask to allow UI to update first
      await Future.microtask(() {});

      // Compute the data (synchronously for now, could use compute() for heavy work)
      final data = widget.compute();

      if (mounted) {
        setState(() {
          _cachedData = data;
          _cachedKey = widget.cacheKey;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _errorWidget();
    }

    if (_isLoading || _cachedData == null) {
      return _loadingSkeleton();
    }

    return widget.builder(_cachedData as T);
  }

  Widget _loadingSkeleton() {
    return Container(
      height: widget.loadingHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      height: widget.loadingHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading data',
              style: TextStyle(
                color: CupertinoColors.systemRed.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
