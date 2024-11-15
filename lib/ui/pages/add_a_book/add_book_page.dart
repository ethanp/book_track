import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/design.dart';
import 'package:book_track/ui/pages/search_result_detail/search_result_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddBookPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Scaffold(appBar: appBar(), body: body(ref));

  PreferredSizeWidget appBar() {
    return AppBar(
      title: Text('Add a book'),
      backgroundColor: ColorPalette.appBarColor,
    );
  }

  Widget body(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          bookSearchTitle(),
          searchBar(ref),
          searchResults(ref),
        ],
      ),
    );
  }

  Widget bookSearchTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Book Search', style: TextStyles.h1),
    );
  }

  Widget searchBar(WidgetRef ref) {
    return SearchAnchor(
      builder: (context, controller) => SearchBar(
        controller: controller,
        onTap: () => print('tapped: ${controller.text}'),
        onSubmitted: (str) => search(controller, ref),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.abc),
        ),
        trailing: [
          TextButton(
            onPressed: () => search(controller, ref),
            child: const Icon(Icons.search),
          )
        ],
      ),
      suggestionsBuilder: (context, controller) => [],
    );
  }

  void search(SearchController controller, WidgetRef ref) {
    print('searching for: ${controller.text}');
    final BookSearchResults results =
        ref.read(bookSearchResultsProvider.notifier);
    BookUniverseService.search(controller.text, results);
  }

  Widget searchResults(WidgetRef ref) => ListView(
      shrinkWrap: true,
      children: ref.watch(bookSearchResultsProvider).books.mapL((Book r) =>
          ListTile(
              title: Text(r.title),
              leading: Text(r.author),
              subtitle: Text('${r.bookType} ${r.bookLength}'),
              onTap: () => ref.context.push(SearchResultDetailPage(r)))));
}
