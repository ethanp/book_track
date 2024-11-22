import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/update_progress_dialog/update_progress_dialog_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:segment_display/segment_display.dart';

class SessionTimerPage extends ConsumerStatefulWidget {
  const SessionTimerPage(this.book);

  final LibraryBook book;

  @override
  ConsumerState createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimerPage> {
  static final dateFormatter = DateFormat('MMM d, y');
  static final timeFormatter = DateFormat('h:mma');

  bool get sessionInProgress => ref.watch(sessionStartTimeProvider) != null;

  @override
  Widget build(BuildContext context) {
    updateTimer();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Session'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(children: [
            segmentDisplay(),
            SizedBox(height: 30),
            toggleButtons(),
            SizedBox(height: 80),
            sessionsToday(),
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
    final SessionStartTime read = ref.read(sessionStartTimeProvider.notifier);
    return toggleSessionButton(
      onPressed: () => read.start(),
      backgroundColor: Colors.lightGreen,
      text: 'Begin Session',
    );
  }

  Widget endSessionButton() {
    final SessionStartTime read = ref.read(sessionStartTimeProvider.notifier);
    final DateTime? startTime = ref.read(sessionStartTimeProvider);

    return toggleSessionButton(
      onPressed: () async {
        read.stop();
        await showCupertinoDialog(
          context: context,
          builder: (context) => UpdateProgressDialogPage(
            book: widget.book,
            startTime: startTime,
            initialEndTime: DateTime.now(),
          ),
        );
      },
      backgroundColor: Colors.orange,
      text: 'End Session',
    );
  }

  Widget cancelSessionButton() {
    final SessionStartTime read = ref.read(sessionStartTimeProvider.notifier);
    return toggleSessionButton(
      onPressed: () => read.stop(),
      backgroundColor: Colors.red,
      text: 'Cancel Session',
    );
  }

  Widget toggleSessionButton({
    required void Function() onPressed,
    required Color backgroundColor,
    required String text,
  }) =>
      ElevatedButton(
        onPressed: () {
          onPressed();
          repaint();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black,
          fixedSize: Size(170, 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child: Text(text, style: TextStyles().h2, textAlign: TextAlign.center),
      );

  Widget segmentDisplay() {
    final DateTime? currStartTime = ref.read(sessionStartTimeProvider);
    final Color? backgroundColor =
        sessionInProgress ? Colors.lightGreen[200] : Colors.blueGrey[100];
    Widget border({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[700]!, width: 8),
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
      backgroundColor: Colors.white.withOpacity(0),
      segmentStyle: HexSegmentStyle(
        segmentBaseSize: const Size(.85, 3.0),
        disabledColor: Color.lerp(backgroundColor, Colors.grey[400], .3),
        enabledColor: Colors.black,
      ),
    );

    return border(child: clockFace);
  }

  Timer? _timer;

  int timerNum = 0;

  void updateTimer() {
    if (sessionInProgress) {
      _timer ??= repaintEverySecond();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Timer repaintEverySecond() => Timer.periodic(Duration(seconds: 1), repaint);

  void repaint([dynamic _]) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String duration(DateTime? currStartTime) {
    if (!sessionInProgress) return '**:**';
    final duration = DateTime.now().difference(currStartTime!);
    String padded(int i) => i.toString().padLeft(2, '0');
    return '${padded(duration.inMinutes)}:${padded(duration.inSeconds % 60)}';
  }

  Widget sessionsToday() {
    final List<ProgressEvent> progressEvents = widget.book.progressHistory;
    var progressToday = progressEvents.where((e) => e.end.isToday);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Card(
        color: Colors.blueGrey[100],
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          height: 200,
          width: double.infinity,
          child: Column(children: [
            Text('Sessions today:', style: TextStyles().h1),
            if (progressToday.isEmpty)
              Text('None', style: TextStyles().h2)
            else
              Table(
                children: progressToday.mapL((ev) {
                  return TableRow(children: [
                    Text(dateFormatter.format(ev.end)),
                    Text(timeFormatter.format(ev.end)),
                    Text('${ev.progress}%'),
                  ]);
                }),
              ),
          ]),
        ),
      ),
    );
  }
}
