import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventTimelineItem extends ConsumerWidget {
  const EventTimelineItem(this.libraryBook, this.readingEvent);

  final LibraryBook libraryBook;
  final ReadingEvent readingEvent;

  static final SimpleLogger log = SimpleLogger(prefix: 'EventTimelineItem');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      pipe(top: true),
      card(ref),
      pipe(top: false),
    ]);
  }

  Widget card(WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: content(ref),
      ),
    );
  }

  Widget content(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [dateTimeString(), eventInfo()],
        ),
        IconButton(
          onPressed: () async {
            if (readingEvent is ProgressEvent) {
              await UpdateProgressDialogPage.update(
                ref,
                libraryBook,
                readingEvent as ProgressEvent,
              );
            } else {
              // TODO(feature) Show a similar modal, but for status updates,
              //  so you can update the datetime or delete only.
            }
          },
          icon: Icon(Icons.edit_note, size: 28),
        ),
      ],
    );
  }

  Widget dateTimeString() =>
      Text(TimeHelpers.dateAndTime(readingEvent.dateTime));

  Widget eventInfo() {
    return switch (readingEvent) {
      StatusEvent(:final status) => Text('Status: ${status.name}'),
      ProgressEvent(:final progress, :final format) =>
        Text('Progress: $progress ${format.name}'),
      _ => throw UnsupportedError(
          'Unknown reading event type: ${readingEvent.runtimeType}')
    };
  }

  Widget pipe({required bool top}) {
    return Container(
      height: 6,
      width: 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade700, // Darker shade for the edges
            Colors.grey.shade300, // Lighter shade for the center
            Colors.grey.shade700, // Darker shade for the other edge
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(top ? 0 : 3),
          bottom: Radius.circular(top ? 3 : 0),
        ),
      ),
    );
  }
}
