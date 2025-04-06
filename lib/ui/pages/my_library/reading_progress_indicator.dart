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
  static const Radius rounded = Radius.circular(10);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    final int progressPercentage = book.progressPercentage;
    const double width = 65;
    return SizedBox(
      width: width - 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$progressPercentage%', style: TextStyle(fontSize: 13)),
          progressBarColors(width),
          Text(
            book.currentBookProgressString ?? '',
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget progressBarColors(double width) {
    final double scaledWidthPerPercent = width / 100 * .94;
    final double readWidth = book.progressPercentage * scaledWidthPerPercent;
    final double unreadWidth =
        (100 - book.progressPercentage) * scaledWidthPerPercent;
    return SizedBox(
      height: 9,
      child: Padding(
        padding: const EdgeInsets.only(left: 1.5),
        child: Row(children: [
          if (book.progressPercentage > 0)
            portion(
              width: readWidth,
              color: Colors.green,
              left: ReadingProgressIndicator.rounded,
            ),
          if (book.progressPercentage < 100)
            portion(
              width: unreadWidth,
              color: Colors.orange,
              right: ReadingProgressIndicator.rounded,
            ),
        ]),
      ),
    );
  }

  Widget portion({
    required double width,
    required Color color,
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) {
    if ([0, 100].contains(book.progressPercentage)) left = right = rounded;
    return Container(
      width: width,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.horizontal(left: left, right: right),
      ),
    );
  }
}
