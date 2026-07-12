import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/cover_art_bytes.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookTile extends ConsumerWidget {
  const BookTile(this.book, this.idx);

  final LibraryBook book;
  final int idx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(book.book.supaId.toString()),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) => UpdateProgressDialogPage.show(ref, book),
      background: _dragBackground(),
      child: _bookListTile(context),
    );
  }

  Widget _bookListTile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(LibraryBookPage(book.supaId)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            _coverArt(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Expanded(child: _title()), _progressPercentage()],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_author(), _pagesRead()],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _startedDate(),
                      if (book.averagePaceDisplay != null)
                        Text(
                          book.averagePaceDisplay!,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _progressBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: book.progressPercentage.toDouble() / 100,
        minHeight: 5,
        backgroundColor: AppColors.progressBarTrack,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
      ),
    );
  }

  Widget _pagesRead() {
    return Text(
      book.currentBookProgressString ?? '',
      style: AppTextStyles.caption,
    );
  }

  Widget _author() {
    return Text(
      book.book.author ?? 'Author Unknown',
      style: AppTextStyles.bodySecondary,
    );
  }

  Widget _startedDate() {
    final String formatted = DateFormat('MMM d, y').format(book.startTime);
    return Text('Started $formatted', style: AppTextStyles.caption);
  }

  Widget _title() {
    return Text(
      book.book.title,
      style: AppTextStyles.h5,
    );
  }

  Widget _progressPercentage() {
    return Text(
      '${book.progressPercentage}%',
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.teal,
      ),
    );
  }

  Widget _coverArt() {
    const double height = 60.0;
    const double width = 45.0;

    final placeholder = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: const Icon(
        CupertinoIcons.book,
        color: AppColors.primary,
        size: 24,
      ),
    );

    Widget bookArt = placeholder;
    if (book.book.coverArtS != null &&
        coverArtLooksDecodable(book.book.coverArtS!)) {
      bookArt = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Image.memory(
          fit: BoxFit.fill,
          height: height,
          width: width,
          book.book.coverArtS!,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: const [AppShadows.coverArt],
      ),
      child: bookArt,
    );
  }

  Widget _dragBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: const Row(
        children: [
          Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 18),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Add progress',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
