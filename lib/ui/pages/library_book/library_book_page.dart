import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_buttons.dart';
import 'book_properties_editor.dart';
import 'event_timeline.dart';
import 'progress_chart/progress_chart.dart';

class LibraryBookPage extends ConsumerStatefulWidget {
  const LibraryBookPage(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  ConsumerState createState() => _LibraryBookPageState();
}

class _LibraryBookPageState extends ConsumerState<LibraryBookPage> {
  late LibraryBook _libraryBook;

  @override
  void initState() {
    super.initState();
    _libraryBook = widget.libraryBook;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userLibraryProvider).whenData((items) {
      bool isShownBook(LibraryBook i) => i.supaId == widget.libraryBook.supaId;
      _libraryBook = items.where(isShownBook).first;
    });
    final subtitle =
        _libraryBook.statusHistory.lastOrNull?.status.name ?? 'no status';
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${_libraryBook.book.title} ($subtitle)'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookPropertiesEditor(_libraryBook),
              BookDetailButtons(book: _libraryBook),
              ProgressChart(_libraryBook),
              EventTimeline(_libraryBook),
            ],
          ),
        ),
      ),
    );
  }
}
