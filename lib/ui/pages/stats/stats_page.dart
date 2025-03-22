import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
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
    return SafeArea(child: AllBooksLineChartCard(userLibrary));
  }
}

class AllBooksLineChartCard extends StatelessWidget {
  const AllBooksLineChartCard(this.userLibrary);

  final List<LibraryBook> userLibrary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 20),
            child: Text(
              'Progress across all books ever',
              style: TextStyles().h3,
            ),
          ),
          SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 35, bottom: 14),
              child: BooksProgressChart(books: userLibrary),
            ),
          ),
        ],
      ),
    );
  }
}
