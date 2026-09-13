import 'dart:math' as math;

import 'package:book_track/ui/common/books_progress_chart/smoothed_book_progress.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter_test/flutter_test.dart';

BookProgressPoint logged(DateTime at, double percent) =>
    BookProgressPoint(at: at, percent: percent);

DateTime day(int dayOfMonth) => DateTime(2026, 1, dayOfMonth);

double percentOn(SmoothedBookProgress progress, DateTime at) => progress.points
    .firstWhere((point) => point.at.startOfDay == at.startOfDay)
    .percent;

void main() {
  group('SmoothedBookProgress', () {
    test('a single log is left as-is', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(4), 22),
      ]);

      expect(progress.points, hasLength(1));
      expect(progress.points.single.percent, 22);
    });

    test('the first logged percent stays pinned', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(10), 10),
        logged(day(11), 80),
        logged(day(30), 85),
      ]);

      expect(percentOn(progress, day(1)), closeTo(0, 1e-9));
    });

    test('an interior spike is approached but not reached', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(DateTime(2026, 8, 28), 0),
        logged(DateTime(2026, 8, 30), 15),
        logged(DateTime(2026, 8, 31), 28),
        logged(DateTime(2026, 9, 8), 38),
      ]);

      expect(percentOn(progress, DateTime(2026, 8, 31)), lessThan(28));
    });

    test(
      'the last day finishes above a last log that sits below the trend',
      () {
        final progress = SmoothedBookProgress.fromLoggedPercents([
          logged(DateTime(2026, 8, 28), 0),
          logged(DateTime(2026, 8, 30), 15),
          logged(DateTime(2026, 8, 31), 28),
          logged(DateTime(2026, 9, 8), 38),
        ]);

        expect(percentOn(progress, DateTime(2026, 9, 8)), greaterThan(38));
      },
    );

    test('daily dates increase strictly', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(5), 40),
      ]);

      for (var index = 1; index < progress.points.length; index++) {
        expect(
          progress.points[index].at.isAfter(progress.points[index - 1].at),
          isTrue,
        );
      }
    });

    test('percents never retreat when logs are nondecreasing', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(4), 20),
        logged(day(10), 35),
        logged(day(18), 40),
      ]);

      for (var index = 1; index < progress.points.length; index++) {
        expect(
          progress.points[index].percent,
          greaterThanOrEqualTo(progress.points[index - 1].percent),
        );
      }
    });

    test('percents stay between 0 and 100', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(2), 15),
        logged(day(3), 28),
        logged(day(11), 38),
      ]);

      for (final point in progress.points) {
        expect(point.percent, greaterThanOrEqualTo(0));
        expect(point.percent, lessThanOrEqualTo(100));
      }
    });

    test(
      'the line stays closer to the first-to-last pace than the farthest log',
      () {
        final logs = [
          logged(day(1), 0),
          logged(day(20), 20),
          logged(day(40), 40),
          logged(day(41), 80),
          logged(day(60), 50),
        ];
        final progress = SmoothedBookProgress.fromLoggedPercents(logs);
        final first = logs.first;
        final last = logs.last;
        final spanMillis = last.at.difference(first.at).inMilliseconds;
        double paceAt(DateTime at) {
          final along = at.difference(first.at).inMilliseconds / spanMillis;
          return first.percent + (last.percent - first.percent) * along;
        }

        final farthestLogDeviation = logs
            .map((log) => (log.percent - paceAt(log.at)).abs())
            .reduce(math.max);
        final farthestSmoothedDeviation = progress.points
            .map((point) => (point.percent - paceAt(point.at)).abs())
            .reduce(math.max);

        expect(
          farthestSmoothedDeviation,
          lessThanOrEqualTo(farthestLogDeviation),
        );
        expect(percentOn(progress, day(41)), lessThan(80));
      },
    );

    test('days between logs are filled so the trend has a daily series', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(5), 40),
      ]);

      expect(progress.points, hasLength(5));
      expect(percentOn(progress, day(3)), greaterThan(0));
      expect(percentOn(progress, day(3)), lessThan(40));
    });

    test('empty logs stay empty', () {
      final progress = SmoothedBookProgress.fromLoggedPercents(const []);
      expect(progress.points, isEmpty);
    });

    test('same-day logs produce one deterministic day', () {
      final morning = DateTime(2026, 1, 4, 8);
      final evening = DateTime(2026, 1, 4, 20);
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(evening, 40),
        logged(morning, 10),
      ]);

      expect(progress.points, hasLength(1));
      expect(progress.points.single.at.startOfDay, day(4));
      expect(progress.points.single.percent, 10);
    });

    test('sparse logs still emit a point for every day in the span', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(20), 50),
      ]);

      expect(progress.points, hasLength(20));
      expect(progress.points.first.at, day(1));
      expect(progress.points.last.at, day(20));
    });

    test('the same logs always produce the same percents', () {
      final logs = [logged(day(1), 0), logged(day(8), 22), logged(day(15), 40)];
      final first = SmoothedBookProgress.fromLoggedPercents(logs);
      final second = SmoothedBookProgress.fromLoggedPercents(logs);

      expect(
        first.points.map((point) => point.percent),
        second.points.map((point) => point.percent),
      );
    });

    test('output never contains NaN or infinity', () {
      final progress = SmoothedBookProgress.fromLoggedPercents([
        logged(day(1), 0),
        logged(day(1), 0),
        logged(day(2), 100),
        logged(day(10), 100),
      ]);

      for (final point in progress.points) {
        expect(point.percent.isFinite, isTrue);
        expect(point.percent.isNaN, isFalse);
      }
    });
  });
}
