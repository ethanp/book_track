import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'grey_box_text_field.dart';
import 'update_format_selector.dart';

final SimpleLogger log = SimpleLogger(prefix: 'UpdateProgressDialogPage');

class UpdateProgressDialogPage extends ConsumerStatefulWidget {
  const UpdateProgressDialogPage({
    required this.book,
    this.startTime,
    this.initialEndTime,
    this.progressEvent,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? initialEndTime;
  final ProgressEvent? progressEvent;

  @override
  ConsumerState createState() => _UpdateProgressDialogState();

  static Future<bool> show(
    WidgetRef ref,
    LibraryBook book, {
    DateTime? startTime,
    DateTime? initialEndTime,
  }) async {
    final bool? res = await showCupertinoDialog(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: book,
        startTime: startTime,
        initialEndTime: initialEndTime,
      ),
    );
    if (res ?? false) ref.invalidate(userLibraryProvider);
    return false; // <- This means *don't* remove the book from the ListView.
  }

  static Future<void> update(
    WidgetRef ref,
    LibraryBook libraryBook,
    ProgressEvent progressEvent,
  ) async {
    final bool? res = await showCupertinoDialog(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: libraryBook,
        progressEvent: progressEvent,
      ),
    );
    if (res ?? false) ref.invalidate(userLibraryProvider);
  }
}

class _UpdateProgressDialogState
    extends ConsumerState<UpdateProgressDialogPage> {
  String _textFieldInput = '';

  late ProgressEventFormat _selectedProgressEventFormat =
      widget.book.defaultProgressFormat;
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
    return Column(children: [
      Text('Set progress update\'s timestamp:'),
      Transform.scale(
        // Flutter doesn’t allow direct styling of CupertinoDatePicker text,
        // but you can just scale the whole widget.
        scale: .78,
        child: SizedBox(
          height: 110,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            minimumDate: widget.startTime,
            maximumDate: widget.startTime?.add(const Duration(hours: 12)),
            initialDateTime: DateTime.now(),
            onDateTimeChanged: (DateTime newEndTime) =>
                setState(() => _selectedEndTime = newEndTime),
          ),
        ),
      ),
    ]);
  }

  List<Widget> submitAndCancel() {
    return [
      CupertinoButton(
        onPressed: () => context.pop(false),
        child: Text('Cancel'),
      ),
      CupertinoButton(
        onPressed: _submit,
        child: Text('Submit'),
      ),
    ];
  }

  Future<void> _submit() async {
    final int? newLen = widget.book.parseLengthText(_textFieldInput);
    if (newLen == null) {
      // TODO(ui) this should be a form validation instead.
      log('invalid length: $_textFieldInput');
      context.pop(false);
      return;
    }
    if (widget.progressEvent != null) {
      // TODO(feature) Show the existing progress modal, but in edit mode:
      //  1. Prefill inputs with status quo values
      //  2. Provide the option to delete the event
      log('TODO implement this feature');
      context.pop(false);
    }
    log('updating to: $newLen');
    await SupabaseProgressService.updateProgress(
      bookId: widget.book.supaId,
      newValue: newLen,
      format: _selectedProgressEventFormat,
      start: widget.startTime,
      end: _selectedEndTime,
    );
    if (mounted) context.pop(true);
  }
}
