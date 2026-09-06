import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_book_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_book_detail_card.dart';

const _log = ELogger('BookPropertiesEditor');

class const BookPropertiesEditor(final LibraryBook libraryBook)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _AuthorCard(libraryBook),
    );
  }
}

class const _AuthorCard(final LibraryBook libraryBook) extends StatefulWidget {
  @override
  State<_AuthorCard> createState() => _AuthorCardState();
}

class _AuthorCardState() extends State<_AuthorCard> {
  bool _editing = false;
  late final TextEditingController _author = TextEditingController(
    text: widget.libraryBook.book.author ?? '',
  );

  @override
  void dispose() {
    _author.dispose();
    super.dispose();
  }

  String get _displayedAuthor =>
      widget.libraryBook.book.author ?? 'unknown';

  Future<void> _commitAuthor(WidgetRef ref) async {
    final author = _author.text.trim();
    setState(() => _editing = false);
    if (author.isEmpty) return;
    _log.log('updating author to $author');
    await SupabaseBookService.updateAuthor(widget.libraryBook.book, author);
    ref.invalidate(userLibraryProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return LibraryBookDetailCard(
          icon: Icons.person_outline,
          iconColor: EColors.textMuted,
          title: 'Author',
          subtitle: _editing
              ? TextField(
                  controller: _author,
                  autofocus: true,
                  style: AppTextStyles.value,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _commitAuthor(ref),
                )
              : Text(
                  _displayedAuthor,
                  style: TextStyle(fontSize: 13, color: EColors.textMuted),
                ),
          trailing: _editing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Save author',
                      onPressed: () => _commitAuthor(ref),
                      icon: const Icon(Icons.check, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: () => setState(() => _editing = false),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                )
              : IconButton(
                  tooltip: 'Edit author',
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
        );
      },
    );
  }
}
