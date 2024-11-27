import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
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
              historyChart(),
              eventTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget historyChart() {
    return Card(
      margin: EdgeInsets.only(left: 16, right: 16, top: 28),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ProgressHistoryView(_libraryBook),
      ),
    );
  }

  /// TODO(feature) Event timeline:
  ///  1. Shows progress & status updates in time order
  ///  2. Allows updating/deleting each update
  Widget eventTimeline() {
    final List<ReadingEvent> progresses =
        // not sure why List.from is needed here but not for the status history.
        List.from(_libraryBook.progressHistory);
    final List<ReadingEvent> statuses = _libraryBook.statusHistory;
    final List<ReadingEvent> events = progresses + statuses;
    events.sort((a, b) => a.sortKey - b.sortKey);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ListView(
        shrinkWrap: true,
        children: events.mapL((e) {
          switch (e) {
            case StatusEvent(:var status):
              return Text('Status: ${status.name}');
            case ProgressEvent(:var progress):
              return Text('Progress: $progress');
            default:
              throw UnsupportedError(
                  'Unknown reading event type: ${e.runtimeType}');
          }
        }),
      ),
    );
  }
}
