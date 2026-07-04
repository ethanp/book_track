import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/scroll_propagating_list_view.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/stats/filter_section.dart';
import 'package:book_track/ui/pages/stats/format_breakdown_card.dart';
import 'package:book_track/ui/pages/stats/progress_chart_card.dart';
import 'package:book_track/ui/pages/stats/read_lines_card.dart';
import 'package:book_track/ui/pages/stats/reading_patterns_card.dart';
import 'package:book_track/ui/pages/stats/activity_calendar_card.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:book_track/ui/pages/stats/summary_stats_card.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Stats'),
      ),
      child: ref.userLibrary((books) => _body(books, ref)),
    );
  }

  Widget _body(List<LibraryBook> userLibrary, WidgetRef ref) {
    final bool showArchived = ref.watch(showArchivedProvider);
    final StatsPeriod selectedPeriod = ref.watch(statsPeriodProvider);
    final DateTime? periodCutoff = selectedPeriod.cutoffDate;

    final List<LibraryBook> books = showArchived
        ? userLibrary
        : userLibrary.whereL((book) => !book.archived);

    return SafeArea(
      child: Column(
        children: [
          const FilterSection(),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('stats_scroll'),
              child: Column(
                children: [
                  _archivedToggle(ref, showArchived),
                  SummaryStatsCard(books: books, periodCutoff: periodCutoff),
                  ActivityCalendarCard(
                    key: ValueKey('calendar-${books.length}-$showArchived'),
                    books: books,
                    periodCutoff: periodCutoff,
                  ),
                  ReadLinesCard(books: books, periodCutoff: periodCutoff),
                  ProgressChartCard(books: books, period: selectedPeriod),
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

  Widget _archivedToggle(WidgetRef ref, bool showArchived) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Include abandoned books', style: AppTextStyles.body),
          CupertinoSwitch(
            value: showArchived,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              ref.read(showArchivedProvider.notifier).state = value;
            },
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
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl,
                left: AppSpacing.lg,
              ),
              child: Text(title, style: AppTextStyles.h3),
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 18,
                right: 35,
                top: AppSpacing.sm,
                bottom: 14,
              ),
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
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    final booksWithProgress = recentBooks
        .where((book) => book.progressHistory.isNotEmpty)
        .map((book) {
      final sorted = book.progressHistory.toList()
        ..sort((a, b) => a.end.compareTo(b.end));
      final beforeWindow = cutoff == null
          ? null
          : sorted.where((event) => event.end.isBefore(cutoff)).lastOrNull;
      final startPercent =
          beforeWindow == null ? 0 : book.intPercentProgressAt(beforeWindow);
      final endPercent = book.intPercentProgressAt(sorted.last);
      final progressMade = endPercent - startPercent;
      return (book: book, progressMade: progressMade);
    }).toList()
      ..sort((a, b) {
        if (a.progressMade != b.progressMade) {
          return b.progressMade.compareTo(a.progressMade);
        }
        return a.book.book.title.compareTo(b.book.book.title);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Books read in this period',
          style: AppTextStyles.h5,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ScrollPropagatingListView(
            itemCount: booksWithProgress.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final entry = booksWithProgress[index];
              final book = entry.book;
              final progressMade = entry.progressMade;
              return GestureDetector(
                onTap: () => context.push(LibraryBookPage(book.supaId)),
                child: Row(
                  children: [
                    _bookCover(book),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        book.book.title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ),
                    Text(
                      '+$progressMade%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
      child: const Icon(CupertinoIcons.book, size: 16, color: AppColors.primary),
    );
  }
}
