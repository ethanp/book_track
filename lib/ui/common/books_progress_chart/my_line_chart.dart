import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/date_axis.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BooksProgressChart extends ConsumerWidget {
  const BooksProgressChart({required this.books});

  final List<LibraryBook> books;

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static final double horizontalInterval = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DateTime> eventTimes =
        books.expand((b) => b.progressHistory).mapL((e) => e.end);
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: grid(),
        titlesData: labelAxes(timespan),
        lineBarsData: plotLines(),
        borderData: border(),
      ),
    );
  }

  FlBorderData border() {
    final borderSide = BorderSide(color: Colors.black, width: 2);
    return FlBorderData(
      show: true,
      border: Border(
        left: borderSide,
        bottom: borderSide,
      ),
    );
  }

  FlGridData grid() {
    return FlGridData(
      horizontalInterval: horizontalInterval,
      drawVerticalLine: false,
    );
  }

  static FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: percentageAxisTitles(shiftTitle: Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: DateAxis(timespan).titles(),
      topTitles: noAxisTitles,
    );
  }

  List<LineChartBarData> plotLines() {
    // TODO(ux) If there are multiple spots on a single day, and the whole book's
    //  been read over many days, it would be easier to interpret if we instead
    //  only show the LAST location of each day on the chart, to avoid those
    //  weird and hard-to-interpret vertical blips visuals. Currently I'm just
    //  *deleting* inner daily location updates to make the chart better, but
    //  this is a waste of data that would be nice to collect.
    final readingProgressLine = LineChartBarData(
      spots: books.expand((b) => b.progressHistory).mapL(eventToSpot),
      isCurved: true,
      curveSmoothness: .1,
      belowBarData: gradientFill(),
      gradient: lineGradient(),
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, percent, __, ___) => FlDotCirclePainter(
          radius: percent / 100 / 1.2 + 2,
          color: Color.lerp(
            Colors.blue.withValues(alpha: .7),
            Colors.blueGrey.withValues(alpha: .8),
            percent / 100,
          )!,
          strokeColor: Colors.black,
        ),
      ),
    );
    return [readingProgressLine];
  }

  static LinearGradient lineGradient() {
    return LinearGradient(
      colors: [
        Colors.blue.withValues(alpha: .2),
        Colors.grey[700]!.withValues(alpha: .6),
      ],
      stops: [.4, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          Colors.teal[400]!.withValues(alpha: .7),
          Colors.blue.withValues(alpha: .4)
        ],
        stops: [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles percentageAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: FlutterHelpers.transform(
        shift: shiftTitle,
        child: Text(
          'Percentage',
          style: TextStyles().sideAxisLabel,
        ),
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

  FlSpot eventToSpot(ProgressEvent progressEvent) {
    return FlSpot(
      progressEvent.end.millisecondsSinceEpoch.toDouble(),
      books.first.percentProgressAt(progressEvent)!,
    );
  }
}
