import 'dart:math' show max;

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_utils/ethan_utils.dart';
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
    BookFormat.audiobook: AppColors.audiobook,
    BookFormat.eBook: AppColors.ebook,
    BookFormat.paperback: AppColors.paperback,
    BookFormat.hardcover: AppColors.hardcover,
  };

  @override
  Widget build(BuildContext context) {
    final cutoff = periodCutoff;
    final booksInPeriod = books
        .where((book) =>
            cutoff == null ||
            book.progressHistory.any((event) => event.end.isAfter(cutoff)))
        .toList();

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _title(),
          const SizedBox(height: AppSpacing.sm),
          if (booksInPeriod.isEmpty)
            _emptyState()
          else
            _chartContent(booksInPeriod),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _title() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.md,
          left: AppSpacing.lg,
        ),
        child: Text('Reading by Format', style: AppTextStyles.h3),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.book, size: 40, color: AppColors.shimmer),
          SizedBox(height: AppSpacing.sm),
          Text('No books in this period', style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }

  Widget _chartContent(List<LibraryBook> booksInPeriod) {
    final data = _progressByFormat(booksInPeriod);
    if (data.isEmpty) return _emptyState();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(height: 150, child: _pieChart(data)),
          ),
          _legend(data),
        ],
      ),
    );
  }

  Map<BookFormat, double> _progressByFormat(List<LibraryBook> books) {
    final progress = <BookFormat, double>{};
    for (final book in books) {
      if (book.progressHistory.isEmpty || book.formats.isEmpty) continue;
      final sorted = book.progressHistory.toList()
        ..sort((a, b) => a.end.compareTo(b.end));
      final cutoff = periodCutoff;
      for (int eventIdx = 0; eventIdx < sorted.length; eventIdx++) {
        final event = sorted[eventIdx];
        if (cutoff != null && event.end.isBefore(cutoff)) continue;
        final format = book.formatById(event.formatId);
        if (format == null || !format.hasLength) continue;
        final currPercent = book.progressPercentAt(event) ?? 0;
        final prevPercent = eventIdx > 0
            ? (book.progressPercentAt(sorted[eventIdx - 1]) ?? 0)
            : 0.0;
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
    final total = data.values.sum;
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: data.entries.mapL((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return PieChartSectionData(
            color: formatColors[entry.key] ?? AppColors.shimmer,
            value: entry.value,
            title: '${percentage.round()}%',
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
            radius: 45,
          );
        }),
      ),
    );
  }

  Widget _legend(Map<BookFormat, double> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.keys.mapL((format) => _legendItem(format, data)),
    );
  }

  Widget _legendItem(BookFormat format, Map<BookFormat, double> data) {
    final formatValue = data[format] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: formatColors[format] ?? AppColors.shimmer,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${format.nameAsCapitalizedWords} (${formatValue.round()}%)',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
