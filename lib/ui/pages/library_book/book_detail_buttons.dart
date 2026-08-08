import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/session_timer/session_timer_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_button.dart';

class BookDetailButtons extends ConsumerWidget {
  BookDetailButtons(this.book) : dense = book.hasProgress;
  final LibraryBook book;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);

    final List<Widget> children = (book.isFinished || book.isAbandoned)
        ? [
            _archive(ref),
            _remove(ref),
          ]
        : [
            _updateProgress(ref),
            _startSession(context),
            _complete(ref),
            _abandon(ref),
            _remove(ref)
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

  Widget _updateProgress(WidgetRef ref) {
    return BookDetailButton(
      title: 'Update progress',
      subtitle: 'Sync with reality',
      icon: CupertinoIcons.list_bullet,
      onPressed: () => UpdateProgressDialogPage.show(ref, book),
      backgroundColor: AppColors.primary.withValues(alpha: 0.25),
      dense: dense,
    );
  }

  Widget _complete(WidgetRef ref) {
    return BookDetailButton(
      title: 'Complete',
      subtitle: 'Mark book as finished',
      icon: CupertinoIcons.checkmark_square,
      onPressed: () async {
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
      backgroundColor: AppColors.success.withValues(alpha: 0.25),
      dense: dense,
    );
  }

  Widget _startSession(BuildContext context) {
    return BookDetailButton(
      title: 'Start session',
      subtitle: 'Reading timer',
      icon: CupertinoIcons.timer,
      onPressed: () => context.push(SessionTimerPage(book)),
      backgroundColor: AppColors.teal.withValues(alpha: 0.2),
      dense: dense,
    );
  }

  Widget _remove(WidgetRef ref) {
    return BookDetailButton(
      title: 'Remove',
      subtitle: 'Remove book from app',
      icon: CupertinoIcons.trash,
      onPressed: () => _showBookActionDialog(
        ref: ref,
        actionName: 'remove',
        onConfirm: SupabaseLibraryService.remove,
      ),
      backgroundColor: AppColors.destructive.withValues(alpha: 0.2),
      dense: dense,
    );
  }

  Widget _archive(WidgetRef ref) {
    final String actionName = book.archived ? 'unarchive' : 'archive';
    return BookDetailButton(
      title: actionName,
      subtitle: '${book.archived ? 'Show on' : 'Hide from'} home screen',
      icon: CupertinoIcons.archivebox,
      onPressed: () => _showBookActionDialog(
        ref: ref,
        actionName: actionName,
        onConfirm: SupabaseLibraryService.archive,
      ),
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
      dense: dense,
    );
  }

  Widget _abandon(WidgetRef ref) {
    return BookDetailButton(
      title: book.isAbandoned ? 'Resume' : 'Abandon',
      subtitle: '${book.isAbandoned ? 'Continue' : 'Stop'} reading',
      icon: book.isAbandoned
          ? CupertinoIcons.play_circle
          : CupertinoIcons.minus_circle,
      onPressed: () async {
        await SupabaseLibraryService.setAbandoned(
          book,
          abandoned: !book.isAbandoned,
        );
        ref.invalidate(userLibraryProvider);
      },
      backgroundColor: book.isAbandoned
          ? AppColors.teal.withValues(alpha: 0.15)
          : AppColors.primaryLight.withValues(alpha: 0.5),
      dense: dense,
    );
  }

  void _showBookActionDialog({
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
          onConfirm(book).then((_) => ref.invalidate(userLibraryProvider));
          ref.context.pop();
        },
      );
}
