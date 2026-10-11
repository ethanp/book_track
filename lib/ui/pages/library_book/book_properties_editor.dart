import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_book_detail_card.dart';
import 'single_format_line.dart';
import 'paste_cover_link_dialog.dart';

const _log = ELogger('BookPropertiesEditor');

class const BookPropertiesEditor(final LibraryBook libraryBook)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userLibraryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _PropertiesCard(libraryBook),
    );
  }
}

class const _PropertiesCard(final LibraryBook libraryBook)
    extends StatefulWidget {
  @override
  State<_PropertiesCard> createState() => _PropertiesCardState();
}

class _PropertiesCardState() extends State<_PropertiesCard> {
  static const _leadingIconSize = 20.0;
  static const _leadingGap = 10.0;
  static const _coverThumbWidth = 40.0;
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
    final libraryRepository = await ref.read(libraryRepositoryProvider.future);
    await libraryRepository.books.updateAuthor(widget.libraryBook.book, author);
    ref.invalidate(userLibraryProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final LibraryBookFormat? onlyFormat =
            widget.libraryBook.formats.length == 1
            ? widget.libraryBook.formats.single
            : null;
        return LibraryBookDetailSurface(
          child: Column(
            children: [
              _authorRow(ref),
              if (onlyFormat != null) ...[
                _segmentDivider(),
                SingleFormatLine(
                  libraryBook: widget.libraryBook,
                  format: onlyFormat,
                ),
              ],
              _segmentDivider(),
              _coverRow(ref),
            ],
          ),
        );
      },
    );
  }

  Widget _authorRow(WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.person, color: EColors.textMuted, size: _leadingIconSize),
        const SizedBox(width: _leadingGap),
        Expanded(child: _authorValueAndLabel(ref)),
        _authorActions(ref),
      ],
    );
  }

  Widget _authorValueAndLabel(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editing
            ? TextField(
                controller: _author,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _commitAuthor(ref),
              )
            : Text(
                _displayedAuthor,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
        const Text(
          'Author',
          style: TextStyle(fontSize: 13, color: EColors.textMuted),
        ),
      ],
    );
  }

  Widget _authorActions(WidgetRef ref) {
    if (!_editing) {
      return IconButton(
        tooltip: 'Edit author',
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.edit_outlined, size: 18),
      );
    }
    return Row(
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
    );
  }

  Widget _segmentDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ColoredBox(
        color: EColors.border,
        child: SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  Widget _coverRow(WidgetRef ref) {
    final Uint8List? coverArt = widget.libraryBook.book.coverArt;
    return Row(
      children: [
        const Icon(Icons.image, color: EColors.textMuted, size: _leadingIconSize),
        const SizedBox(width: _leadingGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                width: _coverThumbWidth,
                height: _coverThumbWidth / BookCover.aspectRatioOf(coverArt),
                bytes: coverArt,
              ),
              const Text(
                'Cover',
                style: TextStyle(fontSize: 13, color: EColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit cover',
          onPressed: () => PasteCoverLinkDialog.show(
            context: context,
            ref: ref,
            book: widget.libraryBook.book,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ],
    );
  }
}
