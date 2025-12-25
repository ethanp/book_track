import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/my_library/reading_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_buttons.dart';
import 'book_properties_editor.dart';
import 'event_timeline.dart';
import 'formats_section.dart';
import 'progress_chart/progress_chart.dart';

class LibraryBookPage extends ConsumerWidget {
  const LibraryBookPage(this.bookId);

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(userLibraryProvider);
    return libraryAsync.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => CupertinoPageScaffold(
        child: Center(child: Text('Error: $e')),
      ),
      data: (books) {
        final book = books.where((b) => b.supaId == bookId).firstOrNull;
        if (book == null) {
          // Book was deleted, pop back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        return _buildPage(book);
      },
    );
  }

  Widget _buildPage(LibraryBook book) {
    return CupertinoPageScaffold(
      navigationBar: _navBar(book),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookPropertiesEditor(book),
              BookDetailButtons(book),
              ProgressChart(book),
              FormatsSection(book),
              EventTimeline(book),
            ],
          ),
        ),
      ),
    );
  }

  CupertinoNavigationBar _navBar(LibraryBook book) {
    return CupertinoNavigationBar(
      middle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            flex: 5,
            child: Text('${book.book.title} (${book.readingStatus.name})'),
          ),
          Flexible(flex: 2, child: ReadingProgressIndicator(book)),
        ],
      ),
    );
  }
}
