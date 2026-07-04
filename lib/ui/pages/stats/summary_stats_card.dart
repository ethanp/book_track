import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/summary_stats.dart';
import 'package:ethan_utils/ethan_utils.dart';
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
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _title(),
          _statusRow(stats),
          _totalsAndStreakRow(stats),
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
          bottom: AppSpacing.lg,
          left: AppSpacing.lg,
        ),
        child: Text('Your Reading Stats', style: AppTextStyles.h3),
      ),
    );
  }

  Widget _statusRow(SummaryStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
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

  Widget _totalsAndStreakRow(SummaryStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statTile(_formatNumber(stats.totalPages), 'pages read'),
          _statTile('${stats.totalHours}h', 'listened'),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
        if (dateRange != null && dateRange.isNotEmpty)
          Text(
            dateRange,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
      ],
    );
  }

  Widget _statTile(String statValue, String label) {
    return Column(
      children: [
        Text(
          statValue,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
