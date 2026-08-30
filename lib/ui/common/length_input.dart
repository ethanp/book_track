import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

/// Input mode for length/progress entry.
enum LengthInputMode() {
  audiobook,
  pages,
  percent,
}

/// Controller for length/duration input that handles audiobook (hours:minutes),
/// page-based, and percent input. Manages text controllers, focus nodes, and parsing.
class LengthInputController({
  required final LengthInputMode mode,
  int? initialValue,
}) {
  this {
    if (initialValue != null && initialValue > 0) {
      setMinutes(initialValue);
    }
  }

  /// Convenience constructor for simple audiobook/pages forms.
  new fromAudiobook({required bool isAudiobook, int? initialValue})
    : this(
        mode: isAudiobook ? LengthInputMode.audiobook : LengthInputMode.pages,
        initialValue: initialValue,
      );

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

  /// Handles Fill/Submit button logic: focuses empty field if any, else calls [onLengthSubmitted].
  void fillOrSubmit(VoidCallback onLengthSubmitted) {
    if (hasEmptyField) {
      firstEmptyField?.requestFocus();
    } else {
      onLengthSubmitted();
    }
  }

  /// Returns "Fill" if there's an empty field, otherwise "Save".
  String get saveLabel => hasEmptyField ? 'Fill' : 'Save';

  /// Standard Cancel/Save dialog actions for length input forms.
  List<Widget> dialogActions(
    BuildContext context,
    VoidCallback onLengthSubmitted,
  ) => [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    TextButton(
      onPressed: () => fillOrSubmit(onLengthSubmitted),
      child: Text(saveLabel),
    ),
  ];

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
class const LengthInput({
  required final LengthInputController controller,
  final bool autofocus = false,
  final bool showLabel = true,
  final double? fieldWidth,
  final VoidCallback? onChanged,
}) extends StatelessWidget {
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
          child: TextField(
            controller: controller.hoursController,
            focusNode: controller.hoursFocus,
            decoration: const InputDecoration(hintText: 'hrs'),
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
          child: TextField(
            controller: controller.minutesController,
            focusNode: controller.minutesFocus,
            decoration: const InputDecoration(hintText: 'min'),
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
          child: TextField(
            controller: controller.pagesController,
            focusNode: controller.pagesFocus,
            decoration: const InputDecoration(hintText: 'Pages'),
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        if (showLabel) ...[const SizedBox(width: 8), const Text('pages')],
      ],
    );
  }

  Widget _percentInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth ?? 60,
          child: TextField(
            controller: controller.percentController,
            focusNode: controller.percentFocus,
            decoration: const InputDecoration(hintText: '%'),
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        if (showLabel) ...[const SizedBox(width: 8), const Text('%')],
      ],
    );
  }
}
