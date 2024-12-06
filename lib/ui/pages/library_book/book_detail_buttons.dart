import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/services/supabase_status_service.dart';
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

  static final SimpleLogger log = SimpleLogger(prefix: 'BookDetailButtons');

  bool get completed => book.readingStatus == ReadingStatus.finished;

  bool get abandoned => book.readingStatus == ReadingStatus.abandoned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);

    final List<Widget> children = completed
        ? [
            archive(ref),
            remove(ref),
          ]
        : [
            updateProgress(ref),
            startSession(context),
            complete(ref),
            abandon(ref),
            remove(ref)
          ];

    return Flexible(
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

  Widget complete(WidgetRef ref) {
    return BookDetailButton(
      title: 'Complete',
      subtitle: 'Mark book as finished',
      icon: Icons.check_box_outlined,
      onPressed: () async {
        await SupabaseStatusService.add(book.supaId, ReadingStatus.finished);
        await SupabaseProgressService.updateProgress(
          bookId: book.supaId,
          newValue: 100,
          format: ProgressEventFormat.percent,
        );
        ref.invalidate(userLibraryProvider);
      },
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
        showBookActionDialog(
          ref.context,
          book.book.title,
          () {
            // We explicitly use `then` (instead of `await`) to ensure the
            // context.pop happens on the same thread as this callback was
            // called on.
            SupabaseLibraryService.remove(book)
                .then((_) => ref.invalidate(userLibraryProvider));
            ref.context.pop();
          },
          'remove',
        );
      },
      backgroundColor: Colors.red[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  Widget archive(WidgetRef ref) {
    return BookDetailButton(
      title: 'Archive',
      subtitle: 'Hide from home screen',
      icon: Icons.archive,
      onPressed: () {
        showBookActionDialog(
          ref.context,
          book.book.title,
          () {
            // Using `then` (instead of `await`) ensures context.pop() happens
            // on the same thread as this callback.
            SupabaseLibraryService.archive(book)
                .then((_) => ref.invalidate(userLibraryProvider));
            ref.context.pop();
          },
          'archive',
        );
      },
      backgroundColor: Colors.orange[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  Widget abandon(WidgetRef ref) {
    return BookDetailButton(
      title: abandoned ? 'Resume' : 'Abandon',
      subtitle: '${abandoned ? 'Continue' : 'Stop'} reading',
      icon: abandoned
          ? Icons.play_circle_outline
          : Icons.remove_circle_outline_outlined,
      onPressed: () async {
        await SupabaseStatusService.add(
          book.supaId,
          abandoned ? ReadingStatus.reading : ReadingStatus.abandoned,
        );
        ref.invalidate(userLibraryProvider);
      },
      backgroundColor: abandoned
          ? Colors.tealAccent[700]!.withOpacity(.2)
          : Colors.orange[300]!.withOpacity(.6),
      dense: dense,
    );
  }

  static void showBookActionDialog(
    BuildContext context,
    String bookTitle,
    VoidCallback onConfirm,
    String name,
  ) =>
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('${name.capitalize} Book'),
            content: Text(
              'Are you sure you want to $name "$bookTitle" from your library?',
            ),
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
                  name.capitalize,
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
            ],
          );
        },
      );
}
