import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
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
    updateTimer();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Session')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(children: [
            segmentDisplay(),
            const SizedBox(height: 30),
            toggleButtons(),
            const SizedBox(height: 80),
            progressHistory(),
          ]),
        ),
      ),
    );
  }

  Widget toggleButtons() {
    return !sessionInProgress
        ? beginSessionButton()
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [endSessionButton(), cancelSessionButton()]);
  }

  Widget beginSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    return toggleSessionButton(
      onPressed: () => readSession.start(),
      backgroundColor: CupertinoColors.systemGreen,
      text: 'Begin Session',
    );
  }

  Widget endSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    final DateTime? startTime = ref.read(sessionStartTimeProvider);

    return toggleSessionButton(
      onPressed: () {
        readSession.stop();
        UpdateProgressDialogPage.show(
          ref,
          widget.book,
          startTime: startTime,
          initialEndTime: DateTime.now(),
        );
      },
      backgroundColor: CupertinoColors.systemOrange,
      text: 'End Session',
    );
  }

  Widget cancelSessionButton() {
    final SessionStartTime readSession =
        ref.read(sessionStartTimeProvider.notifier);
    return toggleSessionButton(
      onPressed: () => readSession.stop(),
      backgroundColor: CupertinoColors.systemRed,
      text: 'Cancel Session',
    );
  }

  Widget toggleSessionButton({
    required void Function() onPressed,
    required Color backgroundColor,
    required String text,
  }) =>
      CupertinoButton(
        onPressed: () {
          onPressed();
          repaint();
        },
        color: backgroundColor,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: 170,
          height: 88,
          child: Center(
            child: Text(text, style: TextStyles.h2, textAlign: TextAlign.center),
          ),
        ),
      );

  Widget segmentDisplay() {
    final DateTime? currStartTime = ref.read(sessionStartTimeProvider);
    final Color backgroundColor =
        sessionInProgress ? CupertinoColors.systemGreen.withAlpha((0.2 * 255).toInt()) : CupertinoColors.systemGrey.withAlpha((0.2 * 255).toInt());
    Widget border({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey, width: 8),
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.all(20),
        child: child,
      );
    }

    final clockFace = SevenSegmentDisplay(
      value: duration(currStartTime),
      backgroundColor: CupertinoColors.white.withAlpha(0),
      segmentStyle: HexSegmentStyle(
        segmentBaseSize: const Size(.85, 3.0),
        disabledColor: Color.lerp(backgroundColor, CupertinoColors.systemGrey, .3),
        enabledColor: CupertinoColors.black,
      ),
    );

    return border(child: clockFace);
  }

  Timer? _timer;

  int timerNum = 0;

  void updateTimer() {
    if (sessionInProgress) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), repaint);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void repaint([dynamic _]) => mounted ? setState(() {}) : {};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String duration(DateTime? currStartTime) {
    if (!sessionInProgress) return '**:**';
    final Duration elapsedTime = DateTime.now().difference(currStartTime!);
    final String minutes = elapsedTime.inMinutes.pad(2);
    final String seconds = (elapsedTime.inSeconds % 60).pad(2);
    return '$minutes:$seconds';
  }

  Widget progressHistory() {
    final List<ProgressEvent> progressEvents = widget.book.progressHistory;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 270),
          child: Column(children: [
            title(),
            if (progressEvents.isEmpty)
              Text('None', style: TextStyles.h2)
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Table(
                    columnWidths: const {0: FixedColumnWidth(110)},
                    children: progressEvents.mapL(
                      (ev) => TableRow(children: [
                        Text(TimeHelpers.monthDayYear(ev.end)),
                        Text(TimeHelpers.hourMinuteAmPm(ev.end)),
                        Text('${widget.book.intPercentProgressAt(ev)}%'),
                        Text(ev.stringWSuffix),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget title() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.black)),
      ),
      padding: const EdgeInsets.only(bottom: 2),
      margin: const EdgeInsets.only(bottom: 12),
      child: Text('Progress Events', style: TextStyles.h1),
    );
  }
}

