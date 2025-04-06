import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/date_axis.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DeltaProgressChart extends ConsumerWidget {
  DeltaProgressChart({required this.books, super.key})
      : deltaByMonth = _calculateDeltaByMonth(books),
        pagesByMonth = _calculatePagesByMonth(books),
        minutesByMonth = _calculateMinutesByMonth(books);

  final List<LibraryBook> books;

  // TODO(cleanup): Convert these fields into getters/methods?
  final List<MapEntry<String, double>> deltaByMonth;
  final List<MapEntry<String, double>> pagesByMonth;
  final List<MapEntry<String, double>> minutesByMonth;

  List<List<MapEntry<String, double>>> get lineDatas =>
      [deltaByMonth, pagesByMonth, minutesByMonth];
  static final yyMmFormat = DateFormat('yyyy-MM');

  static List<MapEntry<String, double>> _calculateDeltaByMonth(
          List<LibraryBook> books) =>
      books
          .expand((b) => b.progressDiffs)
          .fold(<String, double>{}, _sumByMonth)
          .entries
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  static List<MapEntry<String, double>> _calculatePagesByMonth(
          List<LibraryBook> books) =>
      books
          .expand((b) => b.pagesDiffs)
          .fold(<String, double>{}, _sumByMonth)
          .entries
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  static List<MapEntry<String, double>> _calculateMinutesByMonth(
          List<LibraryBook> books) =>
      books
          // TODO(incomplete): Implement b.minutesDiffs to use here instead.
          .expand((b) => b.progressDiffs)
          .fold(<String, double>{}, _sumByMonth)
          .entries
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  static Map<String, double> _sumByMonth(
    Map<String, double> acc,
    MapEntry<DateTime, double> curr,
  ) {
    final key = yyMmFormat.format(curr.key);
    acc[key] = (acc[key] ?? 0.0) + curr.value;
    return acc;
  }

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static final double horizontalInterval = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DateTime> eventTimes =
        deltaByMonth.mapL((e) => yyMmFormat.parse(e.key));
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    const borderSide = BorderSide(color: Colors.black, width: 2);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: deltaByMonth.map((e) => e.value).max,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: FlGridData(
          horizontalInterval: DeltaProgressChart.horizontalInterval,
          drawVerticalLine: false,
        ),
        titlesData: labelAxes(timespan),
        lineBarsData: lineDatas.mapL(dataByMonthLine),
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

  LineChartBarData dataByMonthLine(List<MapEntry<String, double>> dataByMonth) {
    return LineChartBarData(
      spots: dataByMonth.mapL(
        (x) => FlSpot(
          yyMmFormat.parse(x.key).millisSinceEpoch,
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
          // NB: Before using `xPercentage`, search for it elsewhere
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
    );
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
