import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'grey_box_text_field.dart';
import 'update_format_selector.dart';

class UpdateProgressDialogPage extends ConsumerStatefulWidget {
  const UpdateProgressDialogPage({
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

class _UpdateProgressDialogState
    extends ConsumerState<UpdateProgressDialogPage> {
  String _textFieldInput = '';

  ProgressEventFormat _selectedProgressEventFormat =
      ProgressEventFormat.percent;

  @override
  void initState() {
    super.initState();
    widget.book.progressHistory.progressEvents.lastOrNull?.format.ifExists(
        (lastSelectedFormat) =>
            _selectedProgressEventFormat = lastSelectedFormat);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New progress on "${widget.book.book.title}"'),
          finishedBookButton(),
          GreyBoxTextField(textChanged: (newText) {
            print('newText: $newText');
            _textFieldInput = newText;
          }),
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
            int? userInput = int.tryParse(_textFieldInput);
            if (userInput == null) {
              context.showSnackBar(
                'invalid number: $_textFieldInput',
              );
              context.pop();
              return;
            }
            final future = SupabaseProgressService.updateProgress(
              book: widget.book,
              userInput: userInput,
              format: _selectedProgressEventFormat,
              start: widget.startTime,
              end: widget.endTime,
            );
            if (context.mounted) {
              context.showSnackBar('updating to: $userInput');
              context.pop();
            }
            future.then((void _) {
              if (context.mounted) {
                print('update completed');
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.invalidate(userLibraryProvider);
              }
            });
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  Widget finishedBookButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        // TODO implement
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[300],
          foregroundColor: Colors.purple[900],
          elevation: 3,
        ),
        child: Text('I finished the book'),
      ),
    );
  }
}
