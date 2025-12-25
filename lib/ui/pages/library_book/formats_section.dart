import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_format_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormatsSection extends ConsumerWidget {
  const FormatsSection(this.libraryBook, {super.key});

  final LibraryBook libraryBook;

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
              Text('Formats', style: TextStyles.h1),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showAddFormatSheet(context, ref),
                child: const Icon(CupertinoIcons.add_circled),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (formats.isEmpty)
            const Text(
              'No formats added',
              style: TextStyle(color: CupertinoColors.systemGrey),
            )
          else
            ...formats.mapL((format) => _FormatRow(
                  format: format,
                  libraryBook: libraryBook,
                  onEdit: () => _showEditFormatSheet(context, ref, format),
                  onDelete: formats.length > 1
                      ? () => _confirmDeleteFormat(context, ref, format)
                      : null,
                )),
        ],
      ),
    );
  }

  Future<void> _showAddFormatSheet(BuildContext context, WidgetRef ref) async {
    final existingTypes = libraryBook.formats.map((f) => f.format).toSet();

    final result = await showCupertinoModalPopup<(BookFormat, int)?>(
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

  Future<void> _showEditFormatSheet(
    BuildContext context,
    WidgetRef ref,
    LibraryBookFormat format,
  ) async {
    final result = await showCupertinoModalPopup<int?>(
      context: context,
      builder: (context) => _EditLengthSheet(format: format),
    );

    if (result != null) {
      await SupabaseFormatService.updateLength(format.supaId, result);
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
      final otherFormats =
          libraryBook.formats.where((f) => f.supaId != format.supaId).toList();
      if (otherFormats.isEmpty) return; // Can't delete last format

      final targetFormat = await showCupertinoModalPopup<LibraryBookFormat?>(
        context: context,
        builder: (context) => _ReassignEventsSheet(
          format: format,
          otherFormats: otherFormats,
        ),
      );

      if (targetFormat != null) {
        await SupabaseFormatService.reassignEvents(
            format.supaId, targetFormat.supaId);
        await SupabaseFormatService.deleteFormat(format.supaId);
        ref.invalidate(userLibraryProvider);
      }
    } else {
      // No events, just confirm deletion
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Format'),
          content: Text('Remove ${format.format.name} from this book?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
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

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.format,
    required this.libraryBook,
    required this.onEdit,
    this.onDelete,
  });

  final LibraryBookFormat format;
  final LibraryBook libraryBook;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  Color get _formatColor => switch (format.format) {
        BookFormat.audiobook => CupertinoColors.systemOrange,
        BookFormat.eBook => CupertinoColors.systemBlue,
        BookFormat.paperback => CupertinoColors.systemGreen,
        BookFormat.hardcover => CupertinoColors.systemIndigo,
      };

  IconData get _formatIcon => switch (format.format) {
        BookFormat.audiobook => CupertinoIcons.headphones,
        BookFormat.eBook => CupertinoIcons.device_phone_portrait,
        BookFormat.paperback => CupertinoIcons.book,
        BookFormat.hardcover => CupertinoIcons.book_fill,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
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
                  onTap: onEdit,
                  child: Text(
                    format.lengthDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: format.hasLength
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.activeBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              child: const Icon(
                CupertinoIcons.trash,
                size: 18,
                color: CupertinoColors.destructiveRed,
              ),
            ),
        ],
      ),
    );
  }
}

class _AddFormatSheet extends StatefulWidget {
  const _AddFormatSheet({required this.existingTypes});

  final Set<BookFormat> existingTypes;

  @override
  State<_AddFormatSheet> createState() => _AddFormatSheetState();
}

class _AddFormatSheetState extends State<_AddFormatSheet> {
  BookFormat? _selectedFormat;
  LengthInputController? _lengthController;

  void _onFormatSelected(BookFormat format) {
    _lengthController?.dispose();
    _lengthController = LengthInputController.fromAudiobook(
      isAudiobook: format == BookFormat.audiobook,
    );
    setState(() => _selectedFormat = format);
  }

  @override
  void dispose() {
    _lengthController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var onSubmit = () {
      if (_selectedFormat == null) return;
      final length = _lengthController!.value;
      if (length != null && length > 0) {
        Navigator.pop(context, (_selectedFormat!, length));
      }
    };
    return CupertinoAlertDialog(
      title: const Text('Add Format'),
      content: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: BookFormat.values.mapL((format) {
              final isDisabled = widget.existingTypes.contains(format);
              final isSelected = _selectedFormat == format;
              return CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : (isDisabled
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.systemGrey5),
                onPressed: isDisabled ? null : () => _onFormatSelected(format),
                child: Text(
                  format.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDisabled
                        ? CupertinoColors.systemGrey2
                        : (isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.label),
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
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_lengthController != null)
          CupertinoDialogAction(
            onPressed: () => _lengthController!.fillOrSubmit(onSubmit),
            child: Text(_lengthController!.saveLabel),
          ),
      ],
    );
  }
}

class _EditLengthSheet extends StatefulWidget {
  const _EditLengthSheet({required this.format});

  final LibraryBookFormat format;

  @override
  State<_EditLengthSheet> createState() => _EditLengthSheetState();
}

class _EditLengthSheetState extends State<_EditLengthSheet> {
  late final LengthInputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LengthInputController.fromAudiobook(
      isAudiobook: widget.format.isAudiobook,
      initialValue: widget.format.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var onSubmit = () {
      final length = _controller.value;
      if (length != null && length > 0) {
        Navigator.pop(context, length);
      }
    };
    return CupertinoAlertDialog(
      title: Text('Edit ${widget.format.format.name} Length'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LengthInput(controller: _controller),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () => _controller.fillOrSubmit(onSubmit),
          child: Text(_controller.saveLabel),
        ),
      ],
    );
  }
}

class _ReassignEventsSheet extends StatefulWidget {
  const _ReassignEventsSheet({
    required this.format,
    required this.otherFormats,
  });

  final LibraryBookFormat format;
  final List<LibraryBookFormat> otherFormats;

  @override
  State<_ReassignEventsSheet> createState() => _ReassignEventsSheetState();
}

class _ReassignEventsSheetState extends State<_ReassignEventsSheet> {
  LibraryBookFormat? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.otherFormats.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Reassign Progress Events'),
      message: Column(
        children: [
          Text(
            'This format has progress events. Move them to:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedTarget?.supaId,
            children: {
              for (final format in widget.otherFormats)
                format.supaId: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Text(format.format.name, style: TextStyle(fontSize: 13)),
                ),
            },
            onValueChanged: (id) {
              if (id == null) return;
              setState(() {
                _selectedTarget =
                    widget.otherFormats.firstWhere((f) => f.supaId == id);
              });
            },
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            if (_selectedTarget != null) {
              Navigator.pop(context, _selectedTarget);
            }
          },
          child: const Text('Move & Delete'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
