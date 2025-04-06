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
      pipe(onTop: true),
      card(ref),
      pipe(onTop: false),
    ]);
  }

  Widget card(WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [eventInfo(), modifyButtons(ref)],
        ),
      ),
    );
  }

  Widget eventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dateTimeString(),
        switch (readingEvent) {
          StatusEvent statusEvent => Text('Status: ${statusEvent.status.name}'),
          ProgressEvent progressEvent => () {
              final progressString = progressEvent.stringWSuffix;
              final percentString =
                  libraryBook.intPercentProgressAt(progressEvent);
              return Text('Progress: $progressString ($percentString%)');
            }(),
          _ => throw UnsupportedError(
              'Unknown reading event type: ${readingEvent.runtimeType}')
        },
      ],
    );
  }

  Widget modifyButtons(WidgetRef ref) =>
      Row(children: [updateButton(ref), deleteButton(ref)]);

  Widget updateButton(WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.edit_note, size: 28),
      onPressed: () async => switch (readingEvent) {
        ProgressEvent progressEvent => await UpdateProgressDialogPage.update(
            ref, libraryBook, progressEvent),
        StatusEvent _ =>
          // TODO(feature) Show a modal that allows updating [StatusEvent]s.
          //  Probably want to allow updating both the `status` and `time`.
          //  Requires implementing something like [UpdateProgressDialogPage],
          //  but it would be called `UpdateStatusDialogPage` instead.
          'a',
        _ => log('unknown event ${readingEvent.runtimeType} $readingEvent'),
      },
    );
  }

  Widget deleteButton(WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.delete, size: 22, color: Colors.red[900]),
      onPressed: () => ConfirmationDialog.show(
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
      ),
    );
  }

  Widget dateTimeString() =>
      Text(TimeHelpers.dateAndTime(readingEvent.dateTime));

  Widget pipe({required bool onTop}) {
    return Container(
      height: 6,
      width: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(onTop ? 0 : 3),
          bottom: Radius.circular(onTop ? 3 : 0),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.grey[700]!, Colors.grey[300]!, Colors.grey[700]!],
        ),
      ),
    );
  }
}
