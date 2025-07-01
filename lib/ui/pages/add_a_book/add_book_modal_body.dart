import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'search_results.dart';

class AddBookModalBody extends ConsumerStatefulWidget {
  const AddBookModalBody({super.key});

  static final SimpleLogger log = SimpleLogger(prefix: 'AddBookModalBody');

  @override
  ConsumerState<AddBookModalBody> createState() => _AddBookModalBodyState();
}

class _AddBookModalBodyState extends ConsumerState<AddBookModalBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _bookSearchTitle(),
          _searchBar(),
          SearchResults(),
        ],
      ),
    );
  }

  Widget _bookSearchTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Book Search', style: TextStyles.h1),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: CupertinoSearchTextField(
        controller: _controller,
        placeholder: 'Book title...',
        onSubmitted: _search,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        style: TextStyle(color: CupertinoColors.black),
      ),
    );
  }

  void _search(String text) {
    AddBookModalBody.log('searching for: $text');
    final BookSearchResultsNotifier results =
        ref.read(bookSearchResultsProvider.notifier);
    results.notify(BookSearchResults.loading);
    BookUniverseService.search(text, results);
  }
}
