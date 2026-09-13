import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/book_cover.dart';
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
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const StatsPage() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: const EAppHeader(title: 'Stats'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const FilterSection(),
            const Expanded(child: _StatsCardsList()),
          ],
        ),
      ),
    );
  }
}

class const _StatsCardsList() extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StatsCardsList> createState() => _StatsCardsListState();
}

class _StatsCardsListState() extends ConsumerState<_StatsCardsList> {
  List<LibraryBook> _books = const [];
  StatsPeriod _period = StatsPeriod.allTime;
  DateTime? _periodCutoff;
  bool _seeded = false;
  bool _applyScheduled = false;

  @override
  Widget build(BuildContext context) {
    _listenForFilterTaps();
    return ref.watch(userLibraryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString())),
      data: _listOrSeed,
    );
  }

  void _listenForFilterTaps() {
    ref.listen(includeAbandonedProvider, (_, _) => _scheduleApply());
    ref.listen(includeAudiobooksProvider, (_, _) => _scheduleApply());
    ref.listen(includeReadingProvider, (_, _) => _scheduleApply());
    ref.listen(includeFinishedProvider, (_, _) => _scheduleApply());
    ref.listen(statsPeriodProvider, (_, _) => _scheduleApply());
    ref.listen(userLibraryProvider, (previous, next) {
      if (next.hasValue) _applyFilters();
    });
  }

  Widget _listOrSeed(List<LibraryBook> library) {
    if (!_seeded) {
      _commitFilters(library);
      _seeded = true;
    }
    return ListView.builder(
      key: const PageStorageKey('stats_scroll'),
      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
      itemCount: 7,
      itemBuilder: (context, index) => _statsCard(index),
    );
  }

  void _scheduleApply() {
    if (_applyScheduled) return;
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      if (mounted) _applyFilters();
    });
  }

  void _applyFilters() {
    final List<LibraryBook>? library = ref.read(userLibraryProvider).value;
    if (library == null) return;
    setState(() => _commitFilters(library));
  }

  void _commitFilters(List<LibraryBook> library) {
    _books = StatsBookInclusion(
      includeAbandoned: ref.read(includeAbandonedProvider),
      includeAudiobooks: ref.read(includeAudiobooksProvider),
      includeReading: ref.read(includeReadingProvider),
      includeFinished: ref.read(includeFinishedProvider),
    ).appliedTo(library);
    _period = ref.read(statsPeriodProvider);
    _periodCutoff = _period.cutoffDate;
  }

  Widget _statsCard(int index) {
    return switch (index) {
      0 => SummaryStatsCard(books: _books, periodCutoff: _periodCutoff),
      1 => ActivityCalendarCard(books: _books, periodCutoff: _periodCutoff),
      2 => ReadLinesCard(books: _books, periodCutoff: _periodCutoff),
      3 => ProgressChartCard(books: _books, period: _period),
      4 => FormatBreakdownCard(books: _books, periodCutoff: _periodCutoff),
      5 => ReadingPatternsCard(books: _books, periodCutoff: _periodCutoff),
      _ => ChartCard(
        title: 'Recent Stats',
        chart: RecentBooksWidget(books: _books, periodCutoff: _periodCutoff),
      ),
    };
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
                        color: EColors.success,
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
    return BookCover(
      width: 22.5,
      height: 30,
      bytes: book.book.coverArt,
      borderRadius: 3,
    );
  }
}

class const _RecentBookProgress({
  required final LibraryBook book,
  required final int progressMade,
});
