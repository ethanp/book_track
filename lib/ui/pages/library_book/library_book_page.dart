import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/session_timer/session_timer_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_button.dart';
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
            buttons(context),
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

  Widget buttons(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          updateProgress(context),
          complete(),
          abandon(),
          startSession(context),
        ],
      ),
    );
  }

  Widget updateProgress(BuildContext context) {
    return BookDetailButton(
      text: 'Update progress',
      subtitle: 'Sync with reality',
      icon: Icons.list_alt_outlined,
      onPressed: () async {
        await showCupertinoDialog(
          context: context,
          builder: (context) => UpdateProgressDialogPage(book: _libraryBook),
        );
      },
      backgroundColor: Colors.pink[100]!.withOpacity(.75),
    );
  }

  Widget complete() {
    return BookDetailButton(
      text: 'Complete',
      subtitle: 'Mark book as finished',
      icon: Icons.check_box_outlined,
      onPressed: () {},
      backgroundColor: Colors.green[300]!.withOpacity(.6),
    );
  }

  Widget abandon() {
    return BookDetailButton(
      text: 'Abandon',
      subtitle: 'Stop reading this book',
      icon: Icons.remove_circle_outline_outlined,
      onPressed: () {},
      backgroundColor: Colors.red[300]!.withOpacity(.6),
    );
  }

  Widget startSession(BuildContext context) {
    return BookDetailButton(
      text: 'Start session',
      subtitle: 'Reading timer',
      icon: Icons.timer_outlined,
      onPressed: () => context.push(SessionTimerPage(_libraryBook)),
      backgroundColor: Colors.blue[100]!.withOpacity(0.7),
    );
  }
}
