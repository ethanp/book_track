import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';

/// Summary statistics for a user's reading activity.
///
/// Simple immutable data class with a single factory entry point.
/// All computation complexity is hidden in [_StatsCalculator].
class SummaryStats {
  const SummaryStats._({
    required this.statusCounts,
    required this.totalPages,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.longestStreakStart,
    required this.longestStreakEnd,
  });

  final Map<ReadingStatus, int> statusCounts;
  final int totalPages;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;

  int get totalHours => totalMinutes ~/ 60;

  String get longestStreakDateRange {
    if (longestStreakStart == null || longestStreakEnd == null) return '';
    final fmt = DateFormat('MMM d');
    final yearFmt = DateFormat("''yy");
    final start = fmt.format(longestStreakStart!);
    final end = fmt.format(longestStreakEnd!);
    final year = yearFmt.format(longestStreakEnd!);
    return start == end ? '$start $year' : '$start - $end, $year';
  }

  /// Computes summary statistics for the given books within the period.
  static SummaryStats calculate(
          List<LibraryBook> books, DateTime? periodCutoff) =>
      _StatsCalculator(books, periodCutoff).compute();
}

/// Encapsulates all computation logic for [SummaryStats].
class _StatsCalculator {
  _StatsCalculator(List<LibraryBook> allBooks, this._periodCutoff)
      : _books = _filterByPeriod(allBooks, _periodCutoff);

  final DateTime? _periodCutoff;
  final List<LibraryBook> _books;

  static List<LibraryBook> _filterByPeriod(
      List<LibraryBook> books, DateTime? cutoff) {
    if (cutoff == null) return books;
    return books
        .where((b) => b.progressHistory.any((e) => e.end.isAfter(cutoff)))
        .toList();
  }

  SummaryStats compute() {
    final statusCounts = _countByStatus(_books);
    final progress = _ProgressTotals.from(_books, _periodCutoff);
    final streak = _StreakResult.from(_books, _periodCutoff);

    return SummaryStats._(
      statusCounts: statusCounts,
      totalPages: progress.pages,
      totalMinutes: progress.minutes,
      currentStreak: streak.current,
      longestStreak: streak.longest,
      longestStreakStart: streak.longestStart,
      longestStreakEnd: streak.longestEnd,
    );
  }

  static Map<ReadingStatus, int> _countByStatus(List<LibraryBook> books) {
    return {
      for (final status in ReadingStatus.values)
        status: books.where((b) => b.readingStatus == status).length,
    };
  }
}

/// Accumulates pages read and minutes listened within a period.
class _ProgressTotals {
  const _ProgressTotals._({required this.pages, required this.minutes});

  final int pages;
  final int minutes;

  factory _ProgressTotals.from(List<LibraryBook> books, DateTime? cutoff) {
    int pages = 0;
    int minutes = 0;

    for (final book in books) {
      if (book.progressHistory.isEmpty || book.formats.isEmpty) continue;
      final deltas = _BookProgressDeltas(book, cutoff);
      pages += deltas.pages;
      minutes += deltas.minutes;
    }

    return _ProgressTotals._(pages: pages, minutes: minutes);
  }
}

/// Computes progress deltas for a single book within a period.
class _BookProgressDeltas {
  _BookProgressDeltas(this._book, this._cutoff) {
    _compute();
  }

  final LibraryBook _book;
  final DateTime? _cutoff;

  int pages = 0;
  int minutes = 0;

  void _compute() {
    final sorted = _book.progressHistory.toList()
      ..sort((a, b) => a.end.compareTo(b.end));

    for (int i = 0; i < sorted.length; i++) {
      final event = sorted[i];
      if (_cutoff != null && event.end.isBefore(_cutoff)) continue;

      final format = _book.formatById(event.formatId);
      if (format == null || !format.hasLength) continue;

      final prevProgress = _previousProgress(sorted, i, format);
      final delta = event.progress - prevProgress;

      if (delta > 0) {
        if (format.isAudiobook) {
          minutes += delta;
        } else {
          pages += delta;
        }
      }
    }
  }

  int _previousProgress(
      List<ProgressEvent> sorted, int index, LibraryBookFormat format) {
    if (index == 0) return 0;

    final prevEvent = sorted[index - 1];
    final prevFormat = _book.formatById(prevEvent.formatId);

    // If previous event is before cutoff, use cutoff progress
    if (_cutoff != null && prevEvent.end.isBefore(_cutoff)) {
      final cutoffPercent = _book.progressPercentAt(prevEvent);
      return cutoffPercent != null
          ? format.percentToProgress(cutoffPercent)
          : 0;
    }

    if (prevFormat == null || !prevFormat.hasLength) return 0;

    // Same format: use raw progress
    if (prevFormat.supaId == format.supaId) return prevEvent.progress;

    // Different format: convert via percentage
    final prevPercent = prevFormat.progressToPercent(prevEvent.progress);
    return prevPercent != null ? format.percentToProgress(prevPercent) : 0;
  }
}

/// Computes current and longest reading streaks with date ranges.
class _StreakResult {
  const _StreakResult._({
    required this.current,
    required this.longest,
    required this.longestStart,
    required this.longestEnd,
  });

  final int current;
  final int longest;
  final DateTime? longestStart;
  final DateTime? longestEnd;

  factory _StreakResult.from(List<LibraryBook> books, DateTime? cutoff) {
    final activeDays = _collectActiveDays(books, cutoff);
    if (activeDays.isEmpty) {
      return const _StreakResult._(
          current: 0, longest: 0, longestStart: null, longestEnd: null);
    }
    return _StreakCalculator(activeDays).compute();
  }

  static Set<DateTime> _collectActiveDays(
      List<LibraryBook> books, DateTime? cutoff) {
    final days = <DateTime>{};
    for (final book in books) {
      for (final event in book.progressHistory) {
        final date = DateUtils.dateOnly(event.end);
        if (cutoff == null || !date.isBefore(cutoff)) {
          days.add(date);
        }
      }
    }
    return days;
  }
}

/// Performs streak calculation on a set of active days.
class _StreakCalculator {
  _StreakCalculator(Set<DateTime> days) : _sorted = days.toList()..sort();

  final List<DateTime> _sorted;

  _StreakResult compute() {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final isActive = DateUtils.isSameDay(_sorted.last, today) ||
        DateUtils.isSameDay(_sorted.last, yesterday);

    int longest = 1, longestStart = 0, longestEnd = 0;
    int running = 1, runningStart = 0;

    for (int i = 1; i < _sorted.length; i++) {
      final gap = _sorted[i].difference(_sorted[i - 1]).inDays;
      if (gap == 1) {
        running++;
      } else if (gap > 1) {
        if (running > longest) {
          longest = running;
          longestStart = runningStart;
          longestEnd = i - 1;
        }
        running = 1;
        runningStart = i;
      }
    }

    if (running > longest) {
      longest = running;
      longestStart = runningStart;
      longestEnd = _sorted.length - 1;
    }

    return _StreakResult._(
      current: isActive ? running : 0,
      longest: longest,
      longestStart: _sorted[longestStart],
      longestEnd: _sorted[longestEnd],
    );
  }
}
