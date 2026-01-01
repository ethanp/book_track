import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/async_stats_card.dart';
import 'package:book_track/ui/pages/stats/calendar_heatmap.dart';
import 'package:flutter/cupertino.dart';

class ActivityCalendarCard extends StatelessWidget {
  const ActivityCalendarCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context) {
    return AsyncStatsCard<ReadingActivityData>(
      cacheKey: '${books.length}-${periodCutoff?.millisecondsSinceEpoch ?? 0}',
      compute: () => ReadingActivityData.fromProgress(
        books,
        periodCutoff: periodCutoff,
      ),
      loadingHeight: 200,
      builder: _buildCard,
    );
  }

  Widget _buildCard(ReadingActivityData data) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarHeatmap(
              activityByDay: data.activityByDay,
              books: books,
              periodCutoff: periodCutoff,
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
