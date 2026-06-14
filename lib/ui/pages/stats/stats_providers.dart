import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the archive filter toggle in stats.
/// When true (default), archived books are included in stats.
final showArchivedProvider = StateProvider<bool>((ref) => true);

/// Provider for the time period filter in stats.
final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.allTime);

/// Provider for the Read Lines chart toggle. When true, the chart only shows
/// books that are currently being read (not finished or abandoned).
final readLinesCurrentlyReadingOnlyProvider =
    StateProvider<bool>((ref) => false);

enum ProgressAggregation { daily, weekly, monthly }

/// Time period options for filtering stats.
enum StatsPeriod {
  week(label: '7D', daysAgo: 7),
  month(label: '30D', daysAgo: 30),
  quarter(label: '90D', daysAgo: 90),
  sixMonths(label: '6M', daysAgo: 182),
  year(label: '1Y', daysAgo: 365),
  allTime(label: 'All', daysAgo: null);

  const StatsPeriod({required this.label, required this.daysAgo});

  final String label;
  final int? daysAgo;

  /// Returns null for allTime (meaning no cutoff - show all data).
  DateTime? get cutoffDate {
    return daysAgo
        .map((int days) => DateTime.now().shiftedByDays(-days));
  }

  ProgressAggregation get chartAggregation => switch (this) {
        StatsPeriod.week || StatsPeriod.month => ProgressAggregation.daily,
        StatsPeriod.quarter => ProgressAggregation.weekly,
        StatsPeriod.sixMonths ||
        StatsPeriod.year ||
        StatsPeriod.allTime =>
          ProgressAggregation.monthly,
      };
}
