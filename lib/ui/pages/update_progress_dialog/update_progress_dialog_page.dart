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
    this.preexistingProgressEvent,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? initialEndTime;
  final ProgressEvent? preexistingProgressEvent;

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
    if (res == true) ref.invalidate(userLibraryProvider);
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
        preexistingProgressEvent: progressEvent,
      ),
    );
    if (res == true) ref.invalidate(userLibraryProvider);
  }
}

class _UpdateProgressDialogState
    extends ConsumerState<UpdateProgressDialogPage> {
  late String _textFieldInput =
      widget.preexistingProgressEvent?.map(widget.book.bookProgressString) ??
          '';

  late ProgressEventFormat _selectedProgressEventFormat =
      widget.preexistingProgressEvent?.format ??
          widget.book.progressHistory.lastOrNull?.format ??
          widget.book.defaultProgressFormat;

  late DateTime _selectedEndTime = widget.preexistingProgressEvent?.end ??
      widget.initialEndTime ??
      DateTime.now();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO(ux,feature) Audiobook length should have TWO text-fields ([hrs]:[mins])
          //  Just like how it is for the audiobook length update form.
          GreyBoxTextField(
            textChanged: (input) => _textFieldInput = input,
            initialValue: _textFieldInput,
          ),
          updateFormatSelector(),
          SizedBox(height: 15),
          endTimePicker(),
        ],
      ),
      actions: submitAndCancelButtons(),
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

  // TODO(ux) This looks bad and is cumbersome. Consider using eg.
  //  https://github.com/Team-Picky/flutter_datetime_picker_plus instead.
  //  Or I'm sure there are countless alternatives.
  Widget endTimePicker() {
    final dateTimeNow = DateTime.now();
    return Column(children: [
      Text('Set progress update\'s timestamp:'),
      Transform.scale(
        // Flutter doesn’t allow direct styling of CupertinoDatePicker text,
        // but you can just scale the whole widget.
        scale: 1,
        child: SizedBox(
          height: 110,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            minimumDate: dateTimeNow.copyWith(year: dateTimeNow.year - 20),
            maximumDate: dateTimeNow.add(const Duration(days: 12)),
            initialDateTime:
                widget.preexistingProgressEvent?.dateTime ?? dateTimeNow,
            onDateTimeChanged: (t) => setState(() => _selectedEndTime = t),
          ),
        ),
      ),
    ]);
  }

  List<Widget> submitAndCancelButtons() => [
        CupertinoButton(
          onPressed: () => context.pop(false),
          child: Text('Cancel'),
        ),
        CupertinoButton(
          onPressed: _submit,
          child: Text('Submit'),
        ),
      ];

  /// Pop [true] iff UI needs to reload to see updated data.
  Future<void> _submit() async {
    final int? newLen = widget.book.parseLengthText(_textFieldInput);
    if (newLen == null) {
      // TODO(feature) this should be a form validation instead.
      log.error('invalid length: $_textFieldInput');
      context.pop(false);
      return;
    }
    if (widget.preexistingProgressEvent != null) {
      await SupabaseProgressService.updateProgressEvent(
        preexistingEvent: widget.preexistingProgressEvent!,
        updatedValue: newLen,
        start: widget.startTime,
        end: _selectedEndTime,
      );
    } else {
      await SupabaseProgressService.addProgressEvent(
        bookId: widget.book.supaId,
        newValue: newLen,
        format: _selectedProgressEventFormat,
        start: widget.startTime,
        end: _selectedEndTime,
      );
    }
    if (mounted) context.pop(true);
  }
}
