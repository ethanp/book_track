import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/library_book_presentation.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:flutter/material.dart';

class const ArchivedBookRow(final LibraryBook book) extends StatelessWidget {
  static const _coverWidth = 48.0;
  static const _coverHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LibraryBookPage(book.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              width: _coverWidth,
              height: _coverHeight,
              bytes: book.book.coverArt,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _copy()),
          ],
        ),
      ),
    );
  }

  Widget _copy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.book.title,
          style: AppTextStyles.h4,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          book.book.author ?? 'Author Unknown',
          style: AppTextStyles.bodySecondary.copyWith(
            fontStyle: FontStyle.italic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (book.startedAndFinishedCaption.isNotEmpty)
          Text(
            book.startedAndFinishedCaption,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(book.progressStatusCaption, style: AppTextStyles.caption),
      ],
    );
  }
}
