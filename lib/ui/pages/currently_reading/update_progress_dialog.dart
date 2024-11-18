import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateProgressDialog extends ConsumerStatefulWidget {
  const UpdateProgressDialog(this.book);

  final BookProgress book;

  @override
  ConsumerState createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends ConsumerState<UpdateProgressDialog> {
  late final TextEditingController textEditingController;

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
          TextFormField(controller: textEditingController),
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
            // TODO this should be selected during the dialog.
            //  Ideally it would auto-select based on library book format as
            //   as considering what ever the user selected the last time.
            final userFormat = ProgressEventFormat.percent;
            await SupabaseProgressService.updateProgress(
                widget.book, userInput, userFormat);
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
