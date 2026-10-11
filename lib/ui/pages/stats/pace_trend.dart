import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/smoothed_reading_pace.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class const PaceTrend({required final SmoothedReadingPace smoothedPace})
    extends StatefulWidget {
  @override
  State<PaceTrend> createState() => _PaceTrendState();
}

class _PaceTrendState() extends State<PaceTrend> {
  EChartSelectedPoint<DateTime>? _hoveredPoint;

  @override
  Widget build(BuildContext context) {
    final paceSeries = EChartSeries.line(
      id: 'pace',
      points: [
        for (final point in widget.smoothedPace.points)
          EChartPoint(
            date: point.day,
            value: point.percentPerDay,
            id: point.day,
          ),
      ],
      color: EColors.success,
      strokeWidth: 2,
      fillColor: EColors.success.withValues(alpha: 0.2),
    );
    return Stack(
      children: [
        EChart<DateTime>(
          series: [paceSeries],
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

  Widget _hoverCaption(EChartSelectedPoint<DateTime> hovered) {
    final dateStr = DateFormat('MMM d, yyyy').format(hovered.date);
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
              '$dateStr · ${hovered.value.keepingTenthsBelowTen}/day',
              style: AppTextStyles.caption,
            ),
          ),
        ),
      ),
    );
  }
}

extension ReadingPaceCaption on double {
  String get keepingTenthsBelowTen =>
      this >= 10 ? '${round()}%' : '${toStringAsFixed(1)}%';
}
