import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/app_bars.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segment_display/segment_display.dart';

class SessionTimerPage extends ConsumerStatefulWidget {
  const SessionTimerPage(this.book);

  final LibraryBook book;

  @override
  ConsumerState createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimerPage> {
  bool get sessionInProgress => ref.watch(sessionStartTimeProvider) != null;

  @override
  Widget build(BuildContext context) {
    _updateTimer();
    return CupertinoPageScaffold(
      navigationBar: const AppNavigationBar(
        middle: Text('Session'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(children: [
            _segmentDisplay(),
            const SizedBox(height: 30),
            _toggleButtons(),
            const SizedBox(height: 80),
            _progressHistory(),
          ]),
        ),
      ),
    );
  }

  Widget _toggleButtons() {
    if (!sessionInProgress) return _beginSessionButton();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_endSessionButton(), _cancelSessionButton()],
    );
  }

  Widget _beginSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    return _toggleSessionButton(
      onPressed: () => readSession.start(),
      backgroundColor: AppColors.teal,
      text: 'Begin Session',
    );
  }

  Widget _endSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    final DateTime? startTime = ref.read(sessionStartTimeProvider);

    return _toggleSessionButton(
      onPressed: () {
        readSession.stop();
        UpdateProgressDialogPage.show(
          ref,
          widget.book,
          startTime: startTime,
          initialEndTime: DateTime.now(),
        );
      },
      backgroundColor: AppColors.primary,
      text: 'End Session',
    );
  }

  Widget _cancelSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    return _toggleSessionButton(
      onPressed: () => readSession.stop(),
      backgroundColor: AppColors.destructive,
      text: 'Cancel Session',
    );
  }

  Widget _toggleSessionButton({
    required void Function() onPressed,
    required Color backgroundColor,
    required String text,
  }) =>
      CupertinoButton(
        onPressed: () {
          onPressed();
          _repaint();
        },
        color: backgroundColor,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: SizedBox(
          width: 170,
          height: 88,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  Widget _segmentDisplay() {
    final DateTime? currStartTime = ref.read(sessionStartTimeProvider);
    final Color displayBackground = sessionInProgress
        ? AppColors.teal.withValues(alpha: 0.12)
        : AppColors.shimmer.withValues(alpha: 0.3);
    final Color borderColor = sessionInProgress
        ? AppColors.teal.withValues(alpha: 0.4)
        : AppColors.divider;

    final clockFace = SevenSegmentDisplay(
      value: _duration(currStartTime),
      backgroundColor: CupertinoColors.white.withAlpha(0),
      segmentStyle: HexSegmentStyle(
        segmentBaseSize: const Size(.85, 3.0),
        disabledColor: displayBackground.lerpWith(AppColors.shimmer, .3),
        enabledColor: AppColors.textPrimary,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 6),
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: displayBackground,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: const EdgeInsets.all(20),
      child: clockFace,
    );
  }

  Timer? _timer;

  void _updateTimer() {
    if (sessionInProgress) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), _repaint);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _repaint([dynamic _]) => mounted ? setState(() {}) : {};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _duration(DateTime? currStartTime) {
    if (!sessionInProgress) return '**:**';
    final Duration elapsedTime = DateTime.now().difference(currStartTime!);
    final String minutes = elapsedTime.inMinutes.pad(2);
    final String seconds = (elapsedTime.inSeconds % 60).pad(2);
    return '$minutes:$seconds';
  }

  Widget _progressHistory() {
    final List<ProgressEvent> progressEvents = widget.book.progressHistory;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: const [AppShadows.card],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 270),
          child: Column(children: [
            _historyTitle(),
            if (progressEvents.isEmpty)
              Text('None', style: AppTextStyles.h3)
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Table(
                      columnWidths: const {0: FixedColumnWidth(110)},
                      children: progressEvents.mapL(
                        (event) => TableRow(children: [
                          Text(
                            TimeHelpers.monthDayYear(event.end),
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            TimeHelpers.hourMinuteAmPm(event.end),
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            '${widget.book.intPercentProgressAt(event)}%',
                            style: AppTextStyles.body,
                          ),
                          Text(event.stringWSuffix, style: AppTextStyles.body),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _historyTitle() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text('Progress Events', style: AppTextStyles.h3),
    );
  }
}
