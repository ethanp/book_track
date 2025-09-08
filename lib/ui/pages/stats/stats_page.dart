import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/progress_per_month_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Stats')),
      child: ref.userLibrary(body),
    );
  }

  Widget body(List<LibraryBook> userLibrary) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // TODO(feature) add a toggle to show only non-archived books
            ChartCard(
              title: 'Read Lines',
              chart: BooksProgressChart(books: userLibrary),
            ),
            // TODO(feature): Consider making a "running 30 day average" version of
            //  this chart as well. Since reading doesn't happen on a month-cyclic
            //  basis, the "per month" level view is not that helpful. A "Strava
            //  fitness score" sort of "running metric" is a better fit for my
            //  purpose on this.
            ChartCard(
              title: 'Progress per Month',
              chart: ProgressPerMonthChart(books: userLibrary),
            ),
            ChartCard(
              title: 'Recent Stats',
              chart: Card(
                child: Text(
                  'Books read in the past 30 days',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  // TODO(feature): Also display what *percentage* of that book
                  //  has been read over the past 30 days.
                ),
              ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 20),
            child: Text(title, style: TextStyles.h3),
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
