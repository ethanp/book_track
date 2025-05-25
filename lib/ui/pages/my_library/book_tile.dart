import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart' show FlutterHelpers;
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      background: dragBackground(),
      child: bookListTile(context),
    );
  }

  Widget bookListTile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(LibraryBookPage(book)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            coverArt(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Expanded(child: title()), progressPercentage()],
                  ),
                  SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [author(), pagesRead()],
                  ),
                  SizedBox(height: 8),
                  progressBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget progressBar() {
    return LinearProgressIndicator(
      value: book.progressPercentage.toDouble() / 100,
      minHeight: 6,
      borderRadius: BorderRadius.circular(4),
      backgroundColor: Colors.grey[300],
    );
  }

  Widget pagesRead() {
    return Text(
      book.currentBookProgressString ?? '',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
      ),
    );
  }

  Widget author() {
    return Text(
      book.book.author ?? 'Author Unknown',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    );
  }

  Widget title() {
    return Text(
      book.book.title,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  Widget progressPercentage() {
    return Text(
      '${book.progressPercentage}%',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
      ),
    );
  }

  Widget coverArt() {
    final double height = 60;
    final double width = 45;
    Widget bookArt = SizedBox(
      height: height,
      width: width,
      child: Icon(Icons.question_mark),
    );
    if (book.book.coverArtS != null) {
      final bool validCover = (true &&
          book.book.coverArtS![0] == 255 &&
          book.book.coverArtS![1] == 216 &&
          book.book.coverArtS![2] == 255 &&
          book.book.coverArtS![3] == 224);
      if (validCover) {
        bookArt = ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.memory(
            fit: BoxFit.fill,
            height: height,
            width: width,
            book.book.coverArtS!,
          ),
        );
      }
    }
    return Card(
      elevation: 4,
      shape: FlutterHelpers.roundedRect(radius: 6),
      child: bookArt,
    );
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
