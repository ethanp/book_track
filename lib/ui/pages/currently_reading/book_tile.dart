import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/pages/session_start/session_start_page.dart';
import 'package:flutter/material.dart';

import 'reading_progress_indicator.dart';
import 'update_progress_dialog.dart';

class BookTile extends StatelessWidget {
  const BookTile(this.book);

  final BookProgress book;

  @override
  Widget build(BuildContext context) {
    final int latestProgress =
        book.progressHistory.progressEvents.lastOrNull?.progress ?? 0;
    return Dismissible(
      key: Key(book.book.supaId.toString()),
      confirmDismiss: (direction) => _presentUpdateProgressDialog(context),
      child: ListTile(
        title: Text(book.book.title),
        subtitle: Text(book.book.author ?? 'Author unknown'),
        leading: Icon(Icons.question_mark),
        trailing: ReadingProgressIndicator(progressPercent: latestProgress),
        onTap: () => context.push(SessionStartPage(book)),
      ),
    );
  }

  Future<bool> _presentUpdateProgressDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => UpdateProgressDialog(book),
    );
    return false; // <- This means *don't* remove the book from the ListView.
  }
}
