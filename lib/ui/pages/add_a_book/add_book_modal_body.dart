import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'manual_book_form.dart';
import 'search_results.dart';

class AddBookModalBody extends ConsumerStatefulWidget {
  const AddBookModalBody();

  static final SimpleLogger log = SimpleLogger(prefix: 'AddBookModalBody');

  @override
  ConsumerState<AddBookModalBody> createState() => _AddBookModalBodyState();
}

class _AddBookModalBodyState extends ConsumerState<AddBookModalBody> {
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
        onBack: () => setState(() => _showManualForm = false));
  }

  Widget bookSearchTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('Book Search', style: TextStyles.h1),
    );
  }

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: CupertinoSearchTextField(
        controller: _controller,
        placeholder: 'Book title...',
        onSubmitted: search,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        style: TextStyle(color: CupertinoColors.black),
      ),
    );
  }

  Widget manualAddButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _showManualForm = true),
        child: Text(
          "Can't find your book? Add it manually",
          style: TextStyles.value.copyWith(
            color: CupertinoColors.activeBlue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void search(String text) {
    AddBookModalBody.log('searching for: $text');
    final BookSearchResultsNotifier results =
        ref.read(bookSearchResultsNotifierProvider.notifier);
    results.notify(BookSearchResults.loading);
    BookUniverseService.search(text, results);
  }
}
