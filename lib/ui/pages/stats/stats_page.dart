import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/stats/filter_section.dart';
import 'package:book_track/ui/pages/stats/format_breakdown_card.dart';
import 'package:book_track/ui/pages/stats/progress_chart_card.dart';
import 'package:book_track/ui/pages/stats/read_lines_card.dart';
import 'package:book_track/ui/pages/stats/reading_patterns_card.dart';
import 'package:book_track/ui/pages/stats/activity_calendar_card.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:book_track/ui/pages/stats/summary_stats_card.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_card.dart';
import 'recent_books.dart';

class const StatsPage() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(
        title: 'Stats',
        actions: [
          const ESyncPhaseIcon(),
        ],
      ),
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
