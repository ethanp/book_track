import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/smoothed_reading_pace.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

import 'pace_trend.dart';

class const RollingAverageChart({
  required final List<LibraryBook> books,
  final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final smoothedPace = SmoothedReadingPace.fromProgressDeltas(
      books
          .where((book) => book.formats.isNotEmpty)
          .expand((book) => book.progressDiffs),
      periodCutoff: periodCutoff,
    );

    if (smoothedPace.points.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        _currentPace(smoothedPace),
        Expanded(child: PaceTrend(smoothedPace: smoothedPace)),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 40, color: EColors.surfaceRaised),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start reading to see your pace!',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _currentPace(SmoothedReadingPace smoothedPace) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Reading pace: ${smoothedPace.currentPace.keepingTenthsBelowTen}/day',
        style: AppTextStyles.h5,
      ),
    );
  }
}
