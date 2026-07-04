import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:book_track/ui/pages/stats/reading_activity_data.dart';
import 'package:flutter/cupertino.dart';

class ActivityCalendarCard extends StatelessWidget {
  const ActivityCalendarCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    return AsyncStatsCard<ReadingActivityData>(
      cacheKey: '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}',
      compute: () => ReadingActivityData.fromProgress(
        books,
        periodCutoff: periodCutoff,
      ),
      loadingHeight: 200,
      builder: _buildCard,
    );
  }

  Widget _buildCard(ReadingActivityData data) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _title(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: CalendarHeatmap(
              activityByDay: data.activityByDay,
              books: books,
              periodCutoff: periodCutoff,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _legend(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _title() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.md,
          left: AppSpacing.lg,
        ),
        child: Text('Reading Activity', style: AppTextStyles.h3),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Less ', style: AppTextStyles.caption),
        ...CalendarHeatmap.colors.map(
          (color) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(' More', style: AppTextStyles.caption),
      ],
    );
  }
}
