import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingStreakCard extends ConsumerWidget {
  const ReadingStreakCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countMode = ref.watch(statsCountModeProvider);
    return AsyncStatsCard<ReadingActivityData>(
      cacheKey:
          '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}-${countMode.name}',
      compute: () => _computeData(books, periodCutoff, countMode),
      loadingHeight: 280,
      builder: (data) => _buildCard(data, countMode),
    );
  }

  static ReadingActivityData _computeData(
    List<LibraryBook> books,
    DateTime? periodCutoff,
    StatsCountMode countMode,
  ) {
    if (countMode == StatsCountMode.sessions) {
      final eventDates =
          books.expand((b) => b.progressHistory).map((e) => e.end).toList();
      return ReadingActivityData.fromEvents(
        eventDates,
        periodCutoff: periodCutoff,
      );
    } else {
      // Progress mode: sum percentage progress per day
      return ReadingActivityData.fromProgress(
        books,
        periodCutoff: periodCutoff,
      );
    }
  }

  Widget _buildCard(ReadingActivityData data, StatsCountMode countMode) {
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
          _streakDisplay(data.currentStreak, data.longestStreak),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarHeatmap(
              activityByDay: data.activityByDay,
              books: books,
              periodCutoff: periodCutoff,
              isProgressMode: countMode == StatsCountMode.progress,
            ),
          ),
          const SizedBox(height: 12),
          _legend(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text('Reading Activity', style: TextStyles.h3),
    );
  }

  Widget _streakDisplay(int current, int longest) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _streakTile('🔥', 'Current', current),
        _streakTile('🏆', 'Longest', longest),
      ],
    );
  }

  Widget _streakTile(String emoji, String label, int days) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(
          '$days days',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '$label Streak',
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Less ', style: TextStyle(fontSize: 10)),
        ...CalendarHeatmap.colors.map(
          (c) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(' More', style: TextStyle(fontSize: 10)),
      ],
    );
  }
}
