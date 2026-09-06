import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_format_service.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const EditFormatLengthDialog({required final LibraryBookFormat format})
    extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required LibraryBookFormat format,
  }) async {
    final int? length = await showDialog<int>(
      context: context,
      builder: (context) => EditFormatLengthDialog(format: format),
    );
    if (length == null) return;
    await SupabaseFormatService.updateLength(format.supaId, length);
    ref.invalidate(userLibraryProvider);
  }

  @override
  State<EditFormatLengthDialog> createState() => _EditFormatLengthDialogState();
}

class _EditFormatLengthDialogState() extends State<EditFormatLengthDialog> {
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

  void _submitEditedLength() {
    final int? length = _controller.value;
    if (length != null && length > 0) {
      Navigator.pop(context, length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.format.format.name} length'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LengthInput(
          controller: _controller,
          onChanged: () => setState(() {}),
        ),
      ),
      actions: _controller.dialogActions(context, _submitEditedLength),
    );
  }
}
