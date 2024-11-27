import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:flutter/material.dart';

class ReadingProgressIndicator extends StatelessWidget {
  ReadingProgressIndicator(this.book)
      : latestProgress = book.progressHistory.lastOrNull;

  final LibraryBook book;
  final ProgressEvent? latestProgress;

  static SimpleLogger log = SimpleLogger(prefix: 'ReadingProgressIndicator');

  double? get percentage {
    if (book.status == ReadingStatus.completed) {
      return 100;
    }
    if (latestProgress == null) {
      return null;
    }
    switch (latestProgress!.format) {
      case ProgressEventFormat.percent:
        return latestProgress?.progress.toDouble();
      case ProgressEventFormat.pageNum:
      case ProgressEventFormat.minutes:
        if (book.bookLength == null) return null;
        return latestProgress!.progress.toDouble() / book.bookLength!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (percentage == null) {
      // Nothing to show.
      return SizedBox.shrink();
    }
    final double width = 60;
    return SizedBox(
      width: width + 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          progressBar(width),
          Text('${percentage!.floor()}%'),
        ],
      ),
    );
  }

  Widget progressBar(double width) {
    return SizedBox(
      height: 12,
      // Recall: later children are placed *on top* of prior children.
      child: Stack(children: [colors(width), border(width)]),
    );
  }

  Widget colors(double width) {
    final double scale = .94;
    final double scaledWidthPerPercent = width / 100 * scale;
    if (percentage == null) {
      return Placeholder();
    }
    final percent = percentage!;
    final double readWidth = percent * scaledWidthPerPercent;
    final double unreadWidth = (100 - percent) * scaledWidthPerPercent;
    return Padding(
      padding: const EdgeInsets.only(left: 1, top: 1, bottom: 1, right: 3),
      child: Row(children: [
        if (percent > 0)
          Container(
            height: 12,
            width: readWidth,
            color: Colors.green,
            padding: EdgeInsets.zero,
          ),
        if (percent < 100)
          Container(
            height: 12,
            width: unreadWidth,
            color: Colors.orange,
            padding: EdgeInsets.zero,
          ),
      ]),
    );
  }

  Widget border(double width) {
    return Container(
      width: width - 2,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
