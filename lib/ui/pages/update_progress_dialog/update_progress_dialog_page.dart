import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
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
  UpdateProgressDialogPage({
    required this.book,
    this.startTime,
    this.initialEndTime,
    this.eventToUpdate,
  });

  final LibraryBook book;
  final DateTime? startTime;
  final DateTime? initialEndTime;
  final ProgressEvent? eventToUpdate;

  LibraryBookFormat? get _initialFormat {
    if (eventToUpdate != null) {
      return book.formatById(eventToUpdate!.formatId);
    }
    return book.lastUsedFormat ?? book.primaryFormat;
  }

  ProgressEventFormat get initialProgressFormat =>
      eventToUpdate?.format ??
      (_initialFormat?.isAudiobook == true
          ? ProgressEventFormat.minutes
          : ProgressEventFormat.pageNum);

  DateTime get initialTimestamp =>
      eventToUpdate?.end ?? initialEndTime ?? DateTime.now();

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
  late LibraryBookFormat? _selectedFormat = widget._initialFormat;
  late ProgressEventFormat _selectedProgressEventFormat =
      widget.initialProgressFormat;
  late DateTime _selectedUpdateTimestamp = widget.initialTimestamp;

  late final _FieldControllers _fieldControllers =
      _FieldControllers(widget.eventToUpdate);

  // Track the last format to detect switches
  LibraryBookFormat? _previousFormat;

  @override
  void initState() {
    super.initState();
    _previousFormat = _selectedFormat;
  }

  bool get _hasMultipleFormats => widget.book.formats.length > 1;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasMultipleFormats) ...[
            _formatPicker(),
            if (_showContinueFromHint) _continueFromHint(),
          ],
          progressAmountForm(),
          updateFormatSelector(),
          SizedBox(height: 15),
          endTimePicker(),
        ],
      ),
      actions: submitAndCancelButtons(),
    );
  }

  bool get _showContinueFromHint =>
      _selectedFormat != null &&
      _previousFormat != null &&
      _selectedFormat!.supaId != _previousFormat!.supaId &&
      widget.book.lastProgressPercent != null;

  Widget _formatPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text('Format:', style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedFormat?.supaId,
            children: {
              for (final format in widget.book.formats)
                format.supaId: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    format.format.name,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            },
            onValueChanged: (formatId) {
              if (formatId == null) return;
              final newFormat = widget.book.formatById(formatId);
              if (newFormat == null) return;

              setState(() {
                _previousFormat = _selectedFormat;
                _selectedFormat = newFormat;

                // Update progress format based on new format
                _selectedProgressEventFormat = newFormat.isAudiobook
                    ? ProgressEventFormat.minutes
                    : ProgressEventFormat.pageNum;

                // Prefill with suggested position
                _prefillSuggestedPosition(newFormat);
              });
            },
          ),
        ],
      ),
    );
  }

  void _prefillSuggestedPosition(LibraryBookFormat targetFormat) {
    final suggestedPosition = widget.book.suggestPositionIn(targetFormat);
    if (suggestedPosition == null) return;

    if (targetFormat.isAudiobook) {
      _fieldControllers.ctrl[ProgressEventFormat.minutes]
          ?.updateWith(suggestedPosition);
    } else {
      _fieldControllers.ctrl[ProgressEventFormat.pageNum]
          ?.updateText(suggestedPosition.toString());
    }
  }

  Widget _continueFromHint() {
    final percent = widget.book.lastProgressPercent;
    if (percent == null || _selectedFormat == null) return const SizedBox();

    final suggestedPosition = widget.book.suggestPositionIn(_selectedFormat!);
    if (suggestedPosition == null) return const SizedBox();

    final positionStr = _selectedFormat!.isAudiobook
        ? suggestedPosition.minsToHhMm
        : suggestedPosition.toString();
    final unit = _selectedFormat!.isAudiobook ? '' : ' pages';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'You were at ${percent.toStringAsFixed(0)}% (~$positionStr$unit)',
        style: TextStyle(
          fontSize: 11,
          color: CupertinoColors.systemGrey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget progressAmountForm() {
    Widget inputField(_FocusableController c) {
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
          enableSuggestions: false,
          autofocus: true,
          focusNode: c.focusNode,
          keyboardType: TextInputType.number,
          controller: c.controller,
          onChanged: (c) => setState(() {}),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: switch (_selectedProgressEventFormat) {
            ProgressEventFormat.minutes => [
                inputField(_fieldControllers.hrs),
                Text(':'),
                inputField(_fieldControllers.mins),
                Text(' hh:mm'),
              ],
            ProgressEventFormat.pageNum => [
                Text('Page number:'),
                SizedBox(width: 6),
                inputField(_fieldControllers.page),
              ],
            ProgressEventFormat.percent => [
                inputField(_fieldControllers.percent),
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
        // Flutter doesn't allow direct styling of CupertinoDatePicker text,
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

  List<Widget> submitAndCancelButtons() {
    final firstEmptyFormField =
        _fieldControllers.firstEmptyFormField(_selectedProgressEventFormat);
    final cancelButton = CupertinoButton(
      onPressed: () => context.pop(false),
      child: Text('Cancel'),
    );
    final nextFormField = CupertinoButton(
      onPressed: () => firstEmptyFormField?.focusNode.requestFocus(),
      child: Text('Fill'),
    );
    final submitButton = CupertinoButton(
      onPressed: _submit,
      child: Text('Submit'),
    );
    return [
      cancelButton,
      if (firstEmptyFormField == null) submitButton else nextFormField,
    ];
  }

  /// Pop [true] iff UI needs to reload to see updated data.
  Future<void> _submit() async {
    if (_selectedFormat == null) {
      log.error('No format selected');
      context.pop(false);
      return;
    }

    final String lengthText =
        _fieldControllers.values(_selectedProgressEventFormat).join(':');
    final int? newLen = _parseLength(lengthText);
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
        formatId: _selectedFormat!.supaId,
        newValue: newLen,
        format: _selectedProgressEventFormat,
        start: widget.startTime,
        end: _selectedUpdateTimestamp,
      );
    }
    if (mounted) context.pop(true);
  }

  int? _parseLength(String text) {
    if (_selectedFormat?.isAudiobook == true) {
      final List<String> split = text.split(':');
      if (split.length < 2) return int.tryParse(text);
      final int? hrs = int.tryParse(split[0]);
      final int? mins = int.tryParse(split[1]);
      if (hrs == null || mins == null) return null;
      return hrs * 60 + mins;
    }
    return int.tryParse(text);
  }
}

// TODO(clean up): Move these into the _FieldControllers class?
extension on List<_FocusableController>? {
  void updateWith(int progress) {
    this?.first.controller.text = progress.hours.toString();
    this?.last.controller.text = progress.minutes.toString();
  }

  void updateText(String string) {
    this?.first.controller.text = string;
  }
}

class _FocusableController {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
}

class _FieldControllers {
  final ProgressEvent? tEventToUpdate;

  late Map<ProgressEventFormat, List<_FocusableController>> ctrl = () {
    final controllersPerFormat = {
      ProgressEventFormat.minutes: [
        _FocusableController(),
        _FocusableController()
      ],
      ProgressEventFormat.pageNum: [_FocusableController()],
      ProgressEventFormat.percent: [_FocusableController()],
    };
    if (tEventToUpdate == null) return controllersPerFormat;

    // Update an existing event
    final ProgressEvent eventToUpdate = tEventToUpdate!;
    final progress = eventToUpdate.progress;
    final format = eventToUpdate.format;
    if (format == ProgressEventFormat.minutes) {
      controllersPerFormat[format]?.updateWith(progress);
    } else {
      controllersPerFormat[format]?.updateText(progress.toString());
    }
    return controllersPerFormat;
  }();

  _FieldControllers(this.tEventToUpdate);

  _FocusableController get hrs => ctrl[ProgressEventFormat.minutes]!.first;

  _FocusableController get mins => ctrl[ProgressEventFormat.minutes]!.last;

  _FocusableController get page => ctrl[ProgressEventFormat.pageNum]!.first;

  _FocusableController get percent => ctrl[ProgressEventFormat.percent]!.first;

  _FocusableController? firstEmptyFormField(ProgressEventFormat format) =>
      ctrl[format]!.where((e) => e.controller.text.isEmpty).firstOrNull;

  List<String> values(ProgressEventFormat selectedProgressEventFormat) =>
      ctrl[selectedProgressEventFormat]!.mapL((e) => e.controller.text);
}
