import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/smoothed_reading_pace.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        Expanded(child: _PaceTrend(smoothedPace: smoothedPace)),
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
        'Reading pace: ${_paceKeepingTenthsBelowTen(smoothedPace.currentPace)}/day',
        style: AppTextStyles.h5,
      ),
    );
  }
}

class const _PaceTrend({required final SmoothedReadingPace smoothedPace})
    extends StatefulWidget {
  @override
  State<_PaceTrend> createState() => _PaceTrendState();
}

class _PaceTrendState() extends State<_PaceTrend> {
  EChartSelectedPoint? _hoveredPoint;

  @override
  Widget build(BuildContext context) {
    final line = EChartLine(
      points: [
        for (final point in widget.smoothedPace.points)
          EChartPoint(date: point.day, value: point.percentPerDay),
      ],
      color: EColors.success,
      strokeWidth: 2,
      showDots: false,
      fillColor: EColors.success.withValues(alpha: 0.2),
    );
    return Stack(
      children: [
        EChart(
          lines: [line],
          valueScale: EChartValueScale.nice(
            widget.smoothedPace.maxPace,
            tickSuffix: '%',
          ),
          start: widget.smoothedPace.points.first.day,
          end: widget.smoothedPace.points.last.day,
          onHoveredPoint: (point) => setState(() => _hoveredPoint = point),
        ),
        if (_hoveredPoint != null) _hoverCaption(_hoveredPoint!),
      ],
    );
  }

  Widget _hoverCaption(EChartSelectedPoint hovered) {
    final dateStr = DateFormat('MMM d, yyyy').format(hovered.point.date);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EColors.backgroundLift.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: EColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '$dateStr · ${_paceKeepingTenthsBelowTen(hovered.point.value)}/day',
              style: AppTextStyles.caption,
            ),
          ),
        ),
      ),
    );
  }
}

String _paceKeepingTenthsBelowTen(double value) =>
    value >= 10 ? '${value.round()}%' : '${value.toStringAsFixed(1)}%';
