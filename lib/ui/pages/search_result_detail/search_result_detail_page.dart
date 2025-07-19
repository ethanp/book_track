import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cover_art.dart';

class SearchResultDetailPage extends ConsumerStatefulWidget {
  const SearchResultDetailPage(this.book);

  final OpenLibraryBook book;

  @override
  ConsumerState createState() => _SearchResultDetailPage();
}

class _SearchResultDetailPage extends ConsumerState<SearchResultDetailPage> {
  static SimpleLogger log = SimpleLogger(prefix: 'SearchResultDetailPage');

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.book.title),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            CoverArt(widget.book),
            bookMetadata(),
            formatButtons(),
          ]),
        ),
      ),
    );
  }

  Widget formatButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Text("I'm reading this in", style: TextStyles.h1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _saving
                ? const CupertinoActivityIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: BookFormat.values.mapL(typeButton)),
          ),
        ],
      ),
    );
  }

  Widget typeButton(BookFormat bookType) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CupertinoButton(
        onPressed: () => addBookToLibrary(bookType),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: switch (bookType) {
          BookFormat.audiobook => CupertinoColors.systemOrange,
          BookFormat.eBook => CupertinoColors.systemBlue,
          BookFormat.paperback => CupertinoColors.systemRed,
          BookFormat.hardcover => CupertinoColors.systemGreen,
        },
        child: Text(
          bookType.name,
          style: TextStyles.h4.copyWith(fontSize: 13),
        ),
      ),
    );
  }

  Future<void> addBookToLibrary(BookFormat bookType) async {
    setState(() => _saving = true);
    try {
      await SupabaseLibraryService.addBook(widget.book, bookType);
    } catch (error, stack) {
      log('(${error.runtimeType}) $error $stack');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        context.popUntilFirst();
      }
      ref.invalidate(userLibraryProvider);
    }
  }

  Widget bookMetadata() {
    return Column(children: [
      keyValueText('Title: ', widget.book.title),
      keyValueText('Author: ', widget.book.firstAuthor),
      keyValueText('First Pub\'d: ', widget.book.yearFirstPublished.toString()),
      if (widget.book.numPagesMedian != null)
        keyValueText('Pages (est): ', widget.book.numPagesMedian!.toString()),
    ]);
  }

  Widget keyValueText(String key, String value) {
    final TextStyle black = TextStyles.h3;
    final TextStyle bold = black.copyWith(fontWeight: FontWeight.w700);
    final Widget keyWidget = SizedBox(
      width: 90,
      child: Text(
        key,
        style: bold,
        maxLines: 3,
        textAlign: TextAlign.right,
      ),
    );
    final Widget valueWidget = SizedBox(
      width: 200,
      child: Text(
        value,
        style: black,
        maxLines: 3,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          keyWidget,
          SizedBox(width: 16),
          valueWidget,
        ],
      ),
    );
  }
}
