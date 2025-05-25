import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingProgressIndicator extends ConsumerWidget {
  const ReadingProgressIndicator(this.book);

  final LibraryBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${book.progressPercentage}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey[900],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: progressBarColors(),
          ),
          Text(
            book.currentBookProgressString ?? '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget progressBarColors() {
    return LinearProgressIndicator(
      borderRadius: BorderRadius.circular(6),
      minHeight: 6,
      color: Colors.green,
      backgroundColor: Colors.grey[300],
      value: book.progressPercentage.toDouble() / 100,
    );
  }
}
