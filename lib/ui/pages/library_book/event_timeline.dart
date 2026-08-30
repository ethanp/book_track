import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const EventTimeline(final LibraryBook libraryBook)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: libraryBook.progressHistory.reversed.mapL(
          (event) => _EventTimelineItem(libraryBook, event),
        ),
      ),
    );
  }
}

class const _EventTimelineItem(
  final LibraryBook libraryBook,
  final ProgressEvent progressEvent,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [_pipe(onTop: true), _card(ref), _pipe(onTop: false)],
    );
  }

  Widget _card(WidgetRef ref) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Expanded(child: _eventInfo()),
          _modifyButtons(ref),
        ],
      ),
    );
  }

  Widget _eventInfo() {
    final percentString = libraryBook.intPercentProgressAt(progressEvent);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: TimeHelpers.dateAndTime(progressEvent.dateTime),
            style: AppTextStyles.caption,
          ),
          TextSpan(text: '  ·  ', style: AppTextStyles.caption),
          TextSpan(
            text: '${_progressDisplayString()} ($percentString%)',
            style: AppTextStyles.body,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _progressDisplayString() {
    switch (progressEvent.format) {
      case ProgressEventFormat.pageNum:
        return '${progressEvent.progress} pgs';
      case ProgressEventFormat.minutes:
        return '${progressEvent.progress} mins';
      case ProgressEventFormat.percent:
        return _percentAsNativeUnits();
    }
  }

  String _percentAsNativeUnits() {
    final nativeAmount = libraryBook.pagesAt(progressEvent);
    if (nativeAmount <= 0) return progressEvent.stringWSuffix;
    final bookFormat = libraryBook.formatById(progressEvent.formatId);
    if (bookFormat?.isAudiobook == true) {
      return '${nativeAmount.round()} mins';
    }
    return '${nativeAmount.round()} pgs';
  }

  Widget _modifyButtons(WidgetRef ref) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_updateButton(ref), _deleteButton(ref)],
      ),
    );
  }

  Widget _updateButton(WidgetRef ref) {
    return IconButton(
      tooltip: 'Edit',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      iconSize: 18,
      color: AppColors.primary,
      onPressed: () =>
          UpdateProgressDialogPage.update(ref, libraryBook, progressEvent),
      icon: const Icon(Icons.edit),
    );
  }

  Widget _deleteButton(WidgetRef ref) {
    return IconButton(
      tooltip: 'Delete',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      iconSize: 18,
      color: AppColors.destructive,
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
      icon: const Icon(Icons.delete_outline),
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
          colors: [AppColors.divider, AppColors.shimmer, AppColors.divider],
        ),
      ),
    );
  }
}
