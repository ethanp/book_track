import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_format_sheet.dart';
import 'edit_format_length_dialog.dart';
import 'format_row.dart';
import 'reassign_events_sheet.dart';

class const FormatsSection(final LibraryBook libraryBook)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formats = libraryBook.formats;
    if (formats.length == 1) return const SizedBox.shrink();
    return _formatsColumn(context, ref, formats);
  }

  static Future<void> showAddFormat(
    BuildContext context,
    WidgetRef ref,
    LibraryBook libraryBook,
  ) async {
    final existingTypes = libraryBook.formats.map((f) => f.format).toSet();

    final result = await showDialog<(BookFormat, int)?>(
      context: context,
      builder: (context) => AddFormatSheet(existingTypes: existingTypes),
    );

    if (result == null) return;
    final libraryRepository = await ref.read(libraryRepositoryProvider.future);
    await libraryRepository.formats.addFormat(
      libraryBookId: libraryBook.id,
      format: result.$1,
      length: result.$2,
    );
    ref.invalidate(userLibraryProvider);
  }

  void _editFormatLength(
    BuildContext context,
    WidgetRef ref,
    LibraryBookFormat format,
  ) {
    EditFormatLengthDialog.show(context: context, ref: ref, format: format);
  }

  Widget _formatsColumn(
    BuildContext context,
    WidgetRef ref,
    List<LibraryBookFormat> formats,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Formats', style: AppTextStyles.h2),
              IconButton(
                tooltip: 'Add format',
                onPressed: () =>
                    showAddFormat(context, ref, libraryBook),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (formats.isEmpty)
            Text('No formats added', style: AppTextStyles.bodySecondary)
          else
            ...formats.mapL(
              (format) => FormatRow(
                format: format,
                libraryBook: libraryBook,
                onLengthEditActivated: () =>
                    _editFormatLength(context, ref, format),
                onDeleteActivated: () =>
                    _confirmDeleteFormat(context, ref, format),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteFormat(
    BuildContext context,
    WidgetRef ref,
    LibraryBookFormat format,
  ) async {
    final hasEvents = libraryBook.progressForFormat(format).isNotEmpty;

    if (hasEvents) {
      // Need to reassign events first
      final otherFormats = libraryBook.formats.whereL(
        (otherFormat) => otherFormat.id != format.id,
      );
      if (otherFormats.isEmpty) return; // Can't delete last format

      final targetFormat = await showDialog<LibraryBookFormat?>(
        context: context,
        builder: (context) =>
            ReassignEventsSheet(format: format, otherFormats: otherFormats),
      );

      if (targetFormat != null) {
        final libraryRepository = await ref.read(
          libraryRepositoryProvider.future,
        );
        await libraryRepository.formats.reassignEvents(
          format.id,
          targetFormat.id,
        );
        await libraryRepository.formats.deleteFormat(format.id);
        ref.invalidate(userLibraryProvider);
      }
    } else {
      // No events, just confirm deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Format'),
          content: Text('Remove ${format.format.label} from this book?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: EText.section.danger),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final libraryRepository = await ref.read(
          libraryRepositoryProvider.future,
        );
        await libraryRepository.formats.deleteFormat(format.id);
        ref.invalidate(userLibraryProvider);
      }
    }
  }
}

