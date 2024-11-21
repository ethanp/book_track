import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultDetailPage extends ConsumerStatefulWidget {
  const SearchResultDetailPage(this.book);

  final OpenLibraryBook book;

  @override
  ConsumerState createState() => _SearchResultDetailPage();
}

class _SearchResultDetailPage extends ConsumerState<SearchResultDetailPage> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.book.title),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          coverArt(),
          bookMetadata(),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Text(
                  "I'm reading this in",
                  style: TextStyles().h1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _saving
                      ? CircularProgressIndicator()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: BookFormat.values.mapL(typeButton),
                        ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget typeButton(BookFormat bookType) {
    return ElevatedButton(
      onPressed: () async {
        setState(() => _saving = true);
        try {
          await SupabaseLibraryService.addBook(widget.book, bookType);
        } catch (error) {
          if (mounted) context.showSnackBar('$error\n${error.runtimeType}');
        } finally {
          setState(() => _saving = false);
        }
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: Colors.black,
        backgroundColor: switch (bookType) {
          BookFormat.audiobook => Colors.orange[400],
          BookFormat.eBook => Colors.blue[400],
          BookFormat.paperback => Colors.red[300],
          BookFormat.hardcover => Colors.green[200],
        },
      ),
      child: Text(bookType.name),
    );
  }

  Widget bookMetadata() {
    return Column(children: [
      keyValueText('Title: ', widget.book.title),
      keyValueText('Author: ', widget.book.firstAuthor),
      keyValueText(
          'Year First Published: ', widget.book.yearFirstPublished.toString()),
      if (widget.book.numPagesMedian != null)
        keyValueText('Length: ', widget.book.numPagesMedian!.toString()),
    ]);
  }

  late final Future<Uint8List?> futureCoverArtMedSize;

  @override
  void initState() {
    super.initState();
    futureCoverArtMedSize =
        BookUniverseService.downloadMedSizeCover(widget.book);
  }

  @override
  void dispose() {
    futureCoverArtMedSize.ignore();
    super.dispose();
  }

  Widget coverArt() {
    return FutureBuilder(
      future: futureCoverArtMedSize,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for the data
        // Render the image if data is not null
        // Show a blank box if the data is null
        if (snapshot.connectionState == ConnectionState.waiting) {
          return coverArtMissingPlaceholder(loading: true);
        } else if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!);
        } else {
          return coverArtMissingPlaceholder(loading: false);
        }
      },
    );
  }

  Container coverArtMissingPlaceholder({required bool loading}) {
    return Container(
      height: 200,
      width: 150,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: loading
            ? CircularProgressIndicator()
            : SizedBox(
                width: 110,
                child: Text(
                  'No cover art found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ),
      ),
    );
  }

  Widget keyValueText(String key, String value) {
    final TextStyle black = TextStyles().h2;
    final TextStyle bold = black.copyWith(fontWeight: FontWeight.w800);
    final Widget keyWidget = SizedBox(
      width: 90,
      child: Text(key, style: bold, maxLines: 3, textAlign: TextAlign.right),
    );
    final Widget valueWidget = SizedBox(
      width: 200,
      child: Text(value, style: black, maxLines: 3),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [keyWidget, SizedBox(width: 16), valueWidget],
      ),
    );
  }
}
