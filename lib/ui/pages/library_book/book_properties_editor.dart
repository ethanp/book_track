import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
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

class BookPropertiesEditor extends ConsumerWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;

  static final SimpleLogger log = SimpleLogger(prefix: 'BookPropertiesEditor');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-build() whenever an inner widget (eg. the buttons) invalidate()s the
    // user-library.
    ref.watch(userLibraryProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          author(ref),
          length(ref),
          bookFormat(),
        ],
      ),
    );
  }

  Widget author(WidgetRef ref) {
    return EditableBookProperty(
      title: 'Author',
      value: libraryBook.book.author ?? 'unknown',
      initialTextFieldValues: [
        TextFieldValueAndSuffix(
          libraryBook.book.author ?? 'unknown',
          null,
        )
      ],
      onPressed: (List<String> text) async {
        log('updating author to ${text[0]}');
        await SupabaseBookService.updateAuthor(libraryBook.book, text[0]);
        ref.invalidate(userLibraryProvider);
      },
    );
  }

  Widget length(WidgetRef ref) {
    final int? bookLength = libraryBook.bookLength;
    final List<TextFieldValueAndSuffix> bookLengthFieldValues =
        libraryBook.isAudiobook
            ? [
                TextFieldValueAndSuffix(bookLength?.hours ?? '0', 'hrs'),
                TextFieldValueAndSuffix(bookLength?.minutes ?? '0', 'mins'),
              ]
            : [TextFieldValueAndSuffix(bookLength?.toString() ?? '200', 'pgs')];

    return EditableBookProperty(
      title: 'Length',
      value: libraryBook.bookLengthStringWSuffix,
      initialTextFieldValues: bookLengthFieldValues,
      onPressed: (List<String> fields) => updateLength(fields, ref),
    );
  }

  void updateLength(List<String> texts, WidgetRef ref) async {
    final int? len = libraryBook.parseLengthText(texts.join(':'));
    if (len == null) return log('invalid length: $texts');
    log('updating length to $texts');
    await SupabaseLibraryService.updateLength(libraryBook, len);
    ref.invalidate(userLibraryProvider);
  }

  Widget bookFormat() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.4),
      child: Row(
        children: [
          SizedBox(width: 9),
          Text('Format: ', style: TextStyles().title),
          SizedBox(width: 7.3),
          FormatUpdater(
            libraryBook.bookFormat,
            (BookFormat newFormat) =>
                SupabaseLibraryService.updateFormat(libraryBook, newFormat),
          ),
        ],
      ),
    );
  }
}
