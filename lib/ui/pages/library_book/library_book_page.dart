import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_buttons.dart';
import 'book_properties_editor.dart';
import 'progress_history_view.dart';

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
    ref
        .watch(userLibraryProvider)
        // TODO(optimize) this setState may be redundant or even harmful.
        //  Gotta test it out.
        .whenData((items) => setState(() {
              bool isShownBook(LibraryBook i) =>
                  i.supaId == widget.libraryBook.supaId;
              _libraryBook = items.where(isShownBook).first;
            }));
    // TODO(optimize) Is this guy necessary? Probably not?
    setState(() {});
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_libraryBook.book.title),
      ),
      child: SafeArea(
        child: Column(
          children: [
            BookPropertiesEditor(_libraryBook),
            BookDetailButtons(book: _libraryBook),
            historyChart(),
          ],
        ),
      ),
    );
  }

  Widget historyChart() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ProgressHistoryView(_libraryBook),
      ),
    );
  }
}
