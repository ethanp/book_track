import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressChart extends ConsumerWidget {
  const ProgressChart(this.initialBook);

  final LibraryBook initialBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.userLibrary((library) {
      final LibraryBook? latestBook = library
          .where((book) => book.supaId == initialBook.supaId)
          .singleOrNull;
      if (latestBook == null) {
        return Text(
          'The book ${initialBook.book.title} '
          'has been deleted from your library. '
          'We probably have to pop this screen now?',
        );
      }
      if (!latestBook.formats.any((format) => format.hasLength)) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            "Set a length for at least one format to see progress chart.",
            style: AppTextStyles.bodySecondary,
          ),
        );
      }
      return _chartCard(latestBook);
    });
  }

  Widget _chartCard(LibraryBook latestBook) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: const [AppShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(children: [
          _header(latestBook),
          !latestBook.hasProgress
              ? const Text(
                  'No progress updates yet',
                  style: AppTextStyles.bodySecondary,
                )
              : SizedBox(height: 300, child: _chart(latestBook)),
        ]),
      ),
    );
  }

  Widget _header(LibraryBook latestBook) {
    final String? paceDisplay = latestBook.averagePaceDisplay;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text('Progress', style: AppTextStyles.h3),
          if (paceDisplay != null) ...[
            const Spacer(),
            Text(
              paceDisplay,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart(LibraryBook latestBook) => Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
        child: BooksProgressChart(
          books: [latestBook],
          colorByFormat: true, // Color-code by format on book detail page
        ),
      );
}
