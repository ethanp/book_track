import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/scroll_propagating_list_view.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const RecentBooksWidget({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cutoff = periodCutoff;
    final recentBooks = books
        .where(
          (book) =>
              cutoff == null ||
              book.progressHistory.any((event) => event.end.isAfter(cutoff)),
        )
        .toList();

    if (recentBooks.isEmpty) {
      return Center(
        child: Text(
          'No books read in this period',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    final booksWithProgress =
        recentBooks
            .where((book) => book.hasProgress)
            .map(_progressInPeriod)
            .toList()
          ..sort((left, right) {
            if (left.progressMade != right.progressMade) {
              return right.progressMade.compareTo(left.progressMade);
            }
            return left.book.book.title.compareTo(right.book.book.title);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Books read in this period', style: AppTextStyles.h5),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ScrollPropagatingListView(
            itemCount: booksWithProgress.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final recentBook = booksWithProgress[index];
              final book = recentBook.book;
              final progressMade = recentBook.progressMade;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LibraryBookPage(book.id),
                  ),
                ),
                child: Row(
                  children: [
                    _bookCover(book),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        book.book.title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ),
                    Text(
                      '+$progressMade%',
                      style: AppTextStyles.caption.copyWith(
                        color: EColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _RecentBookProgress _progressInPeriod(LibraryBook book) {
    final sorted = book.progressHistory.toList()
      ..sort((left, right) => left.end.compareTo(right.end));
    final cutoff = periodCutoff;
    final beforeWindow = cutoff == null
        ? null
        : sorted.where((event) => event.end.isBefore(cutoff)).lastOrNull;
    final startPercent = beforeWindow == null
        ? 0
        : book.intPercentProgressAt(beforeWindow);
    final endPercent = book.intPercentProgressAt(sorted.last);
    return _RecentBookProgress(
      book: book,
      progressMade: endPercent - startPercent,
    );
  }

  Widget _bookCover(LibraryBook book) {
    return BookCover(
      width: 22.5,
      height: 30,
      bytes: book.book.coverArt,
      borderRadius: 3,
    );
  }
}

class const _RecentBookProgress({
  required final LibraryBook book,
  required final int progressMade,
});
