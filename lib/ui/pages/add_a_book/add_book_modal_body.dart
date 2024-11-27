import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'search_results.dart';

class AddBookModalBody extends ConsumerWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          bookSearchTitle(),
          searchBar(ref),
          SearchResults(),
        ],
      ),
    );
  }

  Widget bookSearchTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Book Search', style: TextStyles().h1),
    );
  }

  Widget searchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: CupertinoSearchTextField(
        controller: _controller,
        placeholder: 'Book title...',
        onSubmitted: (str) => search(str, ref),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        style: TextStyle(color: CupertinoColors.black),
      ),
    );
  }

  void search(String text, WidgetRef ref) {
    print('searching for: $text');
    final BookSearchResults results =
        ref.read(bookSearchResultsProvider.notifier);
    results.update(BookSearchResult.loading);
    BookUniverseService.search(text, results);
  }
}
