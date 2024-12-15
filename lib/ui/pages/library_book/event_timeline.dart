import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/services/supabase_status_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventTimeline extends StatelessWidget {
  const EventTimeline(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: eventsByTimeAscending()
            .mapL((e) => _EventTimelineItem(libraryBook, e)),
      ),
    );
  }

  List<ReadingEvent> eventsByTimeAscending() {
    final List<ReadingEvent> progresses =
        // not sure why List.from is needed here but not for the status history.
        List.from(libraryBook.progressHistory);
    final List<ReadingEvent> statuses = libraryBook.statusHistory;
    return (progresses + statuses)..sort(byTimeAscending);
  }

  int byTimeAscending(ReadingEvent a, ReadingEvent b) =>
      a.dateTimeMillis - b.dateTimeMillis;
}

class _EventTimelineItem extends ConsumerWidget {
  const _EventTimelineItem(this.libraryBook, this.readingEvent);

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [dateTimeString(), eventInfo()],
            ),
            IconButton(
              onPressed: () => update(ref),
              icon: Icon(Icons.edit_note, size: 28),
            ),
            IconButton(
              onPressed: () => delete(ref),
              icon: Icon(Icons.delete, size: 28),
            )
          ],
        ),
      ),
    );
  }

  void delete(WidgetRef ref) => ConfirmationDialog.show(
        context: ref.context,
        text: 'Are you sure you want to delete this event?',
        title: 'delete event',
        actionName: 'delete',
        onConfirm: () async {
          void _ = switch (readingEvent) {
            ProgressEvent ev => await SupabaseProgressService.delete(ev),
            StatusEvent ev => await SupabaseStatusService.delete(ev),
            _ => log('unknown event ${readingEvent.runtimeType} $readingEvent'),
          };
          ref.invalidate(userLibraryProvider);
        },
      );

  Future<void> update(WidgetRef ref) async {
    return switch (readingEvent) {
      ProgressEvent ev =>
        await UpdateProgressDialogPage.update(ref, libraryBook, ev),
      StatusEvent _ =>
        // TODO(feature) Show a similar modal, but for status updates,
        //  so you can update the datetime or delete only.
        'a',
      _ => log('unknown event ${readingEvent.runtimeType} $readingEvent'),
    };
  }

  Widget dateTimeString() =>
      Text(TimeHelpers.dateAndTime(readingEvent.dateTime));

  Widget eventInfo() {
    return switch (readingEvent) {
      StatusEvent ev => Text('Status: ${ev.status.name}'),
      ProgressEvent ev => () {
          final progressString = libraryBook.bookProgressString(ev);
          final percentString = libraryBook.intPercentProgressAt(ev);
          return Text('Progress: $progressString ($percentString%)');
        }(),
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
