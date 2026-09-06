import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const BookDetailButtons(final LibraryBook book) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);

    final actions = (book.isFinished || book.isAbandoned)
        ? [_archive(ref), _remove(ref)]
        : [_logProgress(ref), _complete(ref), _abandon(ref), _remove(ref)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ELayout.spaceLg),
      child: Column(
        children: [
          for (var actionIndex = 0; actionIndex < actions.length; actionIndex += 2) ...[
            if (actionIndex > 0) const SizedBox(height: ELayout.spaceSm),
            Row(
              children: [
                Expanded(child: actions[actionIndex]),
                const SizedBox(width: ELayout.spaceSm),
                Expanded(
                  child: actionIndex + 1 < actions.length
                      ? actions[actionIndex + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _logProgress(WidgetRef ref) {
    return _action(
      title: 'Log progress',
      subtitle: 'Sync with reality',
      icon: Icons.format_list_bulleted,
      accent: EColors.accent,
      onActivated: () => UpdateProgressDialogPage.show(ref, book),
    );
  }

  Widget _complete(WidgetRef ref) {
    return _action(
      title: 'Complete',
      subtitle: 'Mark book as finished',
      icon: Icons.check_box_outlined,
      accent: EColors.success,
      onActivated: () async {
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
    );
  }

  Widget _remove(WidgetRef ref) {
    return _action(
      title: 'Remove',
      subtitle: 'Remove book from app',
      icon: Icons.delete,
      accent: EColors.danger,
      onActivated: () => _showBookActionDialog(
        ref: ref,
        actionName: 'remove',
        onConfirm: SupabaseLibraryService.remove,
      ),
    );
  }

  Widget _archive(WidgetRef ref) {
    final actionName = book.archived ? 'unarchive' : 'archive';
    return _action(
      title: actionName,
      subtitle: '${book.archived ? 'Show on' : 'Hide from'} home screen',
      icon: Icons.archive,
      accent: EColors.accent,
      onActivated: () => _showBookActionDialog(
        ref: ref,
        actionName: actionName,
        onConfirm: SupabaseLibraryService.archive,
      ),
    );
  }

  Widget _abandon(WidgetRef ref) {
    return _action(
      title: book.isAbandoned ? 'Resume' : 'Abandon',
      subtitle: '${book.isAbandoned ? 'Continue' : 'Stop'} reading',
      icon: book.isAbandoned
          ? Icons.play_circle_outline
          : Icons.remove_circle_outline,
      accent: book.isAbandoned ? EColors.success : EColors.warning,
      onActivated: () async {
        await SupabaseLibraryService.setAbandoned(
          book,
          abandoned: !book.isAbandoned,
        );
        ref.invalidate(userLibraryProvider);
      },
    );
  }

  Widget _action({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onActivated,
  }) {
    return ETintedAction.compact(
      accent: accent,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onActivated: onActivated,
    );
  }

  void _showBookActionDialog({
    required WidgetRef ref,
    required String actionName,
    required Future<void> Function(LibraryBook) onConfirm,
  }) => ConfirmationDialog.show(
    context: ref.context,
    text:
        'Are you sure you want to $actionName '
        '"${book.book.title}" from your library?',
    title: '${actionName.capitalize} Book',
    actionName: actionName,
    onConfirm: () async {
      onConfirm(book).then((_) => ref.invalidate(userLibraryProvider));
      ref.context.pop();
    },
  );
}
