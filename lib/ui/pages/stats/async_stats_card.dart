import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const AsyncStatsCard<T>({
  required final String cacheKey,
  required final T Function() compute,
  required final Widget Function(T data) builder,
  final double loadingHeight = 150,
}) extends StatefulWidget {
  @override
  State<AsyncStatsCard<T>> createState() => _AsyncStatsCardState<T>();
}

class _AsyncStatsCardState<T>() extends State<AsyncStatsCard<T>> {
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
    if (_cachedKey == widget.cacheKey && _cachedData != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.microtask(() {});
      final data = widget.compute();
      if (mounted) {
        setState(() {
          _cachedData = data;
          _cachedKey = widget.cacheKey;
          _isLoading = false;
        });
      }
    } catch (computeError) {
      if (mounted) {
        setState(() {
          _error = computeError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _errorWidget();
    if (_isLoading || _cachedData == null) return _loadingSkeleton();
    return widget.builder(_cachedData as T);
  }

  Widget _loadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: widget.loadingHeight,
        child: const ESurface(
          kind: ESurfaceKind.panel,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: widget.loadingHeight,
        child: ESurface(
          kind: ESurfaceKind.panel,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.destructive,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Error loading data',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
