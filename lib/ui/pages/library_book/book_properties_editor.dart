import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_book_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editable_book_property.dart';

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
}
