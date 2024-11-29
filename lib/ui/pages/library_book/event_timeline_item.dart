import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:flutter/material.dart';

class EventTimelineItem extends StatelessWidget {
  const EventTimelineItem(this.readingEvent);

  final ReadingEvent readingEvent;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      pipe(top: true),
      card(),
      pipe(top: false),
    ]);
  }

  Widget card() {
    // TODO(feature) when you click it, you should be able to thoroughly update it.
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: content(),
      ),
    );
  }

  Widget content() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [dateTimeString(), eventInfo()],
        ),
        IconButton(
          onPressed: () {},
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
