import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const FilterSection() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StatsPeriod selectedPeriod = ref.watch(statsPeriodProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final period in StatsPeriod.values)
            EFilterChip(
              label: period.label,
              color: EColors.accentGlow,
              selected: period == selectedPeriod,
              onActivated: () {
                ref.read(statsPeriodProvider.notifier).state = period;
              },
            ),
        ],
      ),
    );
  }
}
