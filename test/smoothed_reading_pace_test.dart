import 'package:book_track/ui/pages/stats/smoothed_reading_pace.dart';
import 'package:flutter_test/flutter_test.dart';

MapEntry<DateTime, double> read(DateTime day, double percent) =>
    MapEntry(day, percent);

DateTime day(int dayOfMonth) => DateTime(2026, 1, dayOfMonth);

List<MapEntry<DateTime, double>> steadyReading({
  required double percentPerDay,
  required int days,
}) => [
  for (var offset = 0; offset < days; offset++)
    read(day(1 + offset), percentPerDay),
];

double paceOn(SmoothedReadingPace smoothedPace, DateTime day) =>
    smoothedPace.points.firstWhere((point) => point.day == day).percentPerDay;

void main() {
  group('SmoothedReadingPace', () {
    test('no reading yields an empty pace', () {
      final smoothedPace = SmoothedReadingPace.fromProgressDeltas([]);

      expect(smoothedPace.points, isEmpty);
      expect(smoothedPace.currentPace, 0);
    });

    test('non-positive deltas never lift the pace', () {
      final smoothedPace = SmoothedReadingPace.fromProgressDeltas([
        read(day(1), 0),
        read(day(1), -5),
      ]);

      expect(smoothedPace.points, isEmpty);
    });

    test('reading a steady rate reports that rate as the pace', () {
      final smoothedPace = SmoothedReadingPace.fromProgressDeltas(
        steadyReading(percentPerDay: 5, days: 120),
        now: day(120),
      );

      expect(smoothedPace.currentPace, closeTo(5, 1e-9));
    });

    test('same-day progress across books sums into the daily pace', () {
      final twoBooksAt2PercentEach = [
        for (var offset = 0; offset < 120; offset++) ...[
          read(day(1 + offset), 2),
          read(day(1 + offset), 2),
        ],
      ];

      final smoothedPace = SmoothedReadingPace.fromProgressDeltas(
        twoBooksAt2PercentEach,
        now: day(120),
      );

      expect(smoothedPace.currentPace, closeTo(4, 1e-9));
    });

    test('smoothing spreads a burst onto neighboring days', () {
      final smoothedPace = SmoothedReadingPace.fromProgressDeltas([
        read(day(1), 3),
        read(day(20), 50),
      ], now: day(25));

      expect(paceOn(smoothedPace, day(19)), greaterThan(0));
    });

    test('period cutoff clips the display but history drives the edge', () {
      final smoothedPace = SmoothedReadingPace.fromProgressDeltas(
        [read(day(1), 40)],
        now: day(7),
        periodCutoff: day(5),
      );

      expect(smoothedPace.points.first.day, day(5));
      expect(smoothedPace.currentPace, greaterThan(0));
    });
  });
}
