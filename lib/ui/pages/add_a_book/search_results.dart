import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/search_result_detail/search_result_detail_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'results_count.dart';

class SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookSearchResults searchResult = ref.watch(bookSearchResultsProvider);
    if (searchResult.isLoading) {
      return SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (searchResult.failure != null) {
      return Column(
        children: [
          Text(
            'Request to OpenLibrary failed. Please search again.',
            style: TextStyles.h3,
          ),
          Text(
            '\n${searchResult.failure}',
            style: TextStyles.value,
          )
        ],
      );
    }
    return Expanded(
      child: Column(children: [
        ResultsCount(searchResult),
        Expanded(
          child: ListView(
            children: searchResult.books.mapL(
              (book) => resultBook(book, ref),
            ),
          ),
        ),
      ]),
    );
  }

  Widget resultBook(OpenLibraryBook book, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: CupertinoListTile(
        leading: coverArt(book),
        title: title(book),
        subtitle: author(book),
        onTap: () => ref.context.push(SearchResultDetailPage(book)),
      ),
    );
  }

  Widget author(OpenLibraryBook book) {
    return Text(
      book.firstAuthor,
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: CupertinoColors.systemGrey,
      ),
    );
  }

  Widget title(OpenLibraryBook book) {
    return Text(
      book.title,
      maxLines: 3,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: CupertinoColors.systemGrey,
      ),
    );
  }

  Widget coverArt(OpenLibraryBook book) {
    return SizedBox(
      width: 50,
      child: book.coverArtS.map(Image.memory),
    );
  }
}
