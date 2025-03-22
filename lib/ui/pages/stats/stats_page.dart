import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:flutter/cupertino.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 200),
      child: BooksProgressChart(books: userLibrary),
    );
  }
}
