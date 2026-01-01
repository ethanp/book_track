import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';

class FormatBreakdownCard extends StatelessWidget {
  const FormatBreakdownCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  static const formatColors = <BookFormat, Color>{
    BookFormat.audiobook: CupertinoColors.systemOrange,
    BookFormat.eBook: CupertinoColors.systemBlue,
    BookFormat.paperback: CupertinoColors.systemGreen,
    BookFormat.hardcover: CupertinoColors.systemIndigo,
  };

  @override
  Widget build(BuildContext context) {
    // Filter to books with activity in the period
    final cutoff = periodCutoff;
    final booksInPeriod = books
        .where((b) =>
            cutoff == null ||
            b.progressHistory.any((e) => e.end.isAfter(cutoff)))
        .toList();

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
          const SizedBox(height: 8),
          if (booksInPeriod.isEmpty)
            _emptyState()
          else
            _chartContent(booksInPeriod),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text('Reading by Format', style: TextStyles.h3),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.book,
              size: 40, color: CupertinoColors.systemGrey3),
          SizedBox(height: 8),
          Text('No books in this period',
              style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _chartContent(List<LibraryBook> booksInPeriod) {
    final data = _progressByFormat(booksInPeriod);
    if (data.isEmpty) return _emptyState();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 150,
              child: _pieChart(data),
            ),
          ),
          _legend(data),
        ],
      ),
    );
  }

  /// Calculate aggregate progress percentage by format.
  Map<BookFormat, double> _progressByFormat(List<LibraryBook> books) {
    final progress = <BookFormat, double>{};

    for (final book in books) {
      if (book.progressHistory.isEmpty || book.formats.isEmpty) continue;

      final sorted = book.progressHistory.toList()
        ..sort((a, b) => a.end.compareTo(b.end));

      final cutoff = periodCutoff;
      for (int i = 0; i < sorted.length; i++) {
        final event = sorted[i];
        if (cutoff != null && event.end.isBefore(cutoff)) continue;

        final format = book.formatById(event.formatId);
        if (format == null || !format.hasLength) continue;

        final currPercent = book.progressPercentAt(event) ?? 0;
        final prevPercent =
            i > 0 ? (book.progressPercentAt(sorted[i - 1]) ?? 0) : 0.0;
        final percentDelta = max(0.0, currPercent - prevPercent);

        if (percentDelta > 0) {
          progress[format.format] =
              (progress[format.format] ?? 0) + percentDelta;
        }
      }
    }
    return progress;
  }

  Widget _pieChart(Map<BookFormat, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: data.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return PieChartSectionData(
            color: formatColors[entry.key] ?? CupertinoColors.systemGrey,
            value: entry.value,
            title: '${percentage.round()}%',
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
            radius: 45,
          );
        }).toList(),
      ),
    );
  }

  Widget _legend(Map<BookFormat, double> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.keys.map((format) => _legendItem(format, data)).toList(),
    );
  }

  Widget _legendItem(BookFormat format, Map<BookFormat, double> data) {
    final value = data[format] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: formatColors[format] ?? CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${format.nameAsCapitalizedWords} (${value.round()}%)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
