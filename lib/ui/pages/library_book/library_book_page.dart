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

  /// Event timeline:
  ///  1. (done) Shows progress & status updates in time order
  ///  2. TODO(feature) Allows updating/deleting each update
  Widget eventTimeline() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ListView(
        shrinkWrap: true,
        children: eventsByTimeAscending().mapL(
          (readingEvent) => switch (readingEvent) {
            StatusEvent(:final status) => Text('Status: ${status.name}'),
            ProgressEvent(:final progress, :final format) =>
              Text('Progress: $progress ${format.name}'),
            _ => throw UnsupportedError(
                'Unknown reading event type: ${readingEvent.runtimeType}')
          },
        ),
      ),
    );
  }

  List<ReadingEvent> eventsByTimeAscending() {
    final List<ReadingEvent> progresses =
        // not sure why List.from is needed here but not for the status history.
        List.from(_libraryBook.progressHistory);
    final List<ReadingEvent> statuses = _libraryBook.statusHistory;
    return (progresses + statuses)..sort(byTimeAscending);
  }

  int byTimeAscending(ReadingEvent a, ReadingEvent b) =>
      a.dateTimeField - b.dateTimeField;
}
