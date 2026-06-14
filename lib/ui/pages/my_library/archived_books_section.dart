import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/my_library/book_tile.dart';
import 'package:flutter/cupertino.dart';

class ArchivedBooksSection extends StatefulWidget {
  const ArchivedBooksSection({required this.books, super.key});

  final List<LibraryBook> books;

  @override
  State<ArchivedBooksSection> createState() => _ArchivedBooksSectionState();
}

class _ArchivedBooksSectionState extends State<ArchivedBooksSection> {
  bool _expanded = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryBook> get _filteredBooks {
    final query = _query.trim();
    if (query.isEmpty) return widget.books;
    final words = query.split(RegExp(r'\s+'));
    return widget.books.whereL((book) {
      final searchTarget = '${book.book.title} ${book.book.author ?? ''}';
      return words.every(
        (word) => RegExp(word, caseSensitive: false).hasMatch(searchTarget),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toggleButton(),
        if (_expanded) ...[
          CupertinoSearchTextField(
            controller: _searchController,
            onChanged: (query) => setState(() => _query = query),
          ),
          const SizedBox(height: 8),
          _bookList(),
        ],
      ],
    );
  }

  Widget _toggleButton() {
    return CupertinoButton(
      child: Text(
        '${_expanded ? 'Hide' : 'See'} archived books...',
        style: TextStyles.h3.copyWith(color: CupertinoColors.activeBlue),
      ),
      onPressed: () => setState(() => _expanded = !_expanded),
    );
  }

  Widget _bookList() {
    final filteredBooks = _filteredBooks;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(filteredBooks.length),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) => BookTile(filteredBooks[index], index),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(int count) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Archived ($count)',
        style: TextStyles.h1,
      ),
    );
  }
}
