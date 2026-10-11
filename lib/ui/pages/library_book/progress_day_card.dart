import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

import 'progress_day_update.dart';

abstract final class _SessionWellChrome() {
  /// Charcoal under the day panel. The shared inset token is the page blue.
  static const fill = Color(0xFF262A32);
}

class const ProgressDayCard(
  final LibraryBook libraryBook,
  final ProgressEventDay progressEventDay,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _timelineStem(onTop: true),
        _card(),
        _timelineStem(onTop: false),
      ],
    );
  }

  Widget _card() {
    return ESurface(
      kind: ESurfaceKind.panel,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_dayHeader(), _sessionsWell()],
      ),
    );
  }

  Widget _dayHeader() {
    final ProgressSincePrevious? progressGained =
        progressEventDay.progressGained;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              progressEventDay.day.todayYesterdayOrDate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
          if (progressGained != null && !progressGained.isZero)
            ..._dayTotalCaptions(progressGained),
        ],
      ),
    );
  }

  List<Widget> _dayTotalCaptions(ProgressSincePrevious progressGained) {
    return [
      if (progressGained.plusUnitsCaption.isNotEmpty)
        _plusText(progressGained.plusUnitsCaption),
      _plusText(progressGained.plusPercentCaption),
    ];
  }

  Widget _sessionsWell() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SessionWellChrome.fill,
        borderRadius: ELayout.borderRadiusMd,
        border: Border.all(color: EColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (sessionIndex, session)
                in progressEventDay.events.reversed.indexed)
              ..._sessionInWell(session, sessionIndex),
          ],
        ),
      ),
    );
  }

  List<Widget> _sessionInWell(ProgressEvent session, int sessionIndex) {
    return [
      if (sessionIndex > 0)
        const ColoredBox(color: EColors.border, child: SizedBox(height: 1)),
      ProgressDayUpdate(libraryBook, session),
    ];
  }

  Widget _plusText(String caption) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        caption,
        style: AppTextStyles.body.copyWith(
          color: EColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timelineStem({required bool onTop}) {
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
          colors: [EColors.border, EColors.surfaceRaised, EColors.border],
        ),
      ),
    );
  }
}
