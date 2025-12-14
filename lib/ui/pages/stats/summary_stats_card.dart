import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;

class SummaryStatsCard extends StatelessWidget {
  const SummaryStatsCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime periodCutoff;

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _title(),
          _statusRow(stats),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _totalsRow(stats),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 16),
      child: Text('Your Reading Stats', style: TextStyles.h3),
    );
  }

  Widget _statusRow(_Stats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statTile(stats.finished.toString(), 'Finished'),
          _statTile(stats.reading.toString(), 'Reading'),
          _statTile(stats.abandoned.toString(), 'Abandoned'),
          _statTile(stats.completionRateDisplay, 'Complete'),
        ],
      ),
    );
  }

  Widget _totalsRow(_Stats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statTile(_formatNumber(stats.totalPages), 'pages read'),
          _statTile('${stats.totalHours}h', 'listened'),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  _Stats _calculateStats() {
    // Filter to books with activity in the period
    final booksInPeriod = books
        .where((b) => b.progressHistory.any((e) => e.end.isAfter(periodCutoff)))
        .toList();

    final finished = booksInPeriod
        .where((b) => b.readingStatus == ReadingStatus.finished)
        .length;
    final reading = booksInPeriod
        .where((b) => b.readingStatus == ReadingStatus.reading)
        .length;
    final abandoned = booksInPeriod
        .where((b) => b.readingStatus == ReadingStatus.abandoned)
        .length;

    final completionRate = finished + abandoned > 0
        ? (finished / (finished + abandoned) * 100).round()
        : null;

    // Calculate pages/minutes read in the period based on event format
    int totalPages = 0;
    int totalMinutes = 0;

    for (final book in booksInPeriod) {
      if (book.progressHistory.isEmpty || book.formats.isEmpty) continue;

      final eventsInPeriod = book.progressHistory
          .where((e) => e.end.isAfter(periodCutoff))
          .toList();
      if (eventsInPeriod.isEmpty) continue;

      // Sort events chronologically
      final sorted = book.progressHistory.toList()
        ..sort((a, b) => a.end.compareTo(b.end));

      // Calculate deltas for each event in the period
      for (int i = 0; i < sorted.length; i++) {
        final event = sorted[i];
        if (event.end.isBefore(periodCutoff)) continue;

        final format = book.formatById(event.formatId);
        if (format == null || !format.hasLength) continue;

        // Get previous event's progress
        final prevEvent = i > 0 ? sorted[i - 1] : null;
        int prevProgress = 0;
        if (prevEvent != null) {
          final prevFormat = book.formatById(prevEvent.formatId);
          if (prevFormat != null && prevFormat.hasLength) {
            // Convert to same units if formats differ
            if (prevFormat.supaId == format.supaId) {
              prevProgress = prevEvent.progress;
            } else {
              // Convert via percentage
              final prevPercent =
                  prevFormat.progressToPercent(prevEvent.progress);
              if (prevPercent != null) {
                prevProgress = format.percentToProgress(prevPercent);
              }
            }
          }
        }

        // Handle case where previous event was before period cutoff
        if (prevEvent != null && prevEvent.end.isBefore(periodCutoff)) {
          // Only count progress from cutoff point onwards
          final cutoffPercent = book.progressPercentAt(prevEvent);
          if (cutoffPercent != null) {
            prevProgress = format.percentToProgress(cutoffPercent);
          }
        }

        final delta = event.progress - prevProgress;
        if (delta > 0) {
          if (format.isAudiobook) {
            totalMinutes += delta;
          } else {
            totalPages += delta;
          }
        }
      }
    }

    return _Stats(
      finished: finished,
      reading: reading,
      abandoned: abandoned,
      completionRate: completionRate,
      totalPages: totalPages,
      totalMinutes: totalMinutes,
    );
  }
}

class _Stats {
  const _Stats({
    required this.finished,
    required this.reading,
    required this.abandoned,
    required this.completionRate,
    required this.totalPages,
    required this.totalMinutes,
  });

  final int finished;
  final int reading;
  final int abandoned;
  final int? completionRate;
  final int totalPages;
  final int totalMinutes;

  String get completionRateDisplay =>
      completionRate != null ? '$completionRate%' : '--';

  int get totalHours => totalMinutes ~/ 60;
}
