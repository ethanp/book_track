import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_format_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_format_length_dialog.dart';

class const FormatsSection(final LibraryBook libraryBook)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formats = libraryBook.formats;

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
                onPressed: () => _showAddFormatSheet(context, ref),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (formats.isEmpty)
            Text('No formats added', style: AppTextStyles.bodySecondary)
          else
            ...formats.mapL(
              (format) => _FormatRow(
                format: format,
                libraryBook: libraryBook,
                onLengthEditActivated: () => EditFormatLengthDialog.show(
                  context: context,
                  ref: ref,
                  format: format,
                ),
                onDeleteActivated: formats.length > 1
                    ? () => _confirmDeleteFormat(context, ref, format)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddFormatSheet(BuildContext context, WidgetRef ref) async {
    final existingTypes = libraryBook.formats.map((f) => f.format).toSet();

    final result = await showDialog<(BookFormat, int)?>(
      context: context,
      builder: (context) => _AddFormatSheet(existingTypes: existingTypes),
    );

    if (result != null) {
      await SupabaseFormatService.addFormat(
        libraryBookId: libraryBook.supaId,
        format: result.$1,
        length: result.$2,
      );
      ref.invalidate(userLibraryProvider);
    }
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
        (f) => f.supaId != format.supaId,
      );
      if (otherFormats.isEmpty) return; // Can't delete last format

      final targetFormat = await showDialog<LibraryBookFormat?>(
        context: context,
        builder: (context) =>
            _ReassignEventsSheet(format: format, otherFormats: otherFormats),
      );

      if (targetFormat != null) {
        await SupabaseFormatService.reassignEvents(
          format.supaId,
          targetFormat.supaId,
        );
        await SupabaseFormatService.deleteFormat(format.supaId);
        ref.invalidate(userLibraryProvider);
      }
    } else {
      // No events, just confirm deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Format'),
          content: Text('Remove ${format.format.name} from this book?'),
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
        await SupabaseFormatService.deleteFormat(format.supaId);
        ref.invalidate(userLibraryProvider);
      }
    }
  }
}

class const _FormatRow({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_formatIcon, color: _formatColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format.format.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: onLengthEditActivated,
                  child: Text(
                    format.lengthDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: format.hasLength
                          ? EColors.textMuted
                          : EColors.accentGlow,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class const _AddFormatSheet({required final Set<BookFormat> existingTypes})
    extends StatefulWidget {
  @override
  State<_AddFormatSheet> createState() => _AddFormatSheetState();
}

class _AddFormatSheetState() extends State<_AddFormatSheet> {
  BookFormat? _selectedFormat;
  LengthInputController? _lengthController;

  void _prepareLengthInputForFormat(BookFormat format) {
    _lengthController?.dispose();
    _lengthController = LengthInputController.fromAudiobook(
      isAudiobook: format == BookFormat.audiobook,
    );
    setState(() => _selectedFormat = format);
  }

  void _submitAddedFormat() {
    if (_selectedFormat == null) return;
    final length = _lengthController!.value;
    if (length != null && length > 0) {
      Navigator.pop(context, (_selectedFormat!, length));
    }
  }

  @override
  void dispose() {
    _lengthController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Format'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BookFormat.values.mapL((format) {
              final isDisabled = widget.existingTypes.contains(format);
              final isSelected = _selectedFormat == format;
              return IgnorePointer(
                ignoring: isDisabled,
                child: Opacity(
                  opacity: isDisabled ? 0.45 : 1,
                  child: EFilterChip(
                    label: format.name,
                    color: format.color,
                    selected: isSelected,
                    onActivated: () => _prepareLengthInputForFormat(format),
                  ),
                ),
              );
            }),
          ),
          if (_lengthController != null) ...[
            const SizedBox(height: 16),
            LengthInput(
              controller: _lengthController!,
              onChanged: () => setState(() {}),
            ),
          ],
        ],
      ),
      actions:
          _lengthController?.dialogActions(context, _submitAddedFormat) ?? [],
    );
  }
}

class const _ReassignEventsSheet({
  required final LibraryBookFormat format,
  required final List<LibraryBookFormat> otherFormats,
}) extends StatefulWidget {
  @override
  State<_ReassignEventsSheet> createState() => _ReassignEventsSheetState();
}

class _ReassignEventsSheetState() extends State<_ReassignEventsSheet> {
  LibraryBookFormat? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.otherFormats.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reassign Progress Events'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This format has progress events. Move them to:',
            style: EText.body.small,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final format in widget.otherFormats)
                EFilterChip(
                  label: format.format.name,
                  color: format.format.color,
                  selected: _selectedTarget?.supaId == format.supaId,
                  onActivated: () => setState(() => _selectedTarget = format),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedTarget == null
              ? null
              : () => Navigator.pop(context, _selectedTarget),
          child: Text('Move & Delete', style: EText.section.danger),
        ),
      ],
    );
  }
}
