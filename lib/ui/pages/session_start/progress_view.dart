import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressView extends StatelessWidget {
  const ProgressView(
    this.book,
  );

  final BookProgress book;
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

    final Iterable<DateTime> eventTimes = progressEvents.map((e) => e.dateTime);
    final DateTime earliestEvent = eventTimes.min;
    final DateTime latestEvent = eventTimes.max;
    final Duration timespan = latestEvent.difference(earliestEvent);
    final bool labelInDaysNotHours = timespan > Duration(days: 2);

    return Column(
      children: [
        Text('History', style: TextStyles().h1),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: 100,
              minX: earliestEvent.millisecondsSinceEpoch.toDouble(),
              maxX: latestEvent.millisecondsSinceEpoch.toDouble(),
              titlesData: FlTitlesData(
                leftTitles: percentageAxisTitles(shiftTitle: Offset(20, -10)),
                rightTitles: percentageAxisTitles(shiftTitle: Offset(15, -2)),
                bottomTitles: dateAxisTitles(labelInDaysNotHours),
                topTitles: noAxisTitles,
              ),
              lineBarsData: [
                LineChartBarData(spots: progressEvents.mapL(eventToSpot)),
              ],
            )),
          ),
        ),
        Table(
          children: progressEvents.mapL((ev) {
            return TableRow(children: [
              Text(dateFormatter.format(ev.dateTime)),
              Text(timeFormatter.format(ev.dateTime)),
              Text('${ev.progress}%'),
            ]);
          }),
        ),
      ],
    );
  }

  static AxisTitles percentageAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: transform(shift: shiftTitle, child: Text('Percentage')),
      sideTitles: SideTitles(
        interval: 25,
        showTitles: true,
        getTitlesWidget: (double value, TitleMeta meta) =>
            Text(value.floor().toString()),
      ),
    );
  }

  static AxisTitles dateAxisTitles(bool labelInDaysNotHours) {
    return AxisTitles(
      axisNameWidget: dateAxisName(),
      sideTitles: dateAxisSideTitles(labelInDaysNotHours),
    );
  }

  static SideTitles dateAxisSideTitles(bool labelInDaysNotHours) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        return transform(
          shift: Offset(18, 13),
          angleDegrees: 35,
          child: dateText(value, labelInDaysNotHours),
        );
      },
    );
  }

  static Text dateText(double value, bool labelInDaysNotHours) {
    final formatter = labelInDaysNotHours ? dateFormatter : timeFormatter;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.floor());
    final dateString = formatter.format(dateTime);
    return Text(dateString, style: TextStyle(letterSpacing: -.4, fontSize: 11));
  }

  static Widget dateAxisName() {
    return transform(
      shift: Offset(0, 20),
      child: Text(
        'Date',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
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
