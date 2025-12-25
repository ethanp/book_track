import 'package:book_track/extensions.dart';
import 'package:flutter/cupertino.dart';

/// Input mode for length/progress entry.
enum LengthInputMode { audiobook, pages, percent }

/// Controller for length/duration input that handles audiobook (hours:minutes),
/// page-based, and percent input. Manages text controllers, focus nodes, and parsing.
class LengthInputController {
  LengthInputController({
    required this.mode,
    int? initialValue,
  }) {
    if (initialValue != null && initialValue > 0) {
      setMinutes(initialValue);
    }
  }

  /// Convenience constructor for simple audiobook/pages forms.
  LengthInputController.fromAudiobook({
    required bool isAudiobook,
    int? initialValue,
  }) : this(
          mode: isAudiobook ? LengthInputMode.audiobook : LengthInputMode.pages,
          initialValue: initialValue,
        );

  final LengthInputMode mode;

  bool get isAudiobook => mode == LengthInputMode.audiobook;
  bool get isPages => mode == LengthInputMode.pages;
  bool get isPercent => mode == LengthInputMode.percent;

  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _pagesController = TextEditingController();
  final _percentController = TextEditingController();

  final _hoursFocus = FocusNode();
  final _minutesFocus = FocusNode();
  final _pagesFocus = FocusNode();
  final _percentFocus = FocusNode();

  TextEditingController get hoursController => _hoursController;
  TextEditingController get minutesController => _minutesController;
  TextEditingController get pagesController => _pagesController;
  TextEditingController get percentController => _percentController;

  FocusNode get hoursFocus => _hoursFocus;
  FocusNode get minutesFocus => _minutesFocus;
  FocusNode get pagesFocus => _pagesFocus;
  FocusNode get percentFocus => _percentFocus;

  /// Sets the audiobook value (total minutes) by splitting into hours:minutes.
  void setMinutes(int totalMinutes) {
    _hoursController.text = totalMinutes.hours.toString();
    _minutesController.text = totalMinutes.minutes.toString();
  }

  /// Sets the pages or percent value.
  void setPages(int pages) => _pagesController.text = pages.toString();
  void setPercent(int percent) => _percentController.text = percent.toString();

  /// Parses input to total value based on mode.
  /// Returns null if input is invalid or empty.
  int? get value {
    switch (mode) {
      case LengthInputMode.audiobook:
        final hours = int.tryParse(_hoursController.text) ?? 0;
        final minutes = int.tryParse(_minutesController.text) ?? 0;
        final total = hours * 60 + minutes;
        return total > 0 ? total : null;
      case LengthInputMode.pages:
        return int.tryParse(_pagesController.text);
      case LengthInputMode.percent:
        return int.tryParse(_percentController.text);
    }
  }

  /// Returns the first empty field's focus node for Fill button behavior.
  /// Returns null if all fields are filled.
  FocusNode? get firstEmptyField {
    switch (mode) {
      case LengthInputMode.audiobook:
        if (_hoursController.text.isEmpty) return _hoursFocus;
        if (_minutesController.text.isEmpty) return _minutesFocus;
        return null;
      case LengthInputMode.pages:
        if (_pagesController.text.isEmpty) return _pagesFocus;
        return null;
      case LengthInputMode.percent:
        if (_percentController.text.isEmpty) return _percentFocus;
        return null;
    }
  }

  bool get hasEmptyField => firstEmptyField != null;

  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _pagesController.dispose();
    _percentController.dispose();
    _hoursFocus.dispose();
    _minutesFocus.dispose();
    _pagesFocus.dispose();
    _percentFocus.dispose();
  }
}

/// Widget that renders length/duration input based on controller's mode.
/// Shows hours:minutes for audiobooks, pages field, or percent field.
class LengthInput extends StatelessWidget {
  const LengthInput({
    required this.controller,
    this.autofocus = false,
    this.showLabel = true,
    this.fieldWidth,
    this.onChanged,
  });

  final LengthInputController controller;
  final bool autofocus;
  final bool showLabel;
  final double? fieldWidth;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (controller.mode) {
      LengthInputMode.audiobook => _audiobookInput(),
      LengthInputMode.pages => _pagesInput(),
      LengthInputMode.percent => _percentInput(),
    };
  }

  Widget _audiobookInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth ?? 50,
          child: CupertinoTextField(
            controller: controller.hoursController,
            focusNode: controller.hoursFocus,
            placeholder: 'hrs',
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(':'),
        ),
        SizedBox(
          width: fieldWidth ?? 50,
          child: CupertinoTextField(
            controller: controller.minutesController,
            focusNode: controller.minutesFocus,
            placeholder: 'min',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
      ],
    );
  }

  Widget _pagesInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth ?? 80,
          child: CupertinoTextField(
            controller: controller.pagesController,
            focusNode: controller.pagesFocus,
            placeholder: 'Pages',
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          const Text('pages'),
        ],
      ],
    );
  }

  Widget _percentInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth ?? 60,
          child: CupertinoTextField(
            controller: controller.percentController,
            focusNode: controller.percentFocus,
            placeholder: '%',
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          const Text('%'),
        ],
      ],
    );
  }
}
