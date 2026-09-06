import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_book_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_format_length_dialog.dart';
import 'editable_book_property.dart';

const _log = ELogger('BookPropertiesEditor');

class const BookPropertiesEditor(final LibraryBook libraryBook)
    extends ConsumerWidget {
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
          _author(ref),
          for (final format in libraryBook.formats)
            _length(context, ref, format),
        ],
      ),
    );
  }

  Widget _author(WidgetRef ref) {
    return EditableBookProperty(
      title: 'Author',
      value: libraryBook.book.author ?? 'unknown',
      initialTextFieldValues: [
        TextFieldValueAndSuffix(libraryBook.book.author ?? 'unknown', null),
      ],
      onValuesCommitted: (List<String> text) async {
        _log.log('updating author to ${text[0]}');
        await SupabaseBookService.updateAuthor(libraryBook.book, text[0]);
        ref.invalidate(userLibraryProvider);
      },
    );
  }

  Widget _length(
    BuildContext context,
    WidgetRef ref,
    LibraryBookFormat format,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('${_lengthTitle(format)}: ', style: AppTextStyles.label),
                const SizedBox(width: 10),
                Text(
                  format.hasLength ? format.lengthDisplay : 'unknown',
                  style: AppTextStyles.value,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => EditFormatLengthDialog.show(
              context: context,
              ref: ref,
              format: format,
            ),
            child: Text('Update', style: AppTextStyles.valueButton),
          ),
        ],
      ),
    );
  }

  String _lengthTitle(LibraryBookFormat format) =>
      libraryBook.formats.length == 1
      ? 'Length'
      : '${format.format.name} length';
}
