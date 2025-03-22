import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reading_progress_indicator.dart';

class BookTile extends ConsumerWidget {
  const BookTile(this.book);

  final LibraryBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 38,
        child: Dismissible(
          key: Key(book.book.supaId.toString()),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) =>
              UpdateProgressDialogPage.show(ref, book),
          background: dragBackground(),
          child: bookListTile(context),
        ),
      ),
    );
  }

  Widget bookListTile(BuildContext context) {
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(book.book.title, style: TextStyles().title),
      subtitle: Text(book.book.author ?? 'Author unknown'),
      leading: coverArt(),
      trailing: ReadingProgressIndicator(book),
      onTap: () => context.push(LibraryBookPage(book)),
    );
  }

  Widget coverArt() {
    if (book.book.coverArtS != null) {
      final bool validCover = (true &&
          book.book.coverArtS![0] == 255 &&
          book.book.coverArtS![1] == 216 &&
          book.book.coverArtS![2] == 255 &&
          book.book.coverArtS![3] == 224);
      if (validCover) return Image.memory(book.book.coverArtS!);
    }
    return Icon(Icons.question_mark);
  }

  Widget dragBackground() {
    return Container(
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Add progress',
          style: TextStyle(
            color: Colors.grey[100],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
