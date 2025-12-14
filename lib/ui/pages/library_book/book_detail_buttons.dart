import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/services/supabase_status_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/pages/session_timer/session_timer_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
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

    final List<Widget> children = (completed || abandoned)
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
                spacing: 10,
                runSpacing: 10,
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
      backgroundColor: Colors.pink[100]!.withValues(alpha: .75),
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
        // Use the last used format or primary format for completion
        final format = book.lastUsedFormat ?? book.primaryFormat;
        if (format != null) {
          await SupabaseProgressService.addProgressEvent(
            libraryBookId: book.supaId,
            formatId: format.supaId,
            newValue: 100,
            format: ProgressEventFormat.percent,
          );
        }
        ref.invalidate(userLibraryProvider);
      },
      backgroundColor: Colors.green[300]!.withValues(alpha: .6),
      dense: dense,
    );
  }

  Widget startSession(BuildContext context) {
    return BookDetailButton(
      title: 'Start session',
      subtitle: 'Reading timer',
      icon: Icons.timer_outlined,
      onPressed: () => context.push(SessionTimerPage(book)),
      backgroundColor: Colors.blue[100]!.withValues(alpha: 0.7),
      dense: dense,
    );
  }

  Widget remove(WidgetRef ref) {
    return BookDetailButton(
      title: 'Remove',
      subtitle: 'Remove book from app',
      icon: Icons.delete_forever_outlined,
      onPressed: () => showBookActionDialog(
        ref: ref,
        actionName: 'remove',
        onConfirm: SupabaseLibraryService.remove,
      ),
      backgroundColor: Colors.red[300]!.withValues(alpha: .6),
      dense: dense,
    );
  }

  Widget archive(WidgetRef ref) {
    final String actionName = book.archived ? 'unarchive' : 'archive';
    return BookDetailButton(
      title: actionName,
      subtitle: '${book.archived ? 'Show on' : 'Hide from'} home screen',
      icon: Icons.archive,
      onPressed: () => showBookActionDialog(
        ref: ref,
        actionName: actionName,
        onConfirm: SupabaseLibraryService.archive,
      ),
      backgroundColor: Colors.orange[300]!.withValues(alpha: .6),
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
          ? Colors.tealAccent[700]!.withValues(alpha: .2)
          : Colors.orange[300]!.withValues(alpha: .6),
      dense: dense,
    );
  }

  void showBookActionDialog({
    required WidgetRef ref,
    required String actionName,
    required Future<void> Function(LibraryBook) onConfirm,
  }) =>
      ConfirmationDialog.show(
        context: ref.context,
        text: 'Are you sure you want to $actionName '
            '"${book.book.title}" from your library?',
        title: '${actionName.capitalize} Book',
        actionName: actionName,
        onConfirm: () async {
          onConfirm(book)
              // Using `then` (instead of `await`) ensures context.pop()
              // happens on the same thread as this callback.
              .then((_) => ref.invalidate(userLibraryProvider));
          ref.context.pop();
        },
      );
}
