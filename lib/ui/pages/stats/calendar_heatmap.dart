import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/day_progress_entry.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class LibraryProgressCalendar() {
  static EPeriodQuartileHeatmapScale scaleFor(
    Iterable<num> observedPercentPoints,
  ) => EPeriodQuartileHeatmapScale(
    observedQuantities: observedPercentPoints,
    legendTitle: 'Daily library-progress change · period quartiles',
    captionForQuantity: (quantity) => '≤${quantity.round()}pp',
  );

  static ECalendarDayPresentation<DateTime> day({
    required DateTime date,
    required int percentPoints,
    required EHeatmapScale scale,
  }) {
    final day = date.startOfDay;
    if (percentPoints <= 0) {
      return ECalendarDayPresentation(
        date: day,
        id: day,
        semanticsLabel: 'No library-progress change',
        visual: const ECalendarDayEmpty(),
      );
    }
    return ECalendarDayPresentation(
      date: day,
      id: day,
      semanticsLabel: '$percentPoints percentage points',
      visual: ECalendarDayMeasuredHeat(
        intensity: scale.intensityFor(percentPoints),
      ),
    );
  }

  static DateTime firstVisibleDate({
    required Map<DateTime, int> activityByDay,
    required DateTime today,
    required int weeksToShow,
    DateTime? periodCutoff,
  }) {
    final cutoffDate = periodCutoff?.startOfDay;
    if (cutoffDate != null) return cutoffDate;
    if (activityByDay.keys.isNotEmpty) {
      final earliest = activityByDay.keys.minBy<num>(
        (date) => date.millisecondsSinceEpoch,
      );
      final twoYearsBack = today.shiftedByDays(-365 * 2);
      return earliest.isAfter(twoYearsBack) ? earliest : twoYearsBack;
    }
    return today.shiftedByDays(-weeksToShow * 7);
  }

  static DateTime firstAllTimeDate({
    required Map<DateTime, int> activityByDay,
    required DateTime today,
    DateTime? periodCutoff,
  }) {
    final cutoffDate = periodCutoff?.startOfDay;
    if (cutoffDate != null) return cutoffDate;
    if (activityByDay.isEmpty) return today.startOfDay;
    return activityByDay.keys.min.startOfDay;
  }

  static List<ECalendarDailyMeasure> allTimeDailyMeasures({
    required Map<DateTime, int> activityByDay,
    required DateTime today,
    DateTime? periodCutoff,
  }) {
    return dailyMeasures(
      activityByDay: activityByDay,
      today: today,
      weeksToShow: 0,
      periodCutoff: firstAllTimeDate(
        activityByDay: activityByDay,
        today: today,
        periodCutoff: periodCutoff,
      ),
    );
  }

  static List<ECalendarDailyMeasure> dailyMeasures({
    required Map<DateTime, int> activityByDay,
    required DateTime today,
    required int weeksToShow,
    DateTime? periodCutoff,
  }) {
    final first = firstVisibleDate(
      activityByDay: activityByDay,
      today: today,
      weeksToShow: weeksToShow,
      periodCutoff: periodCutoff,
    ).startOfDay;
    final last = today.startOfDay;
    final days = <ECalendarDailyMeasure>[];
    for (var day = first; !day.isAfter(last); day = day.shiftedByDays(1)) {
      final quantity = activityByDay[day] ?? 0;
      days.add(
        ECalendarDailyMeasure(
          date: day,
          quantity: quantity,
          isActive: quantity > 0,
        ),
      );
    }
    return days;
  }
}

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
