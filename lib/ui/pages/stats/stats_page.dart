import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/cover_art_bytes.dart';
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
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const StatsPage() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: const EAppHeader(title: 'Stats'),
      body: ref.userLibrary((books) => _body(books, ref)),
    );
  }

  Widget _body(List<LibraryBook> userLibrary, WidgetRef ref) {
    final bool showArchived = ref.watch(showArchivedProvider);
    final bool includeAudiobooks = ref.watch(includeAudiobooksProvider);
    final StatsPeriod selectedPeriod = ref.watch(statsPeriodProvider);
    final DateTime? periodCutoff = selectedPeriod.cutoffDate;

    final List<LibraryBook> books = userLibrary.whereL(
      (book) =>
          (showArchived || !book.archived) &&
          (includeAudiobooks || !book.isAudiobook),
    );

    return SafeArea(
      child: Column(
        children: [
          const FilterSection(),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('stats_scroll'),
              child: Column(
                children: [
                  _filterToggles(ref, includeAudiobooks, showArchived),
                  SummaryStatsCard(books: books, periodCutoff: periodCutoff),
                  ActivityCalendarCard(
                    key: ValueKey(
                      'calendar-${books.length}-$showArchived-$includeAudiobooks',
                    ),
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
                      books: books,
                      periodCutoff: periodCutoff,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterToggles(
    WidgetRef ref,
    bool includeAudiobooks,
    bool showArchived,
  ) {
    return Column(
      children: [
        _filterToggle(
          label: 'Include audiobooks',
          value: includeAudiobooks,
          onChanged: (value) {
            ref.read(includeAudiobooksProvider.notifier).state = value;
          },
        ),
        _filterToggle(
          label: 'Include abandoned books',
          value: showArchived,
          onChanged: (value) {
            ref.read(showArchivedProvider.notifier).state = value;
          },
        ),
      ],
    );
  }

  Widget _filterToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class const ChartCard({
  required final String title,
  required final Widget chart,
}) extends StatelessWidget {
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

class const RecentBooksWidget({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cutoff = periodCutoff;
    final recentBooks = books
        .where(
          (book) =>
              cutoff == null ||
              book.progressHistory.any((event) => event.end.isAfter(cutoff)),
        )
        .toList();

    if (recentBooks.isEmpty) {
      return Center(
        child: Text(
          'No books read in this period',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    final booksWithProgress =
        recentBooks
            .where((book) => book.hasProgress)
            .map(_progressInPeriod)
            .toList()
          ..sort((left, right) {
            if (left.progressMade != right.progressMade) {
              return right.progressMade.compareTo(left.progressMade);
            }
            return left.book.book.title.compareTo(right.book.book.title);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Books read in this period', style: AppTextStyles.h5),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ScrollPropagatingListView(
            itemCount: booksWithProgress.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final recentBook = booksWithProgress[index];
              final book = recentBook.book;
              final progressMade = recentBook.progressMade;
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

  _RecentBookProgress _progressInPeriod(LibraryBook book) {
    final sorted = book.progressHistory.toList()
      ..sort((left, right) => left.end.compareTo(right.end));
    final cutoff = periodCutoff;
    final beforeWindow = cutoff == null
        ? null
        : sorted.where((event) => event.end.isBefore(cutoff)).lastOrNull;
    final startPercent = beforeWindow == null
        ? 0
        : book.intPercentProgressAt(beforeWindow);
    final endPercent = book.intPercentProgressAt(sorted.last);
    return _RecentBookProgress(
      book: book,
      progressMade: endPercent - startPercent,
    );
  }

  Widget _bookCover(LibraryBook book) {
    const double size = 30;
    final placeholder = SizedBox(
      width: size * 0.75,
      height: size,
      child: const Icon(Icons.menu_book, size: 16, color: AppColors.primary),
    );
    final coverArt = book.book.coverArtS;
    if (coverArt == null || !coverArtLooksDecodable(coverArt)) {
      return placeholder;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.memory(
        coverArt,
        width: size * 0.75,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class const _RecentBookProgress({
  required final LibraryBook book,
  required final int progressMade,
});
