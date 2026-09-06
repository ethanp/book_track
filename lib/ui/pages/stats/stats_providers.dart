import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter_riverpod/legacy.dart';

final includeAbandonedProvider = StateProvider<bool>((ref) => true);

final includeAudiobooksProvider = StateProvider<bool>((ref) => true);

final includeReadingProvider = StateProvider<bool>((ref) => true);

final includeFinishedProvider = StateProvider<bool>((ref) => true);

class const StatsBookInclusion({
  required final bool includeAbandoned,
  required final bool includeAudiobooks,
  required final bool includeReading,
  required final bool includeFinished,
}) {
  bool includes(LibraryBook book) {
    if (!includeAbandoned && book.isAbandoned) return false;
    if (!includeAudiobooks && book.isAudiobook) return false;
    if (!includeReading && book.isReading) return false;
    if (!includeFinished && book.isFinished) return false;
    return true;
  }

  List<LibraryBook> appliedTo(List<LibraryBook> library) =>
      library.whereL(includes);
}

final statsPeriodProvider = StateProvider<StatsPeriod>(
  (ref) => StatsPeriod.allTime,
);

enum ProgressAggregation() {
  daily,
  weekly,
  monthly,
}

/// Time period options for filtering stats.
enum StatsPeriod({required final String label, required final int? daysAgo}) {
  week(label: '7D', daysAgo: 7),
  month(label: '30D', daysAgo: 30),
  quarter(label: '90D', daysAgo: 90),
  sixMonths(label: '6M', daysAgo: 182),
  year(label: '1Y', daysAgo: 365),
  allTime(label: 'All', daysAgo: null);

  /// Returns null for allTime (meaning no cutoff - show all data).
  DateTime? get cutoffDate {
    return daysAgo.map((int days) => DateTime.now().shiftedByDays(-days));
  }

  ProgressAggregation get chartAggregation => switch (this) {
    StatsPeriod.week || StatsPeriod.month => ProgressAggregation.daily,
    StatsPeriod.quarter => ProgressAggregation.weekly,
    StatsPeriod.sixMonths ||
    StatsPeriod.year ||
    StatsPeriod.allTime => ProgressAggregation.monthly,
  };
}
