import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const FilterSection() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipRow(_periodChips(ref)),
          const SizedBox(height: AppSpacing.xs),
          _chipRow(_inclusionChips(ref)),
        ],
      ),
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }

  List<Widget> _periodChips(WidgetRef ref) {
    final StatsPeriod selectedPeriod = ref.watch(statsPeriodProvider);
    return [
      for (final period in StatsPeriod.values)
        EFilterChip(
          label: period.label,
          color: EColors.accentGlow,
          compact: true,
          selected: period == selectedPeriod,
          onActivated: () {
            ref.read(statsPeriodProvider.notifier).state = period;
          },
        ),
    ];
  }

  List<Widget> _inclusionChips(WidgetRef ref) {
    final bool includeAudiobooks = ref.watch(includeAudiobooksProvider);
    final bool includeAbandoned = ref.watch(includeAbandonedProvider);
    final bool includeReading = ref.watch(includeReadingProvider);
    final bool includeFinished = ref.watch(includeFinishedProvider);
    return [
      _inclusionChip(
        label: 'Audio',
        included: includeAudiobooks,
        excludedIcon: Icons.headset_off,
        onChanged: (included) {
          ref.read(includeAudiobooksProvider.notifier).state = included;
        },
      ),
      _inclusionChip(
        label: 'Abandoned',
        included: includeAbandoned,
        excludedIcon: Icons.block,
        onChanged: (included) {
          ref.read(includeAbandonedProvider.notifier).state = included;
        },
      ),
      _inclusionChip(
        label: 'Reading',
        included: includeReading,
        excludedIcon: Icons.auto_stories,
        onChanged: (included) {
          ref.read(includeReadingProvider.notifier).state = included;
        },
      ),
      _inclusionChip(
        label: 'Finished',
        included: includeFinished,
        excludedIcon: Icons.task_alt,
        onChanged: (included) {
          ref.read(includeFinishedProvider.notifier).state = included;
        },
      ),
    ];
  }

  Widget _inclusionChip({
    required String label,
    required bool included,
    required IconData excludedIcon,
    required ValueChanged<bool> onChanged,
  }) {
    return EFilterChip(
      label: label,
      icon: included ? Icons.check : excludedIcon,
      color: EColors.accentGlow,
      compact: true,
      selected: included,
      onActivated: () => onChanged(!included),
    );
  }
}
