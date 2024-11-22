import 'package:flutter/material.dart';

class ReadingProgressIndicator extends StatelessWidget {
  const ReadingProgressIndicator({
    required this.progressPercent,
  });

  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final double width = 60;
    return SizedBox(
      width: width + 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          progressBar(width),
          Text('$progressPercent%'),
        ],
      ),
    );
  }

  Widget progressBar(double width) {
    return SizedBox(
      height: 12,
      // Recall: later children are placed *on top* of prior children.
      child: Stack(children: [colors(width), border(width)]),
    );
  }

  Widget colors(double width) {
    final double scale = .94;
    final double scaledWidthPerPercent = width / 100 * scale;
    final double readWidth = progressPercent * scaledWidthPerPercent;
    final double unreadWidth = (100 - progressPercent) * scaledWidthPerPercent;
    return Padding(
      padding: const EdgeInsets.only(left: 1, top: 1, bottom: 1, right: 3),
      child: Row(children: [
        if (progressPercent > 0)
          Container(
            height: 12,
            width: readWidth,
            color: Colors.green,
            padding: EdgeInsets.zero,
          ),
        if (progressPercent < 100)
          Container(
            height: 12,
            width: unreadWidth,
            color: Colors.orange,
            padding: EdgeInsets.zero,
          ),
      ]),
    );
  }

  Widget border(double width) {
    return Container(
      width: width - 2,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
