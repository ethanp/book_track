import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/timespan.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DateAxis {
  const DateAxis(this.timespan, this.verticalInterval);

  final TimeSpan timespan;
  final double? verticalInterval;

  AxisTitles dateAxisTitles() {
    return AxisTitles(
      axisNameWidget: dateAxisName(),
      sideTitles: dateAxisSideTitles(),
      axisNameSize: 24,
    );
  }

  Widget dateAxisName() {
    final String text = timespan.beginning.sameDayAs(timespan.end)
        ? '(${TimeHelpers.monthDayYear(timespan.beginning)})'
        : 'Starting ${TimeHelpers.monthDayYear(timespan.beginning)}';
    final TextStyle style = TextStyles().h2Skinny.copyWith(fontSize: 17);

    return FlutterHelpers.transform(
      shift: Offset(20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Date', style: TextStyles().bottomAxisLabel),
          Padding(
            padding: const EdgeInsets.only(top: 2.9, left: 20),
            child: Text(text, style: style),
          ),
        ],
      ),
    );
  }

  SideTitles dateAxisSideTitles() {
    return SideTitles(
      showTitles: true,
      reservedSize: 36,
      interval: verticalInterval,
      getTitlesWidget: (double value, TitleMeta meta) {
        return FlutterHelpers.transform(
          shift: Offset(8, 0),
          angleDegrees: 35,
          child: dateText(value),
        );
      },
    );
  }

  Widget dateText(double value) {
    final formatter = timespan.duration > Duration(days: 2)
        ? TimeHelpers.monthDayYear
        : TimeHelpers.hourMinuteAmPm;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    final dateString = formatter(dateTime);
    return Text(dateString, style: TextStyle(letterSpacing: -.4, fontSize: 11));
  }
}
