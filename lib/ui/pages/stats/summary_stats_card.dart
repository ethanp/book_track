import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/summary_stats.dart';
import 'package:flutter/cupertino.dart';

class SummaryStatsCard extends StatelessWidget {
  const SummaryStatsCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    return AsyncStatsCard<SummaryStats>(
      cacheKey: '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}',
      compute: () => SummaryStats.calculate(books, periodCutoff),
      loadingHeight: 180,
      builder: (stats) => _buildCard(stats),
    );
  }

  Widget _buildCard(SummaryStats stats) {
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
          _totalsRow(stats),
          _streakRow(stats),
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

  Widget _statusRow(SummaryStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final status in ReadingStatus.values)
            _statTile(
              stats.statusCounts[status].toString(),
              status.nameAsCapitalizedWords,
            ),
        ],
      ),
    );
  }

  Widget _totalsRow(SummaryStats stats) {
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

  Widget _streakRow(SummaryStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _streakTile('Current Streak', stats.currentStreak, null),
          _streakTile('Longest Streak', stats.longestStreak,
              stats.longestStreakDateRange),
        ],
      ),
    );
  }

  Widget _streakTile(String label, int days, String? dateRange) {
    return Column(
      children: [
        Text(
          '$days days',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        if (dateRange != null && dateRange.isNotEmpty)
          Text(
            dateRange,
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
          ),
      ],
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
}
