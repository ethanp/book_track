import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingProgressIndicator extends ConsumerWidget {
  const ReadingProgressIndicator(this.book);

  final LibraryBook book;

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
                color: AppColors.textPrimary,
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
                color: AppColors.textSecondary,
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
      color: AppColors.teal,
      backgroundColor: AppColors.progressBarTrack,
      value: book.progressPercentage.toDouble() / 100,
    );
  }
}
