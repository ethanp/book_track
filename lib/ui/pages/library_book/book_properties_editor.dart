import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_book_service.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editable_book_property.dart';

class BookPropertiesEditor extends ConsumerStatefulWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  ConsumerState createState() => _EditableBookPropertiesState();
}

class _EditableBookPropertiesState extends ConsumerState<BookPropertiesEditor> {
  BookFormat? _format;
  static final SimpleLogger log = SimpleLogger(prefix: 'BookPropertiesEditor');

  @override
  void initState() {
    super.initState();
    _format = widget.libraryBook.bookFormat;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The point of this block is to update this widget state when
    // an inner widget (eg. the buttons) modifies the data shown here.
    // The way it works, is the button invalidate()s the provider
    // (internally), which triggers this to callback.
    ref.watch(userLibraryProvider).whenData(
          (libraryBooks) => setState(() {
            bool isThisBook(LibraryBook book) =>
                book.supaId == widget.libraryBook.supaId;
            _format = libraryBooks.firstWhere(isThisBook).bookFormat;
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          author(),
          length(),
          bookFormat(),
        ],
      ),
    );
  }

  Widget author() {
    return EditableBookProperty(
      title: 'Author',
      value: widget.libraryBook.book.author ?? 'unknown',
      onPressed: updateAuthor,
    );
  }

  void updateAuthor(String text) async {
    log('updating author to $text');
    await SupabaseBookService.updateAuthor(widget.libraryBook.book, text);
    ref.invalidate(userLibraryProvider);
  }

  Widget length() {
    return EditableBookProperty(
      title: 'Length',
      value: widget.libraryBook.bookLengthString,
      defaultValue: widget.libraryBook.bookLengthCount,
      onPressed: updateLength,
    );
  }

  void updateLength(String text) async {
    final int? len = widget.libraryBook.parseLengthText(text);
    if (len == null) return log('invalid length: $text');
    log('updating length to $text');
    await SupabaseLibraryService.updateLength(widget.libraryBook, len);
    ref.invalidate(userLibraryProvider);
  }

  Widget bookFormat() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Book format: ', style: TextStyles().h4),
          SizedBox(height: 12),
          formatUpdater(),
        ],
      ),
    );
  }

  Widget formatUpdater() {
    // Note: We have to wrap BookFormat with Renderable format because
    // nullable types are not allowed as a type param for
    // CupertinoSegmentedControl.
    return CupertinoSegmentedControl<RenderableFormat>(
      onValueChanged: updateFormat,
      groupValue: RenderableFormat(_format),
      children: {
        for (final BookFormat? format
            in List.from(BookFormat.values)..add(null))
          RenderableFormat(format): Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            child: Text(
              format?.name ?? 'unknown',
              style: const TextStyle(fontSize: 11),
            ),
          )
      },
    );
  }

  void updateFormat(RenderableFormat selectedFormat) {
    setState(() => _format = selectedFormat.bookFormat);
    SupabaseLibraryService.updateFormat(
        widget.libraryBook, selectedFormat.bookFormat);
    ref.invalidate(userLibraryProvider);
  }
}
