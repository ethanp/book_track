import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';

class const ChartCard({
  required final String title,
  required final Widget chart,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl,
                left: AppSpacing.lg,
              ),
              child: Text(title, style: AppTextStyles.h3),
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 18,
                right: 35,
                top: AppSpacing.sm,
                bottom: 14,
              ),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}
