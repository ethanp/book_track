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

class ProgressChart extends ConsumerStatefulWidget {
  const ProgressChart(this.useOnlyForInitializing);

  final LibraryBook useOnlyForInitializing;

  @override
  ConsumerState createState() => _ProgressChartState();
}

class _ProgressChartState extends ConsumerState<ProgressChart> {
  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  late LibraryBook _latestBook;

  @override
  void initState() {
    super.initState();
    _latestBook = widget.useOnlyForInitializing;
  }

  @override
  Widget build(BuildContext context) {
    if (_latestBook.bookLength == null) {
      // TODO(ux,feature) Instead of letting it be unknown, force the user
      //  to set something when adding the book to library.
      return Text("This book's length is unknown. Update it above.");
    }
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 28),
      color: Colors.grey[100],
      elevation: 0.2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(children: [
          Text('Progress', style: TextStyles().h2),
          _latestBook.progressHistory.isEmpty
              ? Text('No progress updates yet')
              : SizedBox(
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
        .where((book) => book.supaId == widget.useOnlyForInitializing.supaId)
        .singleOrNull;
    if (updatedBook == null) {
      return Text(
        'The book ${widget.useOnlyForInitializing.book.title} '
        'has been deleted from your library. '
        'We probably have to pop this screen now?',
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
    //  been read over many days, it would be easier to interpret if we instead
    //  only show the LAST location of each day on the chart, to avoid those
    //  weird and hard-to-interpret vertical blips visuals. Currently I'm just
    //  *deleting* inner daily location updates to make the chart better, but
    //  this is a waste of data that would be nice to collect.
    final readingProgressLine = LineChartBarData(
      spots: _latestBook.progressHistory.mapL(eventToSpot),
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
      _latestBook.percentProgressAt(progressEvent)!,
    );
  }
}
