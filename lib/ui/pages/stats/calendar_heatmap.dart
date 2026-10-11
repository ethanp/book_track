import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/day_progress_entry.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'library_progress_calendar.dart';

class const CalendarHeatmap({
  required final Map<DateTime, int> activityByDay,
  required final List<LibraryBook> books,
  final int weeksToShow = 26,
  final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().startOfDay;
    final scale = LibraryProgressCalendar.scaleFor(activityByDay.values);
    return EContributionCalendar<DateTime>(
      firstVisibleDate: LibraryProgressCalendar.firstVisibleDate(
        activityByDay: activityByDay,
        today: today,
        weeksToShow: weeksToShow,
        periodCutoff: periodCutoff,
      ),
      lastVisibleDate: today,
      presentationFor: (date) => LibraryProgressCalendar.day(
        date: date,
        percentPoints: activityByDay[date.startOfDay] ?? 0,
        scale: scale,
      ),
      selectedDayBuilder: (context, day) =>
          _SelectedLibraryProgressDay(date: day.date, books: books),
    );
  }
}

class const _SelectedLibraryProgressDay({
  required final DateTime date,
  required final List<LibraryBook> books,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = DayProgressEntry.tilesForDate(date, books, context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMM d, yyyy').format(date), style: AppTextStyles.h5),
          const SizedBox(height: AppSpacing.sm),
          if (tiles.isEmpty)
            Text('No reading activity', style: AppTextStyles.bodySecondary)
          else
            ...tiles,
        ],
      ),
    );
  }
}
