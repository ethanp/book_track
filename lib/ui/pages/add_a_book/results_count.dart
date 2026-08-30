import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

class const ResultsCount(final BookSearchResults searchResult)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Showing ', style: AppTextStyles.h2Skinny),
          TextSpan(
            text: '${searchResult.books.length}',
            style: AppTextStyles.h2Fat,
          ),
          TextSpan(text: ' items, out of ', style: AppTextStyles.h2Skinny),
          TextSpan(
            text: '${searchResult.fullResultCount}',
            style: AppTextStyles.h2Fat,
          ),
        ],
      ),
    );
  }
}
