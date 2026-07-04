import 'package:book_track/ui/pages/stats/reading_pace.dart';
import 'package:flutter_test/flutter_test.dart';

/// A percent gained on a given day.
MapEntry<DateTime, double> read(DateTime day, double percent) =>
    MapEntry(day, percent);

DateTime day(int dayOfMonth) => DateTime(2026, 1, dayOfMonth);

/// [percentPerDay] read every day for [days] days, starting on day 1.
List<MapEntry<DateTime, double>> steadyReading({
  required double percentPerDay,
  required int days,
}) => [
  for (var offset = 0; offset < days; offset++)
    read(day(1 + offset), percentPerDay),
];

double paceOn(ReadingPaceSeries series, DateTime day) =>
    series.points.firstWhere((point) => point.day == day).percentPerDay;

void main() {
  group('ReadingPaceSeries', () {
    test('no reading yields an empty series', () {
      final series = ReadingPaceSeries.fromProgressDeltas([]);

      expect(series.points, isEmpty);
      expect(series.currentPace, 0);
    });

    test('non-positive deltas never lift the pace', () {
      final series = ReadingPaceSeries.fromProgressDeltas([
        read(day(1), 0),
        read(day(1), -5),
      ]);

      expect(series.points, isEmpty);
    });

    test('reading a steady rate reports that rate as the pace', () {
      final series = ReadingPaceSeries.fromProgressDeltas(
        steadyReading(percentPerDay: 5, days: 40),
        now: day(40),
      );

      expect(series.currentPace, closeTo(5, 1e-9));
    });

    test('same-day progress across books sums into the daily pace', () {
      final twoBooksAt2PercentEach = [
        for (var offset = 0; offset < 40; offset++) ...[
          read(day(1 + offset), 2),
          read(day(1 + offset), 2),
        ],
      ];

      final series = ReadingPaceSeries.fromProgressDeltas(
        twoBooksAt2PercentEach,
        now: day(40),
      );

      expect(series.currentPace, closeTo(4, 1e-9));
    });

    test('smoothing spreads a burst onto neighboring days', () {
      // A single big read on day 20. The raw trailing average on day 19 is 0
      // (nothing read in the prior week), so any positive pace there can only
      // come from the centered (forward-looking) smoothing.
      final series = ReadingPaceSeries.fromProgressDeltas(
        [read(day(1), 3), read(day(20), 50)],
        now: day(25),
      );

      expect(paceOn(series, day(19)), greaterThan(0));
    });

    test('period cutoff clips the display but history drives the edge', () {
      // The only read is on day 1, before the visible window — yet the pace at
      // the window's left edge still reflects it.
      final series = ReadingPaceSeries.fromProgressDeltas(
        [read(day(1), 40)],
        now: day(7),
        periodCutoff: day(5),
      );

      expect(series.points.first.day, day(5));
      expect(series.currentPace, greaterThan(0));
    });
  });
}
