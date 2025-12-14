import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the archive filter toggle in stats.
/// When true (default), archived books are included in stats.
final showArchivedProvider = StateProvider<bool>((ref) => true);

/// Provider for the time period filter in stats.
final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.allTime);

/// Time period options for filtering stats.
enum StatsPeriod {
  week('7D'),
  month('30D'),
  quarter('90D'),
  year('YTD'),
  allTime('All');

  const StatsPeriod(this.label);
  final String label;

  DateTime get cutoffDate {
    final now = DateTime.now();
    return switch (this) {
      StatsPeriod.week => now.subtract(const Duration(days: 7)),
      StatsPeriod.month => now.subtract(const Duration(days: 30)),
      StatsPeriod.quarter => now.subtract(const Duration(days: 90)),
      StatsPeriod.year => DateTime(now.year, 1, 1),
      StatsPeriod.allTime => DateTime(1970),
    };
  }
}

