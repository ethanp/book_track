import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.margin,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: const [AppShadows.card],
      ),
      child: child,
    );
  }
}
