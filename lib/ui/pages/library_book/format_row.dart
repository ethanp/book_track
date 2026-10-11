import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

import 'library_book_detail_card.dart';

class const FormatRow({
  required final LibraryBookFormat format,
  required final LibraryBook libraryBook,
  required final VoidCallback onLengthEditActivated,
  final VoidCallback? onDeleteActivated,
}) extends StatelessWidget {
  Color get _formatColor => format.format.color;

  IconData get _formatIcon => switch (format.format) {
    BookFormat.audiobook => Icons.headphones,
    BookFormat.eBook => Icons.phone_iphone,
    BookFormat.paperback => Icons.menu_book_outlined,
    BookFormat.hardcover => Icons.menu_book,
  };

  @override
  Widget build(BuildContext context) {
    return LibraryBookDetailCard(
      icon: _formatIcon,
      iconColor: _formatColor,
      title: format.format.label,
      subtitle: GestureDetector(
        onTap: onLengthEditActivated,
        child: Text(
          format.lengthDisplay,
          style: TextStyle(
            fontSize: 13,
            color: format.hasLength ? EColors.textMuted : EColors.accentGlow,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit length',
            onPressed: onLengthEditActivated,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          if (onDeleteActivated != null)
            IconButton(
              tooltip: 'Delete format',
              onPressed: onDeleteActivated,
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: EColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}
