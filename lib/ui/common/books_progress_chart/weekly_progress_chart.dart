import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/date_axis.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklyProgressChart extends ConsumerWidget {
  WeeklyProgressChart({required this.books});

  final List<LibraryBook> books;

  // Technically this is dangerous since stateless widgets should be immutable.
  // Not sure if this is actually problematic in practice in this case though.
  late List<MapEntry<DateTime, double>> deltaByDate = books
      .expand((b) => b.progressDiffs)
      .fold(
        <DateTime, double>{},
        (Map<DateTime, double> acc, MapEntry<DateTime, double> elem) => acc
          ..update(
            elem.key,
            (v) => v + elem.value,
            ifAbsent: () => elem.value,
          ),
      )
      .entries
      .toList()
    ..sortOn((a) => a.key);

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static final double horizontalInterval = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DateTime> eventTimes = deltaByDate.mapL((e) => e.key);
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    const borderSide = BorderSide(color: Colors.black, width: 2);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: deltaByDate.map((e) => e.value).max,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: FlGridData(
          horizontalInterval: WeeklyProgressChart.horizontalInterval,
          drawVerticalLine: false,
        ),
        titlesData: labelAxes(timespan),
        lineBarsData: plotLines(),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: borderSide,
            bottom: borderSide,
          ),
        ),
      ),
    );
  }

  static FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: progressAxisTitles(shiftTitle: Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: DateAxis(timespan).titles(),
      topTitles: noAxisTitles,
    );
  }

  List<LineChartBarData> plotLines() {
    return [
      LineChartBarData(
        spots: deltaByDate.mapL(
          (x) => FlSpot(
            x.key.millisSinceEpoch,
            x.value,
          ),
        ),
        isCurved: true,
        curveSmoothness: .05,
        belowBarData: gradientFill(),
        color: Colors.grey[700]!.withValues(alpha: .7),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, xPercentage, bar, index) {
            // Based on a close reading, the fl_chart code for setting
            // `xPercentage` is incorrect. Search for "xPercentage" elsewhere
            // in this repo for correction details.
            return FlDotCirclePainter(
              radius: 2,
              color: Color.lerp(
                Colors.blue.withValues(alpha: .7),
                Colors.blueGrey.withValues(alpha: .8),
                .4,
              )!,
              strokeColor: Colors.black,
            );
          },
        ),
      )
    ];
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          Colors.teal[400]!.withValues(alpha: .15),
          Colors.blue.withValues(alpha: .04)
        ],
        stops: [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles progressAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: FlutterHelpers.transform(
        shift: shiftTitle,
        child: Text('Progress (%)', style: TextStyles().sideAxisLabel),
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
}
