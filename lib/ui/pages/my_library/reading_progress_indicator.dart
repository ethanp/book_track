import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingProgressIndicator extends ConsumerWidget {
  ReadingProgressIndicator(this.book)
      : latestProgress = book.progressHistory.lastOrNull;

  final LibraryBook book;
  final ProgressEvent? latestProgress;

  static SimpleLogger log = SimpleLogger(prefix: 'ReadingProgressIndicator');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    final int? progressPercentage = book.progressPercentage;
    // TODO(bug) I'm seeing percentage == 0% for all audiobooks here. Sim only!
    log('${book.book.title} progressPercentage: $progressPercentage');
    // Nothing to show.
    if (progressPercentage == null) return SizedBox.shrink();
    final double width = 60;
    return SizedBox(
      width: width + 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          progressBar(width),
          Text('$progressPercentage%'),
        ],
      ),
    );
  }

  Widget progressBar(double width) {
    return SizedBox(
      height: 12,
      // Recall: latter children are placed *on top* of prior children.
      child: Stack(children: [colors(width), border(width)]),
    );
  }

  Widget colors(double width) {
    final double scale = .94;
    final double scaledWidthPerPercent = width / 100 * scale;
    final percent = book.progressPercentage!;
    log('${book.book.title} $percent%');
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
