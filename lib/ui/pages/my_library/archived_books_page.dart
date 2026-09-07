import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const ArchivedBooksPage() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: const EAppHeader(title: 'Archived'),
      body: SafeArea(
        child: ref
            .watch(userLibraryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: _pageBody,
            ),
      ),
    );
  }

  Widget _pageBody(List<LibraryBook> library) {
    final archivedBooks = library.whereL((book) => book.archived);
    archivedBooks.sortOn((book) => book.book.title.toLowerCase());
    if (archivedBooks.isEmpty) {
      return Center(
        child: Text('No archived books.', style: AppTextStyles.body),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: archivedBooks.length,
      itemBuilder: (context, index) => _ArchivedBookRow(archivedBooks[index]),
    );
  }
}

class const _ArchivedBookRow(final LibraryBook book) extends StatelessWidget {
  static const _coverWidth = 48.0;
  static const _coverHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(LibraryBookPage(book.supaId)),
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
