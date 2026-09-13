import 'package:book_track/ui/pages/stats/activity_calendar_card.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('percentage-point captions are the period quartile cutoffs', () {
    final scale = LibraryProgressCalendar.scaleFor(const [
      5,
      10,
      15,
      20,
      25,
      30,
      35,
      40,
    ]);
    expect(scale.captionFor(EHeatmapIntensity.none), '≤0pp');
    expect(scale.captionFor(EHeatmapIntensity.low), '≤10pp');
    expect(scale.captionFor(EHeatmapIntensity.mid), '≤20pp');
    expect(scale.captionFor(EHeatmapIntensity.high), '≤30pp');
    expect(scale.captionFor(EHeatmapIntensity.peak), '≤40pp');
    expect(scale.levelFor(5), EHeatmapIntensity.low);
    expect(scale.levelFor(40), EHeatmapIntensity.peak);
    expect(
      scale.legendTitle,
      'Daily library-progress change · period quartiles',
    );
  });

  test('period cutoff is the first visible date', () {
    final first = LibraryProgressCalendar.firstVisibleDate(
      activityByDay: {DateTime(2018, 1, 1): 4},
      today: DateTime(2026, 9, 12),
      weeksToShow: 26,
      periodCutoff: DateTime(2026, 1, 1),
    );
    expect(first, DateTime(2026, 1, 1));
  });

  test('all-time chart measures start at the earliest activity day', () {
    final measures = LibraryProgressCalendar.allTimeDailyMeasures(
      activityByDay: {DateTime(2018, 1, 1): 4, DateTime(2026, 9, 8): 12},
      today: DateTime(2026, 9, 12),
    );
    expect(measures.first.date, DateTime(2018, 1, 1));
    expect(measures.last.date, DateTime(2026, 9, 12));
    expect(measures.first.quantity, 4);
  });

  test('daily measures fill from the period cutoff through today', () {
    final measures = LibraryProgressCalendar.dailyMeasures(
      activityByDay: {DateTime(2026, 9, 8): 12},
      today: DateTime(2026, 9, 12),
      weeksToShow: 26,
      periodCutoff: DateTime(2026, 9, 8),
    );
    expect(measures.length, 5);
    expect(measures.first.date, DateTime(2026, 9, 8));
    expect(measures.first.quantity, 12);
    expect(measures.first.isActive, isTrue);
    expect(measures.last.date, DateTime(2026, 9, 12));
    expect(measures.last.quantity, 0);
    expect(measures.last.isActive, isFalse);
  });

  testWidgets('Grid | Charts replaces the heatmap with the calendar trio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ETheme.material3Dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActivityCalendarCard(
              books: const [],
              periodCutoff: DateTime(2026, 9, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalendarHeatmap), findsOneWidget);

    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarHeatmap), findsNothing);
    expect(find.byType(ECalendarCharts), findsOneWidget);
    expect(find.text('library-progress points per week'), findsOneWidget);
    expect(find.text('Trailing 7-day library-progress points'), findsOneWidget);
  });

  testWidgets('selected day shows progress details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ETheme.material3Dark,
        home: Scaffold(
          body: CalendarHeatmap(
            activityByDay: {DateTime(2026, 9, 8): 12},
            books: const [],
            periodCutoff: DateTime(2026, 9, 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('e-contrib-day-2026-9-8')));
    await tester.pump();
    expect(find.text('Sep 8, 2026'), findsOneWidget);
    expect(find.text('No reading activity'), findsOneWidget);
  });
}
