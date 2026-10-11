import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:book_track/ui/common/confirmation_dialog.dart';
import 'package:book_track/ui/common/progress_event_date_caption.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const ProgressDayUpdate(
  final LibraryBook libraryBook,
  final ProgressEvent progressEvent,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _eventInfo()),
          _modifyButtons(ref),
        ],
      ),
    );
  }

  Widget _eventInfo() {
    final ProgressSincePrevious? progressGained = libraryBook
        .progressSincePrevious(progressEvent);
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            _dateCell(),
            _readoutCell(_positionCaption()),
            _readoutCell(
              '(${libraryBook.intPercentProgressAt(progressEvent)}%)',
            ),
          ],
        ),
        if (progressGained != null && !progressGained.isZero)
          TableRow(
            children: [
              const SizedBox.shrink(),
              _plusCell(progressGained.plusUnitsCaption),
              _plusCell(progressGained.plusPercentCaption),
            ],
          ),
      ],
    );
  }

  Widget _dateCell() {
    return Text(
      '${progressEvent.dateTime.hourMinuteAmPm}  ·  ',
      style: AppTextStyles.caption.copyWith(color: EColors.textMuted),
    );
  }

  Widget _readoutCell(String caption) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        caption,
        style: AppTextStyles.caption.copyWith(color: EColors.textMuted),
      ),
    );
  }

  Widget _plusCell(String caption) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        caption,
        style: AppTextStyles.caption.copyWith(
          color: EColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _positionCaption() {
    final LibraryBookFormat? format = libraryBook.formatById(
      progressEvent.formatId,
    );
    if (format?.isAudiobook == true) {
      return libraryBook.bookProgressString(progressEvent);
    }
    switch (progressEvent.format) {
      case ProgressEventFormat.pageNum:
        return '${progressEvent.progress} pgs';
      case ProgressEventFormat.minutes:
        return progressEvent.progress.minsToHhMm;
      case ProgressEventFormat.percent:
        return _percentAsPages();
    }
  }

  String _percentAsPages() {
    final double nativeAmount = libraryBook.pagesAt(progressEvent);
    if (nativeAmount <= 0) return progressEvent.stringWSuffix;
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
      color: EColors.accent,
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
      color: EColors.danger,
      onPressed: () => ConfirmationDialog.show(
        context: ref.context,
        text: 'Are you sure you want to delete this event?',
        title: 'delete event',
        actionName: 'delete',
        onConfirm: () async {
          final libraryRepository = await ref.read(
            libraryRepositoryProvider.future,
          );
          await libraryRepository.progress.delete(progressEvent);
          ref.invalidate(userLibraryProvider);
        },
      ),
      icon: const Icon(Icons.delete_outline),
    );
  }
}
