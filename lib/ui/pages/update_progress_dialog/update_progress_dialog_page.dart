import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_format_selector.dart';

final SimpleLogger log = SimpleLogger(prefix: 'UpdateProgressDialogPage');

class UpdateProgressDialogPage extends ConsumerStatefulWidget {
  const UpdateProgressDialogPage({
    required this.book,
    this.startTime,
    this.initialEndTime,
    this.eventToUpdate,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? initialEndTime;
  final ProgressEvent? eventToUpdate;

  @override
  ConsumerState createState() => _UpdateProgressDialogState();

  static Future<bool> show(
    WidgetRef ref,
    LibraryBook book, {
    DateTime? startTime,
    DateTime? initialEndTime,
  }) async {
    final bool? updateConfirmed = await showCupertinoDialog(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: book,
        startTime: startTime,
        initialEndTime: initialEndTime,
      ),
    );
    if (updateConfirmed == true) ref.invalidate(userLibraryProvider);
    return false; // <- This means *don't* remove the book from the ListView.
  }

  static Future<void> update(
    WidgetRef ref,
    LibraryBook libraryBook,
    ProgressEvent progressEvent,
  ) async {
    final bool? updateConfirmed = await showCupertinoDialog(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: libraryBook,
        eventToUpdate: progressEvent,
      ),
    );
    if (updateConfirmed == true) ref.invalidate(userLibraryProvider);
  }
}

class _UpdateProgressDialogState
    extends ConsumerState<UpdateProgressDialogPage> {
  late ProgressEventFormat _selectedProgressEventFormat =
      widget.eventToUpdate?.format ??
          widget.book.progressHistory.lastOrNull?.format ??
          widget.book.defaultProgressFormat;

  late DateTime _selectedUpdateTimestamp =
      widget.eventToUpdate?.end ?? widget.initialEndTime ?? DateTime.now();

  late final Map<ProgressEventFormat, List<TextEditingController>>
      _textControllers = () {
    final baseline = {
      ProgressEventFormat.minutes: [
        TextEditingController(),
        TextEditingController()
      ],
      ProgressEventFormat.pageNum: [TextEditingController()],
      ProgressEventFormat.percent: [TextEditingController()],
    };
    if (widget.eventToUpdate == null) return baseline;
    final ProgressEvent eventToUpdate = widget.eventToUpdate!;
    final progress = eventToUpdate.progress;
    final format = eventToUpdate.format;
    if (format == ProgressEventFormat.minutes) {
      baseline[format] = [
        TextEditingController(text: progress.hours.toString()),
        TextEditingController(text: progress.minutes.toString()),
      ];
    } else {
      baseline[format] = [TextEditingController(text: progress.toString())];
    }
    return baseline;
  }();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          progressAmountForm(),
          updateFormatSelector(),
          SizedBox(height: 15),
          endTimePicker(),
        ],
      ),
      actions: submitAndCancelButtons(),
    );
  }

  Widget progressAmountForm() {
    final controllers = _textControllers[_selectedProgressEventFormat]!;
    Widget inputField(TextEditingController c) {
      return SizedBox(
        width: _selectedProgressEventFormat == ProgressEventFormat.pageNum
            ? 36
            : 28,
        height: 26,
        child: CupertinoTextField(
          decoration: BoxDecoration(
            color: Colors.grey[100]!.withValues(alpha: .8),
            border: Border.all(color: Colors.grey[400]!, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.only(top: 5, left: 4),
          style: TextStyle(fontSize: 14, color: Colors.grey[900]),
          autocorrect: false,
          controller: c,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: switch (_selectedProgressEventFormat) {
            ProgressEventFormat.minutes => [
                inputField(controllers.first),
                Text(':'),
                inputField(controllers.last),
                Text(' hh:mm'),
              ],
            ProgressEventFormat.pageNum => [
                Text('Page number:'),
                SizedBox(width: 6),
                inputField(controllers.first),
              ],
            ProgressEventFormat.percent => [
                inputField(controllers.first),
                Text(' %'),
              ],
          }),
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
            initialDateTime: widget.eventToUpdate?.dateTime ?? dateTimeNow,
            onDateTimeChanged: (t) =>
                setState(() => _selectedUpdateTimestamp = t),
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
    final List<TextEditingController> userInputValues =
        _textControllers[_selectedProgressEventFormat]!;
    final String lengthText = userInputValues.map((e) => e.text).join(':');
    final int? newLen = widget.book.parseLengthText(lengthText);
    if (newLen == null) {
      // TODO(feature) this should be a form validation instead.
      log.error('invalid length: $lengthText');
      context.pop(false);
      return;
    }
    if (widget.eventToUpdate != null) {
      log('updating progress to $lengthText ($newLen)');
      await SupabaseProgressService.updateProgressEvent(
        preexistingEvent: widget.eventToUpdate!,
        updatedValue: newLen,
        format: _selectedProgressEventFormat,
        start: widget.startTime,
        end: _selectedUpdateTimestamp,
      );
    } else {
      await SupabaseProgressService.addProgressEvent(
        bookId: widget.book.supaId,
        newValue: newLen,
        format: _selectedProgressEventFormat,
        start: widget.startTime,
        end: _selectedUpdateTimestamp,
      );
    }
    if (mounted) context.pop(true);
  }
}
