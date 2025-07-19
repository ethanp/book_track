import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/date_axis.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProgressPerMonthChart extends ConsumerWidget {
  ProgressPerMonthChart({required this.books, super.key})
      : deltaByMonth = diffPerMonth(
          books,
          CupertinoColors.systemGreen,
          (book) => book.pagesDiffs(percentage: true),
          'Percent',
        ),
        pagesByMonth = diffPerMonth(
          books.where((b) => !b.isAudiobook).toList(),
          CupertinoColors.systemBlue,
          (book) => book.pagesDiffs(),
          'Pages',
        ),
        minutesByMonth = diffPerMonth(
          books.where((b) => b.isAudiobook).toList(),
          CupertinoColors.systemRed,
          (book) => book.pagesDiffs(),
          'Minutes / 5',
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
    CupertinoDynamicColor color,
    Iterable<MapEntry<DateTime, double>> Function(LibraryBook) getDiffs,
    String name,
  ) =>
      DiffPerMonth(
        color: color,
        data: books
            .expand(getDiffs)
            .fold(<String, double>{}, _sumByMonth)
            .entries
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
        name: name,
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
    return Row(children: [
      lineChart(),
      SizedBox(width: 8),
      chartLegend(),
    ]);
  }

  Widget lineChart() {
    final List<DateTime> eventTimes =
        lineDatas.map((e) => e.data).flatten.mapL((e) => yyyyMM.parse(e.key));
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    const borderSide = BorderSide(color: CupertinoColors.black, width: 2);
    return Flexible(
      child: LineChart(
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
      ),
    );
  }

  Widget chartLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineDatas.mapL((l) => lineKey(color: l.color, label: l.name)),
    );
  }

  Widget lineKey({required Color color, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 10,
              height: 10,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  static FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: progressAxisTitles(shiftTitle: const Offset(20, -10)),
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
      color: dataByMonth.color.withOpacity(0.7),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index) {
          // NB: Before using `xPercentage`, search for it elsewhere
          // in this repo for correction details.
          return FlDotCirclePainter(
            radius: 2,
            color: Color.lerp(
              CupertinoColors.systemBlue.withOpacity(0.7),
              CupertinoColors.systemGrey.withOpacity(0.8),
              .4,
            )!,
            strokeColor: CupertinoColors.black,
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
          CupertinoColors.systemTeal.withOpacity(0.15),
          CupertinoColors.systemBlue.withOpacity(0.04),
        ],
        stops: const [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles progressAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: Transform.translate(
        offset: shiftTitle,
        child: Text('Progress (%)', style: TextStyles.sideAxisLabel),
      ),
      sideTitles: SideTitles(
        interval: horizontalInterval,
        reservedSize: 30,
        showTitles: true,
        getTitlesWidget: (double value, TitleMeta meta) =>
            Text(value.floor().toString(), style: TextStyle(fontSize: 10)),
      ),
      axisNameSize: 22,
    );
  }

  static num monthLength(int month, int year) => //newline
      month == 2
          ? year % 4 == 0
              ? 29
              : 28
          : {9, 4, 6, 11}.contains(month)
              ? 30
              : 31;
}

class DiffPerMonth {
  const DiffPerMonth({
    required this.data,
    required this.color,
    required this.name,
  });

  final List<MapEntry<String, double>> data;
  final CupertinoDynamicColor color;
  final String name;
}
