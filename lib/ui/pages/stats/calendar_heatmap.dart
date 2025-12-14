import 'dart:math' show max;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';

class CalendarHeatmap extends StatefulWidget {
  const CalendarHeatmap({
    required this.activityByDay,
    this.weeksToShow = 26,
    this.periodCutoff,
    super.key,
  });

  final Map<DateTime, int> activityByDay;

  /// Number of weeks to display (default 26 = 6 months).
  final int weeksToShow;

  /// Only show dates after this cutoff (inclusive).
  final DateTime? periodCutoff;

  /// Color scale (5 levels like GitHub).
  static const colors = [
    Color(0xFFEBEDF0), // 0: no activity
    Color(0xFF9BE9A8), // 1: light
    Color(0xFF40C463), // 2: medium-light
    Color(0xFF30A14E), // 3: medium
    Color(0xFF216E39), // 4: dark (high activity)
  ];

  @override
  State<CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends State<CalendarHeatmap> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heatmapGrid(),
        if (selectedDate != null) _dayDetails(selectedDate!),
      ],
    );
  }

  Widget _heatmapGrid() {
    final today = DateUtils.dateOnly(DateTime.now());
    final months = _buildMonths(today);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayLabels(),
          ...months,
        ],
      ),
    );
  }

  Widget _dayLabels() {
    const days = ['', 'M', '', 'W', '', 'F', ''];
    return Column(
      children: days
          .map((d) => SizedBox(
                height: 12,
                width: 20,
                child: Text(d, style: const TextStyle(fontSize: 9)),
              ))
          .toList(),
    );
  }

  List<Widget> _buildMonths(DateTime today) {
    final months = <Widget>[];

    // Find the earliest date with actual activity data
    final earliestDataDate = widget.activityByDay.keys.isNotEmpty
        ? widget.activityByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b)
        : null;

    // Determine the start date based on:
    // 1. periodCutoff (if set) - takes precedence
    // 2. earliest data date (if exists), but cap at 2 years back max
    // 3. weeksToShow back from today (fallback if no data)
    final cutoffDate = widget.periodCutoff != null
        ? DateUtils.dateOnly(widget.periodCutoff!)
        : null;

    DateTime effectiveStartDate;
    if (cutoffDate != null) {
      effectiveStartDate = cutoffDate;
    } else if (earliestDataDate != null) {
      // Use the earliest data date, but cap at 2 years back to avoid showing decades of empty data
      final maxBackDate = today.subtract(const Duration(days: 365 * 2));
      effectiveStartDate = earliestDataDate.isAfter(maxBackDate)
          ? earliestDataDate
          : maxBackDate;
    } else {
      // No data at all, use weeksToShow as fallback
      effectiveStartDate =
          today.subtract(Duration(days: widget.weeksToShow * 7));
    }

    // Find the first day of the first month to show
    var currentMonthStart =
        DateTime(effectiveStartDate.year, effectiveStartDate.month, 1);
    final todayMonthStart = DateTime(today.year, today.month, 1);

    while (!currentMonthStart.isAfter(todayMonthStart)) {
      final monthWidget = _buildMonth(currentMonthStart, today, cutoffDate);
      if (monthWidget != null) {
        months.add(monthWidget);
      }

      // Move to next month
      if (currentMonthStart.month == 12) {
        currentMonthStart = DateTime(currentMonthStart.year + 1, 1, 1);
      } else {
        currentMonthStart =
            DateTime(currentMonthStart.year, currentMonthStart.month + 1, 1);
      }
    }

    return months;
  }

  Widget? _buildMonth(
      DateTime monthStart, DateTime today, DateTime? cutoffDate) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final firstDayOfMonth = DateTime(monthStart.year, monthStart.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    // Find the Sunday that starts the week containing the 1st
    var weekStart = firstDayOfMonth.subtract(Duration(days: firstWeekday % 7));

    // Build all weeks that contain days from this month
    final weekColumns = <Widget>[];
    var currentWeekStart = weekStart;

    while (currentWeekStart
        .isBefore(DateTime(monthStart.year, monthStart.month + 1, 1))) {
      final weekColumn = _buildWeekColumn(
          currentWeekStart, monthStart, daysInMonth, today, cutoffDate);
      if (weekColumn != null) {
        weekColumns.add(weekColumn);
      }
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));

      // Stop if we've passed today
      if (currentWeekStart.isAfter(today.add(const Duration(days: 6)))) {
        break;
      }
    }

    if (weekColumns.isEmpty) return null;

    // Month label row
    final monthLabel = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: List.generate(weekColumns.length, (index) {
          // Only show label on first week column of the month
          if (index == 0) {
            final monthName = DateFormat('MMM yy').format(monthStart);
            return SizedBox(
              width: 12, // Same width as week column
              child: Text(
                monthName,
                style: const TextStyle(
                    fontSize: 9, color: CupertinoColors.systemGrey),
                textAlign: TextAlign.left,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            );
          } else {
            return const SizedBox(width: 12);
          }
        }),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        monthLabel,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: weekColumns,
        ),
      ],
    );
  }

  Widget? _buildWeekColumn(
    DateTime weekStart,
    DateTime monthStart,
    int daysInMonth,
    DateTime today,
    DateTime? cutoffDate,
  ) {
    final weekDays = <Widget>[];

    bool hasAnyVisibleDays = false;

    for (int i = 0; i < 7; i++) {
      final date = DateUtils.dateOnly(weekStart.add(Duration(days: i)));

      // Check if this date is in the current month
      final isInMonth =
          date.year == monthStart.year && date.month == monthStart.month;

      // Filter by period cutoff
      final isBeforeCutoff = cutoffDate != null && date.isBefore(cutoffDate);
      final isAfterToday = date.isAfter(today);

      if (!isInMonth || isBeforeCutoff || isAfterToday) {
        // Empty cell for dates outside the month, before cutoff, or in the future
        weekDays.add(const SizedBox(width: 12, height: 12));
      } else {
        hasAnyVisibleDays = true;
        final activity = widget.activityByDay[date] ?? 0;
        weekDays.add(_dayCell(activity, date));
      }
    }

    // Don't show week column if all days are filtered out
    if (!hasAnyVisibleDays) {
      return null;
    }

    return Column(children: weekDays);
  }

  Widget _dayCell(int activity, DateTime date) {
    final colorIndex = _activityToColorIndex(activity);
    final isSelected =
        selectedDate != null && DateUtils.isSameDay(date, selectedDate);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedDate = null;
          } else {
            selectedDate = date;
          }
        });
      },
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: CalendarHeatmap.colors[colorIndex],
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: CupertinoColors.activeBlue, width: 1.5)
              : null,
        ),
      ),
    );
  }

  int _activityToColorIndex(int activity) {
    if (activity == 0) return 0;
    if (activity == 1) return 1;
    if (activity <= 3) return 2;
    if (activity <= 5) return 3;
    return 4;
  }

  Widget _dayDetails(DateTime date) {
    final activity = widget.activityByDay[date] ?? 0;
    final dateStr = DateFormat('MMM d, yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            activity == 1 ? '1 update' : '$activity updates',
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}

/// Data class for reading activity statistics.
class ReadingActivityData {
  const ReadingActivityData({
    required this.activityByDay,
    required this.currentStreak,
    required this.longestStreak,
  });

  final Map<DateTime, int> activityByDay;
  final int currentStreak;
  final int longestStreak;

  /// Calculate reading activity from a list of books.
  factory ReadingActivityData.fromEvents(
    List<DateTime> eventDates, {
    DateTime? periodCutoff,
  }) {
    // Group by date (normalize to midnight)
    final activityByDay = <DateTime, int>{};
    final cutoffDate =
        periodCutoff != null ? DateUtils.dateOnly(periodCutoff) : null;

    for (final eventDate in eventDates) {
      final date = DateUtils.dateOnly(eventDate);

      // Filter by period cutoff (compare normalized dates)
      if (cutoffDate != null && date.isBefore(cutoffDate)) continue;

      activityByDay[date] = (activityByDay[date] ?? 0) + 1;
    }

    // Calculate streaks
    final (current, longest) = _calculateStreaks(activityByDay.keys.toList());

    return ReadingActivityData(
      activityByDay: activityByDay,
      currentStreak: current,
      longestStreak: longest,
    );
  }

  static (int current, int longest) _calculateStreaks(
      List<DateTime> activeDays) {
    if (activeDays.isEmpty) return (0, 0);

    final sorted = activeDays.toList()..sort();
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    int longestStreak = 0;
    int runningStreak = 1;

    // Check if streak is active (today or yesterday has activity)
    final hasRecentActivity = DateUtils.isSameDay(sorted.last, today) ||
        DateUtils.isSameDay(sorted.last, yesterday);

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        runningStreak++;
      } else if (diff > 1) {
        longestStreak = max(longestStreak, runningStreak);
        runningStreak = 1;
      }
      // diff == 0 means same day, keep runningStreak as is
    }
    longestStreak = max(longestStreak, runningStreak);

    // Current streak only counts if it's ongoing
    if (hasRecentActivity) {
      currentStreak = runningStreak;
    }

    return (currentStreak, longestStreak);
  }
}
