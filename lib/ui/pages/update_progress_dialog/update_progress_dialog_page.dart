import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/length_input.dart';
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
    // Ensure _selectedFormat is never null - use first format as fallback
    if (_selectedFormat == null && widget.book.formats.isNotEmpty) {
      _selectedFormat = widget.book.formats.first;
      _selectedProgressEventFormat = _selectedFormat!.isAudiobook
          ? ProgressEventFormat.minutes
          : ProgressEventFormat.pageNum;
    }
    _previousFormat = _selectedFormat;
  }

  bool get _hasMultipleFormats => widget.book.formats.length > 1;

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least one format
    if (widget.book.formats.isEmpty) {
      return CupertinoAlertDialog(
        title: Text('Error'),
        content: Text('This book has no formats. Please add a format first.'),
        actions: [
          CupertinoButton(
            onPressed: () => context.pop(false),
            child: Text('OK'),
          ),
        ],
      );
    }

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
    // Ensure we have a selected format
    final currentFormatId =
        _selectedFormat?.supaId ?? widget.book.formats.first.supaId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text('Format:', style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: currentFormatId,
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
              if (newFormat == null) {
                log.error('Format not found for ID: $formatId');
                return;
              }

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
      _fieldControllers
          .forFormat(ProgressEventFormat.minutes)
          .setMinutes(suggestedPosition);
    } else {
      _fieldControllers
          .forFormat(ProgressEventFormat.pageNum)
          .setPages(suggestedPosition);
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
    final ctrl = _fieldControllers.forFormat(_selectedProgressEventFormat);

    Widget inputField(TextEditingController controller, FocusNode focusNode) {
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
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          controller: controller,
          onChanged: (_) => setState(() {}),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: switch (_selectedProgressEventFormat) {
            ProgressEventFormat.minutes => [
                inputField(ctrl.hoursController, ctrl.hoursFocus),
                Text(':'),
                inputField(ctrl.minutesController, ctrl.minutesFocus),
                Text(' hh:mm'),
              ],
            ProgressEventFormat.pageNum => [
                Text('Page number:'),
                SizedBox(width: 6),
                inputField(ctrl.pagesController, ctrl.pagesFocus),
              ],
            ProgressEventFormat.percent => [
                inputField(ctrl.percentController, ctrl.percentFocus),
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
    final firstEmptyField =
        _fieldControllers.firstEmptyFormField(_selectedProgressEventFormat);
    final cancelButton = CupertinoButton(
      onPressed: () => context.pop(false),
      child: Text('Cancel'),
    );
    final nextFormField = CupertinoButton(
      onPressed: () => firstEmptyField?.requestFocus(),
      child: Text('Fill'),
    );
    final submitButton = CupertinoButton(
      onPressed: _submit,
      child: Text('Submit'),
    );
    return [
      cancelButton,
      if (firstEmptyField == null) submitButton else nextFormField,
    ];
  }

  /// Pop [true] iff UI needs to reload to see updated data.
  Future<void> _submit() async {
    // Ensure format is set - fallback to first format if somehow null
    if (_selectedFormat == null) {
      if (widget.book.formats.isEmpty) {
        log.error('Book has no formats');
        context.pop(false);
        return;
      }
      _selectedFormat = widget.book.formats.first;
      _selectedProgressEventFormat = _selectedFormat!.isAudiobook
          ? ProgressEventFormat.minutes
          : ProgressEventFormat.pageNum;
      log('Format was null, using first format: ${_selectedFormat!.format.name}');
    }

    final int? newLen = _fieldControllers.value(_selectedProgressEventFormat);
    if (newLen == null) {
      log.error('invalid length input');
      context.pop(false);
      return;
    }

    log('Submitting progress: formatId=${_selectedFormat!.supaId}, value=$newLen, format=${_selectedProgressEventFormat.name}');
    if (widget.eventToUpdate != null) {
      log('updating progress to $newLen');
      await SupabaseProgressService.updateProgressEvent(
        preexistingEvent: widget.eventToUpdate!,
        updatedValue: newLen,
        format: _selectedProgressEventFormat,
        formatId: _selectedFormat!.supaId,
        start: widget.startTime,
        end: _selectedUpdateTimestamp,
      );
    } else {
      await SupabaseProgressService.addProgressEvent(
        libraryBookId: widget.book.supaId,
        formatId: _selectedFormat!.supaId,
        newValue: newLen,
        format: _selectedProgressEventFormat,
        start: widget.startTime,
        end: _selectedUpdateTimestamp,
      );
    }
    if (mounted) context.pop(true);
  }
}

/// Manages LengthInputController instances for each ProgressEventFormat mode.
/// Uses shared LengthInputController for consistent behavior across the app.
class _FieldControllers {
  _FieldControllers(ProgressEvent? eventToUpdate) {
    if (eventToUpdate == null) return;
    final progress = eventToUpdate.progress;
    switch (eventToUpdate.format) {
      case ProgressEventFormat.minutes:
        _minutes.setMinutes(progress);
      case ProgressEventFormat.pageNum:
        _pages.setPages(progress);
      case ProgressEventFormat.percent:
        _percent.setPercent(progress);
    }
  }

  final _minutes = LengthInputController(mode: LengthInputMode.audiobook);
  final _pages = LengthInputController(mode: LengthInputMode.pages);
  final _percent = LengthInputController(mode: LengthInputMode.percent);

  LengthInputController forFormat(ProgressEventFormat format) =>
      switch (format) {
        ProgressEventFormat.minutes => _minutes,
        ProgressEventFormat.pageNum => _pages,
        ProgressEventFormat.percent => _percent,
      };

  FocusNode? firstEmptyFormField(ProgressEventFormat format) =>
      forFormat(format).firstEmptyField;

  int? value(ProgressEventFormat format) => forFormat(format).value;

  void dispose() {
    _minutes.dispose();
    _pages.dispose();
    _percent.dispose();
  }
}
