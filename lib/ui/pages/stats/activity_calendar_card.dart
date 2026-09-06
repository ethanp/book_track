import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:book_track/ui/pages/stats/reading_activity_data.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const ActivityCalendarCard({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _card(
      ReadingActivityData.fromProgress(books, periodCutoff: periodCutoff),
    );
  }

  Widget _card(ReadingActivityData data) {
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
          _legend(data.maxDailyPercentDelta),
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

  Widget _legend(int maxDailyPercentDelta) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less ', style: AppTextStyles.caption),
        ...EHeatmapIntensity.values.map(
          (level) => EHeatmapLegendSwatch(
            level: level,
            caption: level.quantityUpperBoundCaption(maxDailyPercentDelta),
          ),
        ),
        Text(' More', style: AppTextStyles.caption),
      ],
    );
  }
}
