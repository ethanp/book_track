import 'package:book_track/ui/common/length_input.dart';
import 'package:flutter/material.dart';

class const SearchResultLengthDialog({
  required final bool isAudiobook,
  final int? initialValue,
}) extends StatefulWidget {
  @override
  State<SearchResultLengthDialog> createState() =>
      _SearchResultLengthDialogState();
}

class _SearchResultLengthDialogState() extends State<SearchResultLengthDialog> {
  late final LengthInputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LengthInputController.fromAudiobook(
      isAudiobook: widget.isAudiobook,
      initialValue: widget.isAudiobook ? null : widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitEnteredLength() {
    final length = _controller.value;
    if (length != null && length > 0) Navigator.pop(context, length);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isAudiobook ? 'Audiobook Length' : 'Book Length'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isAudiobook
                  ? 'How long is the audiobook?'
                  : 'How many pages?',
            ),
            const SizedBox(height: 8),
            LengthInput(
              controller: _controller,
              autofocus: true,
              showLabel: !widget.isAudiobook,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
      actions: _controller.dialogActions(context, _submitEnteredLength),
    );
  }
}
