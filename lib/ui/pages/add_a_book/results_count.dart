import 'package:book_track/ui/design.dart';
import 'package:flutter/material.dart';

class ResultsCount extends StatelessWidget {
  const ResultsCount({
    required this.shownCount,
    required this.fullCount,
  });

  final int shownCount;
  final int fullCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Showing the first ',
              style: TextStyles().h2Skinny,
            ),
            TextSpan(
              text: '$shownCount',
              style: TextStyles().h2Fat,
            ),
            TextSpan(
              text: ' items, out of ',
              style: TextStyles().h2Skinny,
            ),
            TextSpan(
              text: '$fullCount',
              style: TextStyles().h2Fat,
            ),
          ],
        ),
      ),
    );
  }
}
