import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';

class ResultsCount extends StatelessWidget {
  ResultsCount(BookSearchResults searchResult)
      : shownCount = searchResult.books.length,
        fullCount = searchResult.fullResultCount;

  final int shownCount;
  final int fullCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Showing ',
              style: TextStyles.h2Skinny,
            ),
            TextSpan(
              text: '$shownCount',
              style: TextStyles.h2Fat,
            ),
            TextSpan(
              text: ' items, out of ',
              style: TextStyles.h2Skinny,
            ),
            TextSpan(
              text: '$fullCount',
              style: TextStyles.h2Fat,
            ),
          ],
        ),
      ),
    );
  }
}
