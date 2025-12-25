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
    return CupertinoPageScaffold(
      navigationBar: navBar(),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookPropertiesEditor(_libraryBook),
              BookDetailButtons(book: _libraryBook),
              ProgressChart(_libraryBook),
              FormatsSection(_libraryBook),
              EventTimeline(_libraryBook),
            ],
          ),
        ),
      ),
    );
  }

  CupertinoNavigationBar navBar() {
    final currentStatus = _libraryBook.readingStatus.name;
    return CupertinoNavigationBar(
      middle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            flex: 5,
            child: Text('${_libraryBook.book.title} ($currentStatus)'),
          ),
          Flexible(
            flex: 2,
            child: ReadingProgressIndicator(_libraryBook),
          ),
        ],
      ),
    );
  }
}
