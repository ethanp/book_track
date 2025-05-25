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

class ProgressPerMonthChart extends ConsumerWidget {
  ProgressPerMonthChart({required this.books, super.key})
      : deltaByMonth = diffPerMonth(
          books,
          Colors.green[900]!,
          (book) => book.progressDiffs,
        ),
        pagesByMonth = diffPerMonth(
          books,
          Colors.blue[900]!,
          (book) => book.pagesDiffs,
        ),
        minutesByMonth = diffPerMonth(
          books,
          Colors.red[900]!,
          (book) => book.fiveMinDiffs,
        );

  final List<LibraryBook> books;

  final DiffPerMonth deltaByMonth;
  final DiffPerMonth pagesByMonth;
  final DiffPerMonth minutesByMonth;

  List<DiffPerMonth> get lineDatas =>
      [deltaByMonth, pagesByMonth, minutesByMonth];

  static final yyyyMM = DateFormat('yyyy-MM');

  static DiffPerMonth diffPerMonth(
    List<LibraryBook> books,
    Color color,
    Iterable<MapEntry<DateTime, double>> Function(LibraryBook) getDiffs,
  ) =>
      DiffPerMonth(
        color: color,
        data: books
            .expand(getDiffs)
            .fold(<String, double>{}, _sumByMonth)
            .entries
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );

  static Map<String, double> _sumByMonth(
    Map<String, double> acc,
    MapEntry<DateTime, double> curr,
  ) {
    final key = yyyyMM.format(curr.key);
    acc[key] = (acc[key] ?? 0.0) + curr.value;
    return acc;
  }

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static final double horizontalInterval = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DateTime> eventTimes =
        lineDatas.map((e) => e.data).flatten.mapL((e) => yyyyMM.parse(e.key));
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    const borderSide = BorderSide(color: Colors.black, width: 2);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: lineDatas.map((e) => e.data).flatten.map((e) => e.value).max,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: FlGridData(
          horizontalInterval: ProgressPerMonthChart.horizontalInterval,
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

  LineChartBarData dataByMonthLine(DiffPerMonth dataByMonth) {
    final DateTime now = DateTime.now();
    final String currMonth = yyyyMM.format(now);
    return LineChartBarData(
      spots: dataByMonth.map((x) => x.data)!.toList().mapL((x) => FlSpot(
          yyyyMM.parse(x.key).millisSinceEpoch,
          // Scale the last point based on how much of the month has
          // elapsed, to make it an "estimate" of the "full" month's data.
          x.key == currMonth
              ? x.value / now.day * monthLength(now.month, now.year)
              : x.value)),
      isCurved: true,
      curveSmoothness: .05,
      belowBarData: gradientFill(),
      color: dataByMonth.color.withValues(alpha: .7),
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

  static num monthLength(int month, int year) => month == 2
      ? year % 4 == 0
          ? 29
          : 28
      : {9, 4, 6, 11}.contains(month)
          ? 30
          : 31;
}

class DiffPerMonth {
  const DiffPerMonth({required this.data, required this.color});

  final List<MapEntry<String, double>> data;
  final Color color;
}
