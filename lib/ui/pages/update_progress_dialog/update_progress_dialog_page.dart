import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'grey_box_text_field.dart';
import 'update_format_selector.dart';

class UpdateProgressDialogPage extends ConsumerStatefulWidget {
  const UpdateProgressDialogPage({
    required this.book,
    this.startTime,
    this.initialEndTime,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? initialEndTime;

  @override
  ConsumerState createState() => _UpdateProgressDialogState();

  static Future<bool> show(
    WidgetRef ref,
    LibraryBook book, {
    DateTime? startTime,
    DateTime? initialEndTime,
  }) async {
    await showCupertinoDialog(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: book,
        startTime: startTime,
        initialEndTime: initialEndTime,
      ),
    );
    ref.invalidate(userLibraryProvider);
    return false; // <- This means *don't* remove the book from the ListView.
  }
}

class _UpdateProgressDialogState
    extends ConsumerState<UpdateProgressDialogPage> {
  String _textFieldInput = '';

  ProgressEventFormat _selectedProgressEventFormat =
      ProgressEventFormat.percent;
  DateTime _selectedEndTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.book.progressHistory.lastOrNull?.format.map((lastSelectedFormat) =>
        _selectedProgressEventFormat = lastSelectedFormat);
    widget.initialEndTime.map((endTime) => _selectedEndTime = endTime);
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.book.book.title;
    final String format = widget.book.bookFormat?.name ?? '';
    return CupertinoAlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Book: "$title" ($format)'),
          GreyBoxTextField(textChanged: (input) => _textFieldInput = input),
          updateFormatSelector(),
          SizedBox(height: 15),
          endTimePicker(),
        ],
      ),
      actions: submitAndCancel(),
    );
  }

  Widget updateFormatSelector() {
    return UpdateFormatSelector(
      currentlySelectedFormat: _selectedProgressEventFormat,
      onSelected: (selected) =>
          setState(() => _selectedProgressEventFormat = selected),
      book: widget.book,
    );
  }

  Widget endTimePicker() {
    return Column(
      children: [
        Text('Set progress update\'s timestamp:'),
        // Flutter doesn’t allow direct styling of CupertinoDatePicker text,
        // but you can just scale the whole widget.
        Transform.scale(
          scale: .78,
          child: SizedBox(
            height: 110,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              minimumDate: widget.startTime,
              maximumDate: widget.startTime?.add(const Duration(hours: 12)),
              initialDateTime: DateTime.now(),
              onDateTimeChanged: (DateTime newDateTime) =>
                  setState(() => _selectedEndTime = newDateTime),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> submitAndCancel() {
    return [
      CupertinoButton(
        // color: Colors.deepOrangeAccent[100]!.withOpacity(.22),
        onPressed: context.pop,
        child: Text('Cancel'),
      ),
      CupertinoButton(
        // color: Colors.green[100]!.withOpacity(.5),
        onPressed: _submit,
        child: Text('Submit'),
      ),
    ];
  }

  void _submit() {
    final int? userInput = int.tryParse(_textFieldInput);
    if (userInput == null) {
      // TODO(ui) this should be a form validation instead.
      context.showSnackBar('invalid number: $_textFieldInput');
      context.pop();
      return;
    }
    SupabaseProgressService.updateProgress(
      book: widget.book,
      userInput: userInput,
      format: _selectedProgressEventFormat,
      start: widget.startTime,
      end: _selectedEndTime,
    );
    context.showSnackBar('updating to: $userInput');
    context.pop();
  }
}
