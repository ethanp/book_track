import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the archive filter toggle in stats.
/// When true (default), archived books are included in stats.
final showArchivedProvider = StateProvider<bool>((ref) => true);

/// Provider for the stats counting mode.
final statsCountModeProvider =
    StateProvider<StatsCountMode>((ref) => StatsCountMode.sessions);

/// How to count reading activity in stats.
enum StatsCountMode {
  /// Count individual progress events/sessions
  sessions('Sessions'),

  /// Count aggregate percentage progress
  progress('Progress');

  const StatsCountMode(this.label);
  final String label;
}

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

  /// Returns null for allTime (meaning no cutoff - show all data).
  DateTime? get cutoffDate {
    final now = DateTime.now();
    return switch (this) {
      StatsPeriod.week => now.subtract(const Duration(days: 7)),
      StatsPeriod.month => now.subtract(const Duration(days: 30)),
      StatsPeriod.quarter => now.subtract(const Duration(days: 90)),
      StatsPeriod.year => DateTime(now.year, 1, 1),
      StatsPeriod.allTime => null, // No cutoff - use earliest data date
    };
  }
}
