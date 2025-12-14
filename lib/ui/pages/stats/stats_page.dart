import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/filter_section.dart';
import 'package:book_track/ui/pages/stats/format_breakdown_card.dart';
import 'package:book_track/ui/pages/stats/progress_chart_card.dart';
import 'package:book_track/ui/pages/stats/reading_patterns_card.dart';
import 'package:book_track/ui/pages/stats/reading_streak_card.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:book_track/ui/pages/stats/summary_stats_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Stats')),
      child: ref.userLibrary((books) => _body(books, ref)),
    );
  }

  Widget _body(List<LibraryBook> userLibrary, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedProvider);
    final selectedPeriod = ref.watch(statsPeriodProvider);
    final periodCutoff = selectedPeriod.cutoffDate;

    final books = showArchived
        ? userLibrary
        : userLibrary.where((b) => !b.archived).toList();

    return SafeArea(
      child: Column(
        children: [
          const FilterSection(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Abandoned books toggle
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Include abandoned books'),
                        CupertinoSwitch(
                          value: showArchived,
                          onChanged: (value) {
                            ref.read(showArchivedProvider.notifier).state =
                                value;
                          },
                        ),
                      ],
                    ),
                  ),
                  SummaryStatsCard(books: books, periodCutoff: periodCutoff),
                  ReadingStreakCard(
                    key: ValueKey('streak-${books.length}-$showArchived'),
                    books: books,
                    periodCutoff: periodCutoff,
                  ),
                  ChartCard(
                    title: 'Read Lines',
                    chart: BooksProgressChart(
                        books: books, periodCutoff: periodCutoff),
                  ),
                  ProgressChartCard(books: books, periodCutoff: periodCutoff),
                  FormatBreakdownCard(books: books, periodCutoff: periodCutoff),
                  ReadingPatternsCard(books: books, periodCutoff: periodCutoff),
                  ChartCard(
                    title: 'Recent Stats',
                    chart: RecentBooksWidget(
                        books: books, periodCutoff: periodCutoff),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.chart,
  });

  final String title;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 20),
            child: Text(title, style: TextStyles.h3),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 18, right: 35, top: 8, bottom: 14),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentBooksWidget extends StatelessWidget {
  const RecentBooksWidget({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    final cutoff = periodCutoff;
    final recentBooks = books
        .where((book) =>
            cutoff == null ||
            book.progressHistory.any((event) => event.end.isAfter(cutoff)))
        .toList();

    if (recentBooks.isEmpty) {
      return const Center(
        child: Text(
          'No books read in this period',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    // Calculate progress made for each book and sort
    final booksWithProgress = recentBooks
        .where((book) => book.progressHistory.isNotEmpty)
        .map((book) {
      final sorted = book.progressHistory.toList()
        ..sort((a, b) => a.end.compareTo(b.end));
      final beforeWindow = cutoff == null
          ? null
          : sorted.where((e) => e.end.isBefore(cutoff)).lastOrNull;
      final startPercent =
          beforeWindow == null ? 0 : book.intPercentProgressAt(beforeWindow);
      final endPercent = book.intPercentProgressAt(sorted.last);
      final progressMade = endPercent - startPercent;
      return (book: book, progressMade: progressMade);
    }).toList();

    // Sort by progressMade (highest first), then alphabetically by title
    booksWithProgress.sort((a, b) {
      // First sort by progressMade (descending)
      if (a.progressMade != b.progressMade) {
        return b.progressMade.compareTo(a.progressMade);
      }
      // Then sort alphabetically by title
      return a.book.book.title.compareTo(b.book.book.title);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Books read in this period',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: booksWithProgress.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final entry = booksWithProgress[index];
              final book = entry.book;
              final progressMade = entry.progressMade;
              return Row(
                children: [
                  _bookCover(book),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.book.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '+$progressMade%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookCover(LibraryBook book) {
    const double size = 30;
    if (book.book.coverArtS != null && book.book.coverArtS!.length >= 4) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.memory(
          book.book.coverArtS!,
          width: size * 0.75,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return SizedBox(
      width: size * 0.75,
      height: size,
      child: const Icon(CupertinoIcons.book, size: 16),
    );
  }
}
