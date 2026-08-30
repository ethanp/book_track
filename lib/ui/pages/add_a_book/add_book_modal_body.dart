import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'manual_book_form.dart';
import 'search_results.dart';

const _log = ELogger('AddBookModalBody');

class const AddBookModalBody() extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddBookModalBody> createState() => _AddBookModalBodyState();
}

class _AddBookModalBodyState() extends ConsumerState<AddBookModalBody> {
  late final TextEditingController _controller;
  bool _showManualForm = false;

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
      child: _showManualForm ? manualFormView() : searchView(),
    );
  }

  Widget searchView() {
    return Column(
      children: [
        bookSearchTitle(),
        searchBar(),
        manualAddButton(),
        SearchResults(),
      ],
    );
  }

  Widget manualFormView() {
    return ManualBookForm(
      onBackActivated: () => setState(() => _showManualForm = false),
    );
  }

  Widget bookSearchTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Book Search', style: AppTextStyles.h1),
    );
  }

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Book title...',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: search,
        style: AppTextStyles.body,
      ),
    );
  }

  Widget manualAddButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextButton(
        onPressed: () => setState(() => _showManualForm = true),
        child: Text(
          "Can't find your book? Add it manually",
          style: AppTextStyles.valueButton.copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void search(String text) {
    _log.log('searching for: $text');
    final BookSearchResultsNotifier results = ref.read(
      bookSearchResultsProvider.notifier,
    );
    results.notify(BookSearchResults.loading);
    BookUniverseService.search(text, results);
  }
}
