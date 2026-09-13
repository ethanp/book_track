import 'dart:math';

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/library_book_presentation.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const BookTile(final LibraryBook book) extends ConsumerWidget {
  static const _coverLeadingExtraWidth = 20.0;
  static const _coverAspectSlack = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(book.supaId.toString()),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) => UpdateProgressDialogPage.show(ref, book),
      background: _addProgressReveal(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LayoutBuilder(builder: _flushCard),
      ),
    );
  }

  Widget _flushCard(BuildContext context, BoxConstraints constraints) {
    return EFlushLeadingCard(
      leadingWidth: min(
        EFlushLeadingCard.cappedLeadingWidth(constraints.maxWidth) +
            _coverLeadingExtraWidth +
            _coverAspectSlack,
        constraints.maxWidth,
      ),
      leadingGap: AppSpacing.md,
      onActivated: () => context.push(LibraryBookPage(book.supaId)),
      leading: _coverArt(),
      child: _copy(),
    );
  }

  Widget _coverArt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double coverHeight = constraints.maxHeight;
        final double uncappedWidth =
            coverHeight * BookCover.aspectRatioOf(book.book.coverArt) +
            _coverAspectSlack;
        return Align(
          alignment: Alignment.centerLeft,
          child: BookCover(
            width: min(uncappedWidth, constraints.maxWidth),
            height: coverHeight,
            bytes: book.book.coverArt,
            borderRadius: 0,
          ),
        );
      },
    );
  }

  Widget _copy() {
    final AverageReadingPace? readingPace = book.averageReadingPace;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identity(),
          const SizedBox(height: AppSpacing.sm),
          _schedule(readingPace),
          const SizedBox(height: AppSpacing.sm),
          _progress(),
        ],
      ),
    );
  }

  Widget _identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_title(), _author()],
    );
  }

  Widget _schedule(AverageReadingPace? readingPace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _startedAndEta(readingPace?.etaCaption),
        if (readingPace != null) _averagePace(readingPace.paceLabel),
      ],
    );
  }

  Widget _progress() {
    return EProgressMeter(
      value: book.progressPercentage.toDouble() / 100,
      leadingLabel: '${book.progressPercentage}%',
      trailingLabel: book.currentBookProgressString,
      tone: EStatusTone.success,
    );
  }

  Widget _title() {
    return Text(
      book.book.title,
      style: AppTextStyles.h4,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _author() {
    return Text(
      book.book.author ?? 'Author Unknown',
      style: AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _startedAndEta(String? etaCaption) {
    final DateTime? startedOn = book.startedOn;
    final String caption = [
      if (startedOn != null) 'Started ${startedOn.monthDayCaption}',
      if (etaCaption != null) etaCaption,
    ].join(' · ');
    if (caption.isEmpty) return const SizedBox.shrink();
    return Text(caption, style: AppTextStyles.caption, maxLines: 2);
  }

  Widget _averagePace(String paceLabel) {
    return Text(paceLabel, style: AppTextStyles.caption);
  }

  Widget _addProgressReveal() {
    return Container(
      decoration: BoxDecoration(
        color: EColors.success,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: const Row(
        children: [
          Icon(Icons.add, color: Colors.white, size: 18),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Log progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
