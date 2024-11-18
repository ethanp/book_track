import 'dart:async';

import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segment_display/segment_display.dart';

class SessionTimerPage extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimerPage> {
  bool get sessionInProgress => ref.watch(sessionStartTimeProvider) != null;

  @override
  Widget build(BuildContext context) {
    updateTimer();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette().appBarColor,
        title: Text('Session'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(children: [
            toggleButton(),
            SizedBox(height: 50),
            segmentDisplay(),
          ]),
        ),
      ),
    );
  }

  Widget toggleButton() {
    final SessionStartTime read = ref.read(sessionStartTimeProvider.notifier);
    return sessionInProgress
        ? toggleSessionButton(
            onPressed: () => read.stop(),
            backgroundColor: Colors.orange,
            text: 'Stop Session',
          )
        : toggleSessionButton(
            onPressed: () => read.start(),
            backgroundColor: Colors.lightGreen,
            text: 'Start Session',
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
          fixedSize: Size(250, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
        ),
        child: Text(
          text,
          style: TextStyles().h1,
        ),
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
    print('canceling timer upon dispose');
    _timer?.cancel();
    super.dispose();
  }

  String duration(DateTime? currStartTime) {
    if (!sessionInProgress) return '**:**';
    final duration = DateTime.now().difference(currStartTime!);
    String padded(int i) => i.toString().padLeft(2, '0');
    return '${padded(duration.inMinutes)}:${padded(duration.inSeconds % 60)}';
  }
}
