import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_book_service.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editable_book_property.dart';
import 'format_updater.dart';

class BookPropertiesEditor extends ConsumerStatefulWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  ConsumerState createState() => _EditableBookPropertiesState();
}

class _EditableBookPropertiesState extends ConsumerState<BookPropertiesEditor> {
  static final SimpleLogger log = SimpleLogger(prefix: 'BookPropertiesEditor');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The point of this block is to re-render this widget when
    // an inner widget (eg. the buttons) modifies the data shown by this widget.
    // The way it works, is anyone (e.g. field-updater) `invalidate()`s the
    // provider, which triggers `setState()` in this callback.
    ref.watch(userLibraryProvider).whenData((library) => setState(() {}));
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
      value: widget.libraryBook.bookLengthStringWSuffix,
      defaultValue: widget.libraryBook.bookLengthString,
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
      child: Row(
        children: [
          SizedBox(width: 9),
          Text('Format: ', style: TextStyles().title),
          SizedBox(width: 7.3),
          FormatUpdater(
            widget.libraryBook.bookFormat,
            (BookFormat format) =>
                SupabaseLibraryService.updateFormat(widget.libraryBook, format),
          ),
        ],
      ),
    );
  }
}
