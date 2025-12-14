import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterSection extends ConsumerWidget {
  const FilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedProvider);
    final selectedPeriod = ref.watch(statsPeriodProvider);

    return Column(
      children: [
        // Archive toggle row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Include archived books'),
              CupertinoSwitch(
                value: showArchived,
                onChanged: (value) {
                  ref.read(showArchivedProvider.notifier).state = value;
                },
              ),
            ],
          ),
        ),
        // Period selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CupertinoSlidingSegmentedControl<StatsPeriod>(
            groupValue: selectedPeriod,
            children: {
              for (final period in StatsPeriod.values)
                period: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Text(period.label, style: const TextStyle(fontSize: 13)),
                ),
            },
            onValueChanged: (value) {
              if (value != null) {
                ref.read(statsPeriodProvider.notifier).state = value;
              }
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
