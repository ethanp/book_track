import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/books_progress_chart/my_line_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressChart extends ConsumerStatefulWidget {
  const ProgressChart(this.useOnlyForInitializing);

  final LibraryBook useOnlyForInitializing;

  @override
  ConsumerState createState() => _ProgressChartState();
}

class _ProgressChartState extends ConsumerState<ProgressChart> {
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
    // I think I don't need to setState here since I'm already in the
    // `watch` callback.
    _latestBook = updatedBook;
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
      child: BooksProgressChart(books: [_latestBook]),
    );
  }
}
