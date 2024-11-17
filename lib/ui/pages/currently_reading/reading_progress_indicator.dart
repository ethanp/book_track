import 'package:flutter/material.dart';

class ReadingProgressIndicator extends StatelessWidget {
  const ReadingProgressIndicator({
    required this.progressPercent,
  });

  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final double width = 70;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                if (progressPercent > 0)
                  Container(
                    height: 12,
                    width: width / 100 * progressPercent - 1,
                    color: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
                Container(
                  height: 12,
                  width: width / 100 * (100 - progressPercent) - 2,
                  color: Colors.orange,
                ),
              ]),
            ),
          ),
          Text('$progressPercent%'),
        ],
      ),
    );
  }
}
