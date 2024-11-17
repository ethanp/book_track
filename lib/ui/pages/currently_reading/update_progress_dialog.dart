import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
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
            onPressed: () {
              context.showSnackBar('captured: ${textEditingController.text}');
              context.pop();
            },
            child: Text('Submit'))
      ],
    );
  }
}
