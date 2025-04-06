import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/books_progress_chart/progress_per_month_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Stats')),
      child: ref.userLibrary(body),
    );
  }

  Widget body(List<LibraryBook> userLibrary) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            ChartCard(
              title: 'Read Lines',
              chart: BooksProgressChart(books: userLibrary),
            ),
            ChartCard(
              title: 'Progress per Month',
              chart: ProgressPerMonthChart(books: userLibrary),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.chart,
  });

  final String title;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 20),
            child: Text(title, style: TextStyles().h3),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}
