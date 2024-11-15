import 'dart:async';

import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segment_display/segment_display.dart';

class SessionTimer extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimer> {
  bool get sessionInProgress => ref.watch(sessionStartTimeProvider) != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        toggleButton(),
        segmentDisplay(),
      ]),
    );
  }

  Widget toggleButton() {
    final SessionStartTime read = ref.read(sessionStartTimeProvider.notifier);
    return sessionInProgress
        ? ElevatedButton(
            onPressed: () => read.stop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Stop Session'),
          )
        : ElevatedButton(
            onPressed: () => read.start(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
            child: Text('Start Session'),
          );
  }

  Widget segmentDisplay() {
    final DateTime? currStartTime = ref.read(sessionStartTimeProvider);
    reloadEverySecond();
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

  void reloadEverySecond() {
    if (sessionInProgress) {
      Timer.periodic(
        Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  String duration(DateTime? currStartTime) {
    if (!sessionInProgress) return '**:**';
    final duration = DateTime.now().difference(currStartTime!);
    String padded(int i) => i.toString().padLeft(2, '0');
    return '${padded(duration.inMinutes)}:${padded(duration.inSeconds % 60)}';
  }
}
