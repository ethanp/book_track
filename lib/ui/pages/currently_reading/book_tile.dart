import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../update_progress_dialog/update_progress_dialog_page.dart';
import 'reading_progress_indicator.dart';

class BookTile extends StatelessWidget {
  const BookTile(this.book);

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final int latestProgress = book.progressHistory.lastOrNull?.progress ?? 0;
    return Dismissible(
      key: Key(book.book.supaId.toString()),
      confirmDismiss: (direction) => _presentUpdateProgressDialog(context),
      background: Container(
        color: Colors.green,
        child: Text(
          'Add progress',
          style: TextStyle(color: Colors.grey[100], fontSize: 18),
        ),
      ),
      child: CupertinoListTile(
        title: Text(book.book.title),
        subtitle: Text(book.book.author ?? 'Author unknown'),
        leading: book.book.coverArtS.ifExists(
          Image.memory,
          otherwise: Icon(Icons.question_mark),
        ),
        trailing: ReadingProgressIndicator(progressPercent: latestProgress),
        onTap: () => context.push(LibraryBookPage(book)),
      ),
    );
  }

  Future<bool> _presentUpdateProgressDialog(BuildContext context) async {
    await showCupertinoDialog(
      context: context,
      builder: (context) => UpdateProgressDialogPage(book: book),
    );
    return false; // <- This means *don't* remove the book from the ListView.
  }
}
