import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_by_period_chart.dart';
import 'package:book_track/ui/pages/stats/rolling_average_chart.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const ProgressChartCard({
  required final List<LibraryBook> books,
  required final StatsPeriod period,
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
                bottom: AppSpacing.md,
                left: AppSpacing.lg,
              ),
              child: Text('Reading Progress', style: AppTextStyles.h3),
            ),
          ),
          _chartAndCaptionPanel(
            'Rolling Average',
            RollingAverageChart(books: books, periodCutoff: period.cutoffDate),
          ),
          _chartAndCaptionPanel(
            period.chartAggregation.name.capitalize,
            ProgressByPeriodChart(books: books, period: period),
          ),
        ],
      ),
    );
  }

  Widget _chartAndCaptionPanel(String label, Widget chart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: EColors.border),
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
