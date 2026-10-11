import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const ReassignEventsSheet({
  required final LibraryBookFormat format,
  required final List<LibraryBookFormat> otherFormats,
}) extends StatefulWidget {
  @override
  State<ReassignEventsSheet> createState() => _ReassignEventsSheetState();
}

class _ReassignEventsSheetState() extends State<ReassignEventsSheet> {
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
                  label: format.format.label,
                  color: format.format.color,
                  selected: _selectedTarget?.id == format.id,
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
