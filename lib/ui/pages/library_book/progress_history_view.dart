import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'date_axis.dart';
import 'timespan.dart';

class ProgressHistoryView extends ConsumerStatefulWidget {
  const ProgressHistoryView(this.useLocalInstead);

  final LibraryBook useLocalInstead;

  @override
  ConsumerState createState() => _ProgressHistoryViewState();
}

class _ProgressHistoryViewState extends ConsumerState<ProgressHistoryView> {
  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  late LibraryBook _latestBook;

  @override
  void initState() {
    super.initState();
    _latestBook = widget.useLocalInstead;
  }

  @override
  Widget build(BuildContext context) {
    if (_latestBook.bookLength == null) {
      // TODO(ui) improve the understandability of what this is saying.
      return Text('book length unknown');
    }
    return Card(
      margin: EdgeInsets.only(left: 16, right: 16, top: 28),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(children: [
          Text('History', style: TextStyles().h1),
          if (_latestBook.progressHistory.isEmpty)
            Text('No progress updates yet')
          else
            SizedBox(
                height: 300,
                child: ref.watch(userLibraryProvider).when(
                    loading: () => const CircularProgressIndicator(),
                    error: (err, trace) => Text(err.toString()),
                    data: body))
        ]),
      ),
    );
  }

  Widget? body(List<LibraryBook> library) {
    final LibraryBook? updatedBook = library
        .where((book) => book.supaId == widget.useLocalInstead.supaId)
        .singleOrNull;
    if (updatedBook == null) {
      return Text(
        'The book ${widget.useLocalInstead.book.title} was deleted from '
        'user\'s library. We probably have to pop this screen '
        'now?',
      );
    }
    _latestBook = updatedBook;
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
      child: lineChart(),
    );
  }

  static final double horizontalInterval = 25;

  LineChart lineChart() {
    final eventTimes = _latestBook.progressHistory.mapL((e) => e.end);
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
    //  been read over many days, it would make sense to only show the LAST
    //  spot of each day on the chart, to avoid weird and hard-to-interpret
    //  visuals.
    final readingProgressLine = LineChartBarData(
        spots: _latestBook.progressHistory.mapL(eventToSpot),
        belowBarData: gradientFill(),
        gradient: lineGradient());
    return [readingProgressLine];
  }

  static LinearGradient lineGradient() {
    return LinearGradient(
      colors: [Colors.grey[600]!, Colors.blue.withValues(alpha: .2)],
      stops: [.4, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [Colors.teal[400]!, Colors.blue.withValues(alpha: .2)],
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

  FlSpot eventToSpot(ProgressEvent progressEvent) {
    return FlSpot(
      progressEvent.end.millisecondsSinceEpoch.toDouble(),
      _latestBook.percentProgressAt(progressEvent)!,
    );
  }
}
