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
    if (progressPercentage == null) return SizedBox.shrink();
    const double width = 90;
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
    final int percent = book.progressPercentage!;
    final double readWidth = percent * scaledWidthPerPercent;
    final double unreadWidth = (100 - percent) * scaledWidthPerPercent;
    return SizedBox(
      height: 9,
      child: Padding(
        padding: const EdgeInsets.only(left: 1.5),
        child: Row(children: [
          if (percent > 0) readPortion(readWidth),
          if (percent < 100) unreadPortion(unreadWidth),
        ]),
      ),
    );
  }

  Widget unreadPortion(double unreadWidth) =>
      portion(unreadWidth, Colors.orange, right: Radius.circular(10));

  Widget readPortion(double readWidth) =>
      portion(readWidth, Colors.green, left: Radius.circular(10));

  Widget portion(
    double width,
    Color color, {
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) {
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
