import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/search_result_detail/search_result_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'results_count.dart';

class SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookSearchResult? searchResult = ref.watch(bookSearchResultsProvider);
    if (searchResult == null) {
      return SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Expanded(
      child: Column(
        children: [
          ResultsCount(shownCount: 10, fullCount: 888),
          Expanded(
            child: ListView(
              children: searchResult.books.mapL((book) => item(book, ref)),
            ),
          ),
        ],
      ),
    );
  }

  Widget item(Book book, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: InkWell(
        child: Material(
          elevation: .3,
          child: Row(
            children: [
              coverArt(book),
              Flexible(child: bookInfo(book)),
            ],
          ),
        ),
        onTap: () => ref.context.push(SearchResultDetailPage(book)),
      ),
    );
  }

  Widget coverArt(Book book) {
    return SizedBox(
      width: 50,
      child: book.coverArtS == null ? null : Image.memory(book.coverArtS!),
    );
  }

  Widget bookInfo(Book book) {
    final String subtitle =
        [book.bookType, book.bookLengthPgs].where((v) => v != null).join(' ');
    final title = Text(
      book.title,
      maxLines: 3,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
    final author = Text(
      book.author ?? 'No author listed',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: Colors.grey[800],
      ),
    );
    final otherInfo = [
      if (subtitle.isNotEmpty)
        Text(
          subtitle,
          style: TextStyle(
            fontWeight: FontWeight.w400,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, author, ...otherInfo],
    );
  }
}
