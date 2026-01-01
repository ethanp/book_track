import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_per_month_chart.dart';
import 'package:book_track/ui/pages/stats/rolling_average_chart.dart';
import 'package:flutter/cupertino.dart';

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

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
            padding: const EdgeInsets.only(top: 18, bottom: 12),
            child: Text('Reading Progress', style: TextStyles.h3),
          ),
          _chartSection(
            'Rolling Average',
            RollingAverageChart(
              books: books,
              periodCutoff: periodCutoff,
            ),
          ),
          _chartSection(
            'Monthly',
            ProgressPerMonthChart(
              books: books,
              periodCutoff: periodCutoff,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartSection(String label, Widget chart) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
            child: chart,
          ),
        ),
      ],
    );
  }
}
