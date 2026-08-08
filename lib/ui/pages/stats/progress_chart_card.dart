import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_per_month_chart.dart';
import 'package:book_track/ui/pages/stats/rolling_average_chart.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({required this.books, required this.period});

  final List<LibraryBook> books;
  final StatsPeriod period;

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
                bottom: AppSpacing.md,
                left: AppSpacing.lg,
              ),
              child: Text('Reading Progress', style: AppTextStyles.h3),
            ),
          ),
          _chartSection(
            'Rolling Average',
            RollingAverageChart(
              books: books,
              periodCutoff: period.cutoffDate,
            ),
          ),
          _chartSection(
            period.chartAggregation.name.capitalize,
            ProgressPerMonthChart(
              books: books,
              period: period,
            ),
          ),
        ],
      ),
    );
  }

  /// Each chart lives in its own bounding panel so a chart and its caption
  /// (e.g. the rolling average's "Reading pace" line) read as one unit,
  /// clearly separated from the chart below it.
  Widget _chartSection(String label, Widget chart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.h5),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}
