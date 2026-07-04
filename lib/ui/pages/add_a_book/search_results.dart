import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/search_result_detail/search_result_detail_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'results_count.dart';

class SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookSearchResults searchResult =
        ref.watch(bookSearchResultsNotifierProvider);
    if (searchResult.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }
    if (searchResult.failure != null) {
      return Column(
        children: [
          Text(
            'Request to OpenLibrary failed. Please search again.',
            style: AppTextStyles.h4,
          ),
          Text('\n${searchResult.failure}', style: AppTextStyles.bodySecondary),
        ],
      );
    }
    return Expanded(
      child: Column(children: [
        ResultsCount(searchResult),
        Expanded(
          child: ListView(
            children: searchResult.books.mapL(
              (book) => _resultBook(book, ref),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _resultBook(OpenLibraryBook book, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: CupertinoListTile(
        leading: _coverArt(book),
        title: Text(
          book.title,
          maxLines: 3,
          style: AppTextStyles.h5,
        ),
        subtitle: Text(
          book.firstAuthor,
          style: AppTextStyles.bodySecondary.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        onTap: () => ref.context.push(SearchResultDetailPage(book)),
      ),
    );
  }

  Widget _coverArt(OpenLibraryBook book) {
    return SizedBox(
      width: 50,
      child: book.coverArtS.map(Image.memory),
    );
  }
}
