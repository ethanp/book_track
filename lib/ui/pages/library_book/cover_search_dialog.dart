import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_cover_search.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

/// Shows up to [BookCoverSearch.maxCovers] book-shaped covers found for the
/// book; returns the one picked.
class const CoverSearchDialog(final LibraryBook libraryBook)
    extends StatefulWidget {
  static const _coverWidth = 96.0;

  static Future<Uint8List?> show(
    BuildContext context,
    LibraryBook libraryBook,
  ) => showDialog<Uint8List>(
    context: context,
    builder: (context) => CoverSearchDialog(libraryBook),
  );

  @override
  State<CoverSearchDialog> createState() => _CoverSearchDialogState();
}

class _CoverSearchDialogState() extends State<CoverSearchDialog> {
  late final Future<List<Uint8List>> _foundCovers = BookCoverSearch(
    widget.libraryBook,
  ).topCovers();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Covers for ${widget.libraryBook.book.title}'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Uint8List>>(
          future: _foundCovers,
          builder: (context, snapshot) => _searchOutcome(snapshot),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _searchOutcome(AsyncSnapshot<List<Uint8List>> snapshot) {
    if (snapshot.hasError) {
      return _message('Cover search failed: ${snapshot.error}');
    }
    final List<Uint8List>? covers = snapshot.data;
    if (covers == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (covers.isEmpty) return _message('No book-shaped covers found.');
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: covers.mapL(_pickableCover),
      ),
    );
  }

  Widget _message(String text) =>
      Text(text, style: const TextStyle(color: EColors.textMuted));

  Widget _pickableCover(Uint8List coverArt) {
    final Size pixelSize = BookCover.pixelSizeOf(coverArt)!;
    return InkWell(
      onTap: () => Navigator.pop(context, coverArt),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookCover(
            width: CoverSearchDialog._coverWidth,
            height:
                CoverSearchDialog._coverWidth /
                BookCover.aspectRatioOf(coverArt),
            bytes: coverArt,
          ),
          Text(
            '${pixelSize.width.round()}×${pixelSize.height.round()}',
            style: const TextStyle(fontSize: 11, color: EColors.textMuted),
          ),
        ],
      ),
    );
  }
}
