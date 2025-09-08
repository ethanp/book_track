import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DateAxis {
  const DateAxis(this.timespan);

  final TimeSpan timespan;

  AxisTitles titles() {
    return AxisTitles(
      axisNameWidget: dateAxisName(),
      sideTitles: dateTextLabels(),
      axisNameSize: 24,
    );
  }

  Widget dateAxisName() {
    return FlutterHelpers.transform(
      shift: Offset(20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Date', style: TextStyles.sideAxisLabel),
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 10),
            child: Text(
              'Starting ${TimeHelpers.monthDayYear(timespan.beginning)}',
              style: TextStyles.sideAxisLabelThin,
            ),
          ),
        ],
      ),
    );
  }

  SideTitles dateTextLabels() {
    return SideTitles(
      showTitles: true,
      reservedSize: 36,
      interval: verticalInterval.inMilliseconds.toDouble(),
      getTitlesWidget: (double value, TitleMeta _) {
        return FlutterHelpers.transform(
          shift: Offset(8, 0),
          angleDegrees: 35,
          child: dateText(value),
        );
      },
    );
  }

  Duration get verticalInterval {
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
    final formatter = verticalInterval >= Duration(days: 1)
        ? TimeHelpers.monthDayYear
        : TimeHelpers.hourMinuteAmPm;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    return Text(
      formatter(dateTime),
      style: TextStyle(letterSpacing: -.4, fontSize: 10),
    );
  }
}

class MonthAxis {
  const MonthAxis(this.timespan);

  final TimeSpan timespan;

  AxisTitles titles() {
    return AxisTitles(
      axisNameWidget: monthAxisName(),
      sideTitles: monthTextLabels(),
      axisNameSize: 24,
    );
  }

  Widget monthAxisName() {
    return FlutterHelpers.transform(
      shift: Offset(20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Month', style: TextStyles.sideAxisLabel),
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 10),
            child: Text(
              'Starting ${TimeHelpers.monthDayYear(timespan.beginning)}',
              style: TextStyles.sideAxisLabelThin,
            ),
          ),
        ],
      ),
    );
  }

  SideTitles monthTextLabels() {
    return SideTitles(
      showTitles: true,
      minIncluded: false,
      maxIncluded: true,
      reservedSize: 26,
      interval: Duration(days: 1).inMilliseconds.toDouble(),
      getTitlesWidget: (double value, TitleMeta c) {
        if (DateTime.fromMillisecondsSinceEpoch(value.toInt()).day == 1)
          return FlutterHelpers.transform(
            shift: Offset(2, 2),
            angleDegrees: 35,
            child: dateText(value),
          );
        else
          return SizedBox.shrink();
      },
    );
  }

  Widget dateText(double value) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    return Text(
      TimeHelpers.monthNameAbbr(dateTime),
      style: TextStyle(letterSpacing: -.4, fontSize: 10),
    );
  }
}
