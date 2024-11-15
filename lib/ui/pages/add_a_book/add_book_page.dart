import 'package:book_track/ui/design.dart';
import 'package:flutter/material.dart';

class AddBookPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(appBar: appBar(), body: body()));
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      title: Text('Add a book'),
      backgroundColor: ColorPalette.appBarColor,
    );
  }

  Widget body() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          bookSearchTitle(),
          searchBar(),
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

  Widget searchBar() {
    return SearchAnchor(
      builder: (context, controller) => SearchBar(
        controller: controller,
        onTap: () => print('tapped: ${controller.text}'),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.abc),
        ),
        trailing: [searchButton(controller)],
      ),
      suggestionsBuilder: (context, controller) => [],
    );
  }

  Widget searchButton(SearchController controller) {
    return TextButton(
      onPressed: () {
        print('searching for: ${controller.text}');
      },
      child: const Icon(Icons.search),
    );
  }
}
