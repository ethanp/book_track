import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:book_track/ui/pages/stats/reading_activity_data.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const ActivityCalendarCard({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatefulWidget {
  @override
  State<ActivityCalendarCard> createState() => _ActivityCalendarCardState();
}

class _ActivityCalendarCardState() extends State<ActivityCalendarCard> {
  bool _showCharts = false;

  @override
  Widget build(BuildContext context) {
    return _card(
      ReadingActivityData.fromProgress(
        widget.books,
        periodCutoff: widget.periodCutoff,
      ),
    );
  }

  Widget _card(ReadingActivityData data) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _titleRow(),
          if (_showCharts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ECalendarCharts(
                dailyMeasures: LibraryProgressCalendar.allTimeDailyMeasures(
                  activityByDay: data.activityByDay,
                  today: DateTime.now().startOfDay,
                  periodCutoff: widget.periodCutoff,
                ),
                measureTitle: 'library-progress points',
                formatMeasure: (quantity) => '${quantity.round()}pp',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CalendarHeatmap(
                activityByDay: data.activityByDay,
                books: widget.books,
                periodCutoff: widget.periodCutoff,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: EHeatmapLegend(
              scale: LibraryProgressCalendar.scaleFor(data.activityByDay.values),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _titleRow() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: Text('Reading Activity', style: AppTextStyles.h3)),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Grid')),
              ButtonSegment(value: true, label: Text('Charts')),
            ],
            selected: {_showCharts},
            onSelectionChanged: (selected) {
              setState(() => _showCharts = selected.single);
            },
          ),
        ],
      ),
    );
  }
}
