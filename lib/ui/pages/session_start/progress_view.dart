import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/design.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('History', style: TextStyles.h1),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(lineBarsData: [
              LineChartBarData(spots: [FlSpot(0, 0), FlSpot(1, 1)]),
            ])),
          ),
        ),
        Table(
          children: book.progressHistory.progressEvents.mapL((ev) {
            final String date = dateFormatter.format(ev.dateTime);
            final String time = timeFormatter.format(ev.dateTime);
            return TableRow(children: [
              Text(date),
              Text(time),
              Text('${ev.progress}%'),
            ]);
          }),
        ),
      ],
    );
  }
}
