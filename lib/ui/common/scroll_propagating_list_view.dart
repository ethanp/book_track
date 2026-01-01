import 'package:flutter/material.dart';

/// A ListView that propagates overscroll to its parent scrollable.
/// When the user scrolls past the edges, the scroll gesture is forwarded
/// to the parent scroll view with momentum preserved.
class ScrollPropagatingListView extends StatefulWidget {
  const ScrollPropagatingListView({
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int)? separatorBuilder;

  @override
  State<ScrollPropagatingListView> createState() =>
      _ScrollPropagatingListViewState();
}

class _ScrollPropagatingListViewState extends State<ScrollPropagatingListView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        final parentPosition = Scrollable.maybeOf(context)?.position;
        if (parentPosition == null) return true;

        if (notification.velocity != 0) {
          final target = parentPosition.pixels - notification.velocity * 0.3;
          parentPosition.animateTo(
            target.clamp(
              parentPosition.minScrollExtent,
              parentPosition.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
          );
        } else {
          parentPosition.jumpTo(
            parentPosition.pixels + notification.overscroll,
          );
        }
        return true;
      },
      child: widget.separatorBuilder != null
          ? ListView.separated(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.itemCount,
              separatorBuilder: widget.separatorBuilder!,
              itemBuilder: widget.itemBuilder,
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.itemCount,
              itemBuilder: widget.itemBuilder,
            ),
    );
  }
}
