import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const ReadingProgressIndicator(final LibraryBook book)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    return SizedBox(
      width: 80,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${book.progressPercentage}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: EColors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SizedBox(width: 80, child: _progressBar()),
            ),
            Text(
              book.currentBookProgressString ?? '',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: EColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    return LinearProgressIndicator(
      borderRadius: BorderRadius.circular(6),
      minHeight: 6,
      color: EColors.success,
      backgroundColor: EColors.surfaceRaised,
      value: book.progressPercentage.toDouble() / 100,
    );
  }
}
