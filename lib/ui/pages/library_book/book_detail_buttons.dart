import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:book_track/ui/pages/session_timer/session_timer_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_button.dart';

class BookDetailButtons extends ConsumerWidget {
  BookDetailButtons({required this.book})
      : dense = book.progressHistory.isNotEmpty;
  final LibraryBook book;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> children = [
      updateProgress(ref),
      startSession(context),
      complete(),
      abandon(),
      remove(ref),
    ];
    return Expanded(
      child: dense
          ? Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: children,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
    );
  }

  Widget updateProgress(WidgetRef ref) {
    return BookDetailButton(
      title: 'Update progress',
      subtitle: 'Sync with reality',
      icon: Icons.list_alt_outlined,
      onPressed: () => UpdateProgressDialogPage.show(ref, book),
      backgroundColor: Colors.pink[100]!.withOpacity(.75),
      dense: dense,
    );
  }

  Widget complete() {
    return BookDetailButton(
      title: 'Complete',
      subtitle: 'Mark book as finished',
      icon: Icons.check_box_outlined,
      onPressed: () {},
      backgroundColor: Colors.green[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  Widget startSession(BuildContext context) {
    return BookDetailButton(
      title: 'Start session',
      subtitle: 'Reading timer',
      icon: Icons.timer_outlined,
      onPressed: () => context.push(SessionTimerPage(book)),
      backgroundColor: Colors.blue[100]!.withOpacity(0.7),
      dense: dense,
    );
  }

  Widget remove(WidgetRef ref) {
    return BookDetailButton(
      title: 'Remove',
      subtitle: 'Remove book from app',
      icon: Icons.delete_forever_outlined,
      onPressed: () {
        showRemoveBookDialog(
          ref.context,
          book.book.title,
          () {
            SupabaseLibraryService.remove(book).then((val) {
              print('invalidating user library provider');
              ref.invalidate(userLibraryProvider);
            });
            ref.context.pop();
          },
        );
      },
      backgroundColor: Colors.red[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  Widget abandon() {
    return BookDetailButton(
      title: 'Abandon',
      subtitle: 'Stop reading this book',
      icon: Icons.remove_circle_outline_outlined,
      onPressed: () {},
      backgroundColor: Colors.orange[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  static void showRemoveBookDialog(
    BuildContext context,
    String bookTitle,
    VoidCallback onConfirm,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Remove Book'),
          content: Text(
              'Are you sure you want to remove "$bookTitle" from your library?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              isDestructiveAction: true,
              child: Text(
                'Remove',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
            ),
          ],
        );
      },
    );
  }
}