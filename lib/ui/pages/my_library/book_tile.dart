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
          confirmDismiss: (direction) =>
              UpdateProgressDialogPage.show(ref, book),
          background: Container(
            color: Colors.green,
            child: Text(
              'Add progress',
              style: TextStyle(color: Colors.grey[100], fontSize: 18),
            ),
          ),
          child: CupertinoListTile(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(book.book.title, style: TextStyles().title),
            subtitle: Text(book.book.author ?? 'Author unknown'),
            leading: book.book.coverArtS.map(Image.memory) ??
                Icon(Icons.question_mark),
            trailing: ReadingProgressIndicator(book),
            onTap: () => context.push(LibraryBookPage(book)),
          ),
        ),
      ),
    );
  }
}
