import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

class AsyncStatsCard<T> extends StatefulWidget {
  const AsyncStatsCard({
    required this.cacheKey,
    required this.compute,
    required this.builder,
    this.loadingHeight = 150,
    super.key,
  });

  final String cacheKey;
  final T Function() compute;
  final Widget Function(T data) builder;
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
    return Container(
      height: widget.loadingHeight,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: const [AppShadows.card],
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _errorWidget() {
    return Container(
      height: widget.loadingHeight,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
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
    );
  }
}
