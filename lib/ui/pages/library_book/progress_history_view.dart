import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'date_axis.dart';
import 'timespan.dart';

class ProgressHistoryView extends StatelessWidget {
  const ProgressHistoryView(this.bookProgress);

  final LibraryBook bookProgress;
  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  @override
  Widget build(BuildContext context) {
    final List<ProgressEvent> progressEvents =
        bookProgress.progressHistory.progressEvents;

    return Column(
      children: [
        Text('History', style: TextStyles().h1),
        if (progressEvents.isEmpty)
          Text('No progress updates yet')
        else
          SizedBox(height: 300, child: flLineChart(progressEvents)),
      ],
    );
  }

  static final double horizontalInterval = 25;

  Widget flLineChart(List<ProgressEvent> progressEvents) {
    final Iterable<DateTime> eventTimes = progressEvents.map((e) => e.end);
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

  static double? verticalInterval(TimeSpan timespan) {
    final Duration? intervalDuration =
        timespan.duration < Duration(hours: 10) ? null : Duration(minutes: 30);
    print('vertical interval $intervalDuration');
    return intervalDuration?.inMilliseconds.toDouble();
  }

  static FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: percentageAxisTitles(shiftTitle: Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles:
          DateAxis(timespan, verticalInterval(timespan)).dateAxisTitles(),
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

  static FlSpot eventToSpot(ProgressEvent p) {
    return FlSpot(
      p.end.millisecondsSinceEpoch.toDouble(),
      p.progress.toDouble(),
    );
  }

  static List<ProgressEvent> fakeProgress() {
    return [
      DateTime(2024, 1, 1, 0, 0),
      DateTime(2024, 1, 1, 1, 10),
      DateTime(2024, 1, 1, 3, 20),
    ].zipWithIndex.mapL(
          (e) => ProgressEvent(
            end: e.elem,
            progress: 10 * e.idx,
            format: ProgressEventFormat.percent,
          ),
        );
  }
}
