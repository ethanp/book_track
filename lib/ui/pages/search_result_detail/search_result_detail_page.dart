import 'package:book_track/data_model.dart';
import 'package:book_track/ui/design.dart';
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
        backgroundColor: ColorPalette.appBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          keyValueText('Title: ', widget.book.title),
          keyValueText('Author: ', widget.book.author),
          keyValueText('Year: ', widget.book.yearPublished.toString()),
          // TODO(low priority): add cover art here.
        ]),
      ),
    );
  }

  Widget keyValueText(String key, String value) {
    final TextStyle black = TextStyles.h2;
    final TextStyle bold = black.copyWith(fontWeight: FontWeight.bold);
    final Widget keyWidget = SizedBox(
      width: 60,
      child: Text(key, style: bold, maxLines: 3, textAlign: TextAlign.right),
    );
    final Widget valueWidget = SizedBox(
      width: 200,
      child: Text(value, style: black, maxLines: 3),
    );
    return Row(
      children: [keyWidget, SizedBox(width: 30), valueWidget],
    );
  }
}
