import 'package:book_track/data_model.dart';
import 'package:flutter/material.dart';

import 'reading_progress_indicator.dart';

class BookTile extends StatelessWidget {
  const BookTile(this.book);

  final BookProgress book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(book.book.title),
      subtitle: Text(book.book.author),
      leading: Icon(Icons.question_mark),
      trailing: ReadingProgressIndicator(
        progressPercent: book.progressHistory.progressEvents.last.progress,
      ),
    );
  }
}
