import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressHistoryView extends StatelessWidget {
  const ProgressHistoryView(this.bookProgress);

  final BookProgress bookProgress;
  static final dateFormatter = DateFormat('MMM d, y');
  static final timeFormatter = DateFormat('h:mma');
  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  @override
  Widget build(BuildContext context) {
    final List<ProgressEvent> progressEvents =
        // TODO enable this real code instead of the fake crap.
        // book.progressHistory.progressEvents;
        fakeProgress();

    return Column(
      children: [
        Text('History', style: TextStyles().h1),
        SizedBox(height: 300, child: flLineChart(progressEvents)),
      ],
    );
  }

  static final double horizontalInterval = 25;

  Widget flLineChart(List<ProgressEvent> progressEvents) {
    final Iterable<DateTime> eventTimes = progressEvents.map((e) => e.dateTime);
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: timespan.beginning.millisecondsSinceEpoch.toDouble(),
          maxX: timespan.end.millisecondsSinceEpoch.toDouble(),
          gridData: FlGridData(
              horizontalInterval: horizontalInterval,
              verticalInterval: verticalInterval(timespan)),
          titlesData: labelAxes(timespan),
          lineBarsData: plotLines(progressEvents),
        ),
      ),
    );
  }

  static double? verticalInterval(TimeSpan timespan) =>
      timespan.duration > Duration(hours: 10)
          ? null
          : Duration(minutes: 30).inMilliseconds.toDouble();

  FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: percentageAxisTitles(shiftTitle: Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: dateAxisTitles(timespan),
      topTitles: noAxisTitles,
    );
  }

  List<LineChartBarData> plotLines(List<ProgressEvent> progressEvents) {
    final readingProgressLine = LineChartBarData(
      spots: progressEvents.mapL(eventToSpot),
      belowBarData: gradientFill(),
    );
    return [readingProgressLine];
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          Colors.blue.withOpacity(1),
          Colors.blue.withOpacity(.2),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles percentageAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: transform(
        shift: shiftTitle,
        child: Text('Percentage', style: TextStyles().sideAxisLabel),
      ),
      sideTitles: SideTitles(
        interval: horizontalInterval,
        reservedSize: 30,
        showTitles: true,
        getTitlesWidget: (double value, TitleMeta meta) =>
            Text(value.floor().toString()),
      ),
      axisNameSize: 22,
    );
  }

  static AxisTitles dateAxisTitles(TimeSpan timespan) {
    return AxisTitles(
      axisNameWidget: transform(
        shift: Offset(20, 0),
        child: Text('Date', style: TextStyles().bottomAxisLabel),
      ),
      sideTitles: dateAxisSideTitles(timespan),
      axisNameSize: 24,
    );
  }

  static SideTitles dateAxisSideTitles(TimeSpan timespan) {
    return SideTitles(
      showTitles: true,
      reservedSize: 36,
      interval: verticalInterval(timespan),
      getTitlesWidget: (double value, TitleMeta meta) {
        return transform(
          shift: Offset(8, 0),
          angleDegrees: 35,
          child: dateText(value, timespan),
        );
      },
    );
  }

  static Text dateText(double value, TimeSpan timespan) {
    final formatter =
        timespan.duration > Duration(days: 2) ? dateFormatter : timeFormatter;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    final dateString = formatter.format(dateTime);
    return Text(dateString, style: TextStyle(letterSpacing: -.4, fontSize: 11));
  }

  static Widget dateAxisName() {
    return Text(
      'Date',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static FlSpot eventToSpot(ProgressEvent p) {
    return FlSpot(
      p.dateTime.millisecondsSinceEpoch.toDouble(),
      p.progress.toDouble(),
    );
  }

  static Widget transform({
    Offset? shift,
    double? angleDegrees,
    required Widget child,
  }) {
    Widget ret = child;
    if (shift != null) {
      ret = Transform.translate(offset: shift, child: ret);
    }
    if (angleDegrees != null) {
      ret = Transform.rotate(angle: angleDegrees.deg2rad, child: ret);
    }
    return ret;
  }

  static List<ProgressEvent> fakeProgress() {
    final date1 = DateTime(2024, 1, 1, 0, 0);
    final date2 = DateTime(2024, 1, 1, 1, 10);
    final date3 = DateTime(2024, 1, 1, 3, 20);
    return [date1, date2, date3].zipWithIndex.mapL(
        (e) => ProgressEvent(e.elem, 10 * e.idx, ProgressEventFormat.percent));
  }
}

class TimeSpan {
  TimeSpan({
    required this.beginning,
    required this.end,
  }) : duration = beginning.difference(end);

  final DateTime beginning;
  final DateTime end;
  final Duration duration;
}
