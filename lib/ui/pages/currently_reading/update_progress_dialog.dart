import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_format_selector.dart';

class UpdateProgressDialog extends ConsumerStatefulWidget {
  const UpdateProgressDialog({
    required this.book,
    this.startTime,
    this.endTime,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? endTime;

  @override
  ConsumerState createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends ConsumerState<UpdateProgressDialog> {
  late final TextEditingController textEditingController;
  // TODO Ideally it would initialize this by considering whatever the user
  //  selected the last time.
  ProgressEventFormat _selectedProgressEventFormat =
      ProgressEventFormat.percent;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New progress on "${widget.book.book.title}"'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: TextFormField(controller: textEditingController),
          ),
          UpdateFormatSelector(
            currentlySelectedFormat: _selectedProgressEventFormat,
            onSelected: (selected) =>
                setState(() => _selectedProgressEventFormat = selected),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: Text('Cancel')),
        TextButton(
          onPressed: () async {
            int? userInput = int.tryParse(textEditingController.text);
            if (userInput == null) {
              context.showSnackBar(
                'invalid number: ${textEditingController.text}',
              );
              context.pop();
              return;
            }
            await SupabaseProgressService.updateProgress(
              book: widget.book,
              userInput: userInput,
              format: _selectedProgressEventFormat,
              start: widget.startTime,
              end: widget.endTime,
            );
            if (context.mounted) {
              context.showSnackBar('updated to: $userInput');
              context.pop();
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
