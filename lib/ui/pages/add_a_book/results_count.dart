import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

class ResultsCount extends StatelessWidget {
  ResultsCount(BookSearchResults searchResult)
      : shownCount = searchResult.books.length,
        fullCount = searchResult.fullResultCount;

  final int shownCount;
  final int fullCount;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Showing ', style: AppTextStyles.h2Skinny),
          TextSpan(text: '$shownCount', style: AppTextStyles.h2Fat),
          TextSpan(text: ' items, out of ', style: AppTextStyles.h2Skinny),
          TextSpan(text: '$fullCount', style: AppTextStyles.h2Fat),
        ],
      ),
    );
  }
}
