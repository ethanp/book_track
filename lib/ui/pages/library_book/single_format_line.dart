import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_format_length_dialog.dart';
import 'formats_section.dart';

class const SingleFormatLine({
  required final LibraryBook libraryBook,
  required final LibraryBookFormat format,
}) extends ConsumerWidget {
  IconData get _formatIcon => switch (format.format) {
    BookFormat.audiobook => Icons.headphones,
    BookFormat.eBook => Icons.phone_iphone,
    BookFormat.paperback => Icons.menu_book_outlined,
    BookFormat.hardcover => Icons.menu_book,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(_formatIcon, color: format.format.color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: _valueAndLabel()),
        IconButton(
          tooltip: 'Add format',
          onPressed: () =>
              FormatsSection.showAddFormat(context, ref, libraryBook),
          icon: const Icon(Icons.add_circle_outline, size: 18),
        ),
        IconButton(
          tooltip: 'Edit length',
          onPressed: () => EditFormatLengthDialog.show(
            context: context,
            ref: ref,
            format: format,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ],
    );
  }

  Widget _valueAndLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: format.format.label),
              TextSpan(
                text: '  ${format.lengthDisplay}',
                style: format.hasLength
                    ? null
                    : const TextStyle(color: EColors.accentGlow),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Text(
          'Format',
          style: TextStyle(fontSize: 13, color: EColors.textMuted),
        ),
      ],
    );
  }
}
