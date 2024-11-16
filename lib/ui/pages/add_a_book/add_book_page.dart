import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'search_results.dart';

class AddBookPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Scaffold(appBar: appBar(), body: body(ref));

  PreferredSizeWidget appBar() {
    return AppBar(
      title: Text('Add a book'),
      backgroundColor: ColorPalette().appBarColor,
    );
  }

  Widget body(WidgetRef ref) {
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
      padding: const EdgeInsets.only(bottom: 22),
      child: SearchAnchor(
        builder: (context, controller) => SearchBar(
          controller: controller,
          onTap: () => print('tapped: ${controller.text}'),
          onSubmitted: (str) => search(str, ref),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.abc),
          ),
          trailing: [
            TextButton(
              onPressed: () => search(controller.text, ref),
              child: const Icon(Icons.search),
            )
          ],
        ),
        suggestionsBuilder: (context, controller) => [],
      ),
    );
  }

  void search(String text, WidgetRef ref) {
    print('searching for: $text');
    final BookSearchResults results =
        ref.read(bookSearchResultsProvider.notifier);
    BookUniverseService.search(text, results);
  }
}
