import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventTimeline extends StatelessWidget {
  const EventTimeline(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: libraryBook.progressHistory
            .mapL((event) => _EventTimelineItem(libraryBook, event)),
      ),
    );
  }
}

class _EventTimelineItem extends ConsumerWidget {
  const _EventTimelineItem(this.libraryBook, this.progressEvent);

  final LibraryBook libraryBook;
  final ProgressEvent progressEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      _pipe(onTop: true),
      _card(ref),
      _pipe(onTop: false),
    ]);
  }

  Widget _card(WidgetRef ref) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_eventInfo(), _modifyButtons(ref)],
      ),
    );
  }

  Widget _eventInfo() {
    final percentString = libraryBook.intPercentProgressAt(progressEvent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TimeHelpers.dateAndTime(progressEvent.dateTime),
          style: AppTextStyles.caption,
        ),
        Text(
          'Progress: ${_progressDisplayString()} ($percentString%)',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  String _progressDisplayString() {
    if (progressEvent.format != ProgressEventFormat.percent) {
      return progressEvent.stringWSuffix;
    }
    final nativeAmount = libraryBook.pagesAt(progressEvent);
    if (nativeAmount <= 0) return progressEvent.stringWSuffix;
    final bookFormat = libraryBook.formatById(progressEvent.formatId);
    if (bookFormat?.isAudiobook == true) {
      return '${nativeAmount.toInt().minsToHhMm} hh:mm';
    }
    return '${nativeAmount.round()} pgs';
  }

  Widget _modifyButtons(WidgetRef ref) =>
      Row(children: [_updateButton(ref), _deleteButton(ref)]);

  Widget _updateButton(WidgetRef ref) {
    return CupertinoButton(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onPressed: () =>
          UpdateProgressDialogPage.update(ref, libraryBook, progressEvent),
      child: const Icon(
        CupertinoIcons.pencil,
        size: 22,
        color: AppColors.primary,
      ),
    );
  }

  Widget _deleteButton(WidgetRef ref) {
    return CupertinoButton(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onPressed: () => ConfirmationDialog.show(
        context: ref.context,
        text: 'Are you sure you want to delete this event?',
        title: 'delete event',
        actionName: 'delete',
        onConfirm: () async {
          await SupabaseProgressService.delete(progressEvent);
          ref.invalidate(userLibraryProvider);
        },
      ),
      child: const Icon(
        CupertinoIcons.trash,
        size: 20,
        color: AppColors.destructive,
      ),
    );
  }

  Widget _pipe({required bool onTop}) {
    return Container(
      height: 6,
      width: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(onTop ? 0 : 3),
          bottom: Radius.circular(onTop ? 3 : 0),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.divider,
            AppColors.shimmer,
            AppColors.divider,
          ],
        ),
      ),
    );
  }
}
