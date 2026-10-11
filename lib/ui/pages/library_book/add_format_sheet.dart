import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const AddFormatSheet({required final Set<BookFormat> existingTypes})
    extends StatefulWidget {
  @override
  State<AddFormatSheet> createState() => _AddFormatSheetState();
}

class _AddFormatSheetState() extends State<AddFormatSheet> {
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
                    label: format.label,
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
