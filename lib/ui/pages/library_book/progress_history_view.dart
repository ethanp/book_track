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
    return Column(children: [
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
    ]);
  }

  Widget? body(List<LibraryBook> library) {
    final Widget deletedNote = Text(
      'The book ${widget.useLocalInstead.book.title} was deleted from '
      'user\'s library. We probably have to pop this screen '
      'now?',
    );
    final LibraryBook? updatedBook = library
        .where((book) => book.supaId == widget.useLocalInstead.supaId)
        .singleOrNull;
    updatedBook.map((book) => _latestBook = book);
    return updatedBook.map(content) ?? deletedNote;
  }

  Widget content(LibraryBook updatedBook) {
    final eventTimes = updatedBook.progressHistory.mapL((e) => e.end);
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    final widget = Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
      child: lineChart(timespan),
    );
    return widget;
  }

  static final double horizontalInterval = 25;

  LineChart lineChart(TimeSpan timespan) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: timespan.beginning.millisecondsSinceEpoch.toDouble(),
        maxX: timespan.end.millisecondsSinceEpoch.toDouble(),
        gridData: grid(timespan),
        titlesData: labelAxes(timespan),
        lineBarsData: plotLines(),
      ),
    );
  }

  FlGridData grid(TimeSpan timespan) {
    return FlGridData(
        checkToShowHorizontalLine: (v) =>
            v == timespan.beginning.millisecondsSinceEpoch.toDouble(),
        horizontalInterval: horizontalInterval,
        verticalInterval: verticalInterval(timespan));
  }

  static double? verticalInterval(TimeSpan timespan) {
    final Duration? intervalDuration =
        timespan.duration < Duration(hours: 10) ? null : Duration(minutes: 30);
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

  List<LineChartBarData> plotLines() {
    final readingProgressLine = LineChartBarData(
      spots: _latestBook.progressHistory.mapL(eventToSpot),
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

  static FlSpot eventToSpot(ProgressEvent p) {
    return FlSpot(
      p.end.millisecondsSinceEpoch.toDouble(),
      p.progress.toDouble(),
    );
  }
}
