import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const AppCard({
  required final Widget child,
  final EdgeInsetsGeometry? margin,
  final EdgeInsetsGeometry? padding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      child: ESurface(kind: ESurfaceKind.panel, padding: padding, child: child),
    );
  }
}
