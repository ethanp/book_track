import 'package:book_track/ui/common/books_progress_chart/chart_axis_label.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/progress_event_date_caption.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class const DateAxis(final TimeSpan timespan) {
  AxisTitles titles() {
    return AxisTitles(
      axisNameWidget: dateAxisName(),
      sideTitles: dateTextLabels(),
      axisNameSize: 24,
    );
  }

  Widget dateAxisName() {
    return ChartAxisLabel.nudgedIntoPlot(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Date', style: AppTextStyles.sideAxisLabel),
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 10),
            child: Text(
              'Starting ${timespan.beginning.slashMonthDayYear}',
              style: AppTextStyles.sideAxisLabelThin,
            ),
          ),
        ],
      ),
      shift: Offset(20, 0),
    );
  }

  SideTitles dateTextLabels() {
    return SideTitles(
      showTitles: true,
      reservedSize: 36,
      interval: dateTickSpacing.inMilliseconds.toDouble(),
      getTitlesWidget: (double value, TitleMeta _) {
        return ChartAxisLabel.tiltedToClearNeighbors(
          dateText(value),
          shift: Offset(8, 0),
          angleDegrees: 35,
        );
      },
    );
  }

  Duration get dateTickSpacing {
    if (timespan.duration < Duration(hours: 10))
      return Duration(minutes: 30);
    else if (timespan.duration < Duration(days: 1))
      return Duration(hours: 3);
    else if (timespan.duration < Duration(days: 21))
      return Duration(days: 1);
    else if (timespan.duration < Duration(days: 40))
      return Duration(days: 7);
    else
      return Duration(days: 30);
  }

  Widget dateText(double value) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    final caption = dateTickSpacing >= Duration(days: 1)
        ? dateTime.slashMonthDayYear
        : dateTime.hourMinuteAmPm;
    return Text(
      caption,
      style: TextStyle(letterSpacing: -.4, fontSize: 10),
    );
  }
}
