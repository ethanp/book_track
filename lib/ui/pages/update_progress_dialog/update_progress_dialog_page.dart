import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_progress_service.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:book_track/ui/common/progress_event_date_caption.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_format_selector.dart';

const _log = ELogger('UpdateProgressDialogPage');

class const UpdateProgressDialogPage({
  required final LibraryBook book,
  final ProgressEvent? eventToUpdate,
}) extends ConsumerStatefulWidget {
  LibraryBookFormat? get _initialFormat {
    if (eventToUpdate != null) {
      return book.formatById(eventToUpdate!.formatId);
    }
    return book.lastUsedFormat ?? book.primaryFormat;
  }

  ProgressEventFormat get initialProgressFormat =>
      eventToUpdate?.format ?? _lastUsedProgressFormat;

  ProgressEventFormat get _lastUsedProgressFormat {
    final lastEvent = book.progressHistory.lastOrNull;
    if (lastEvent != null) return lastEvent.format;
    return _initialFormat?.isAudiobook == true
        ? ProgressEventFormat.minutes
        : ProgressEventFormat.pageNum;
  }

  DateTime get initialTimestamp => eventToUpdate?.end ?? DateTime.now();

  @override
  ConsumerState createState() => _UpdateProgressDialogState();

  static Future<bool> show(WidgetRef ref, LibraryBook book) async {
    final bool? updateConfirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(book: book),
    );
    if (updateConfirmed == true) ref.invalidate(userLibraryProvider);
    return false; // <- This means *don't* remove the book from the ListView.
  }

  static Future<void> update(
    WidgetRef ref,
    LibraryBook libraryBook,
    ProgressEvent progressEvent,
  ) async {
    final bool? updateConfirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => UpdateProgressDialogPage(
        book: libraryBook,
        eventToUpdate: progressEvent,
      ),
    );
    if (updateConfirmed == true) ref.invalidate(userLibraryProvider);
  }
}

class _UpdateProgressDialogState()
    extends ConsumerState<UpdateProgressDialogPage> {
  late LibraryBookFormat? _selectedFormat = widget._initialFormat;
  late ProgressEventFormat _selectedProgressEventFormat =
      widget.initialProgressFormat;
  late DateTime _selectedUpdateTimestamp = widget.initialTimestamp;

  late final _FieldControllers _fieldControllers = _FieldControllers(
    widget.eventToUpdate,
  );

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
      return AlertDialog(
        title: const Text('Error'),
        content: const Text(
          'This book has no formats. Please add a format first.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Log progress'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasMultipleFormats) ...[
              _formatPicker(),
              if (_showContinueFromHint) _continueFromHint(),
            ],
            progressAmountForm(),
            updateFormatSelector(),
            const SizedBox(height: 15),
            endTimePicker(),
          ],
        ),
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
          Text('Format:', style: EText.label.small),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            showSelectedIcon: false,
            selected: {currentFormatId},
            segments: [
              for (final format in widget.book.formats)
                ButtonSegment(
                  value: format.supaId,
                  label: Text(format.format.name),
                ),
            ],
            onSelectionChanged: (selection) {
              final newFormat = widget.book.formatById(selection.first);
              if (newFormat == null) {
                _log.error('Format not found for ID: ${selection.first}');
                return;
              }

              setState(() {
                _previousFormat = _selectedFormat;
                _selectedFormat = newFormat;
                _selectedProgressEventFormat = newFormat.isAudiobook
                    ? ProgressEventFormat.minutes
                    : ProgressEventFormat.pageNum;
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
        style: EText.caption.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget progressAmountForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LengthInput(
        controller: _fieldControllers.forFormat(_selectedProgressEventFormat),
        autofocus: true,
        onChanged: () => setState(() {}),
      ),
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
        const Text('Set log timestamp:'),
        TextButton(
          onPressed: _pickUpdateTimestamp,
          child: Text(_selectedUpdateTimestamp.slashMonthDayYearAtTime),
        ),
      ],
    );
  }

  Future<void> _pickUpdateTimestamp() async {
    final dateTimeNow = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedUpdateTimestamp,
      firstDate: dateTimeNow.copyWith(year: dateTimeNow.year - 20),
      lastDate: dateTimeNow.shiftedByDays(12),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedUpdateTimestamp),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _selectedUpdateTimestamp = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  List<Widget> submitAndCancelButtons() => _fieldControllers.dialogActions(
    context,
    _selectedProgressEventFormat,
    _submit,
  );

  /// Pop [true] iff UI needs to reload to see updated data.
  Future<void> _submit() async {
    // Ensure format is set - fallback to first format if somehow null
    if (_selectedFormat == null) {
      if (widget.book.formats.isEmpty) {
        _log.error('Book has no formats');
        context.pop(false);
        return;
      }
      _selectedFormat = widget.book.formats.first;
      _selectedProgressEventFormat = _selectedFormat!.isAudiobook
          ? ProgressEventFormat.minutes
          : ProgressEventFormat.pageNum;
      _log.log(
        'Format was null, using first format: ${_selectedFormat!.format.name}',
      );
    }

    final int? newLen = _fieldControllers.value(_selectedProgressEventFormat);
    if (newLen == null) {
      _log.error('invalid length input');
      context.pop(false);
      return;
    }

    _log.log(
      'Submitting progress: formatId=${_selectedFormat!.supaId}, value=$newLen, format=${_selectedProgressEventFormat.name}',
    );
    if (widget.eventToUpdate != null) {
      _log.log('updating progress to $newLen');
      await SupabaseProgressService.updateProgressEvent(
        preexistingEvent: widget.eventToUpdate!,
        updatedValue: newLen,
        format: _selectedProgressEventFormat,
        formatId: _selectedFormat!.supaId,
        end: _selectedUpdateTimestamp,
      );
    } else {
      await SupabaseProgressService.addProgressEvent(
        libraryBookId: widget.book.supaId,
        formatId: _selectedFormat!.supaId,
        newValue: newLen,
        format: _selectedProgressEventFormat,
        end: _selectedUpdateTimestamp,
      );
    }
    if (mounted) context.pop(true);
  }
}

/// Manages LengthInputController instances for each ProgressEventFormat mode.
/// Uses shared LengthInputController for consistent behavior across the app.
class _FieldControllers(ProgressEvent? eventToUpdate) {
  this {
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

  List<Widget> dialogActions(
    BuildContext context,
    ProgressEventFormat format,
    VoidCallback onLengthSubmitted,
  ) => forFormat(format).dialogActions(context, onLengthSubmitted);

  void dispose() {
    _minutes.dispose();
    _pages.dispose();
    _percent.dispose();
  }
}
