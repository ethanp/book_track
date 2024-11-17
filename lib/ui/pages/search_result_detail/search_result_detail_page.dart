import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchResultDetailPage extends ConsumerStatefulWidget {
  const SearchResultDetailPage(this.book);

  final Book book;

  @override
  ConsumerState createState() => _SearchResultDetailPage();
}

class _SearchResultDetailPage extends ConsumerState<SearchResultDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: ColorPalette().appBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          coverArt(),
          bookMetadata(),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                foregroundColor: Colors.black,
                elevation: 2,
              ),
              child: Text('Add to reading list'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget bookMetadata() {
    return Column(children: [
      keyValueText('Title: ', widget.book.title),
      keyValueText('Author: ', widget.book.author ?? 'Author unknown'),
      keyValueText(
          'Year First Published: ', widget.book.yearFirstPublished.toString()),
      if (widget.book.bookLengthPgs != null)
        keyValueText('Length: ', widget.book.bookLengthPgs!),
    ]);
  }

  late final Future<Uint8List?> futureCoverArtMedSize;

  @override
  void initState() {
    futureCoverArtMedSize = BookUniverseService.getCoverArtSizeM(widget.book);
    super.initState();
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
