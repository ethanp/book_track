import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextFieldValueAndSuffix {
  const TextFieldValueAndSuffix(this.value, this.suffix);

  final String value;
  final String? suffix;
}

class EditableBookProperty extends ConsumerStatefulWidget {
  const EditableBookProperty({
    required this.title,
    required this.value,
    required this.onPressed,
    required this.initialTextFieldValues,
  });

  final String title;
  final String value;
  final void Function(List<String>) onPressed;
  final List<TextFieldValueAndSuffix> initialTextFieldValues;

  @override
  ConsumerState createState() => _EditableBookPropertyState();
}

class _EditableBookPropertyState extends ConsumerState<EditableBookProperty> {
  bool _editing = false;

  late final Map<TextEditingController, String?> textFields = {
    for (final v in widget.initialTextFieldValues)
      TextEditingController(text: v.value): v.suffix
  };

  @override
  void dispose() {
    textFields.keys.forEach((field) => field.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          titleAndValueLeft(),
          trailingButtonsRight(),
        ],
      ),
    );
  }

  Widget titleAndValueLeft() {
    return Row(children: [
      Text('${widget.title}: ', style: TextStyles().title),
      SizedBox(width: 10),
      if (_editing)
        textField()
      else
        Text(widget.value, style: TextStyles().value),
    ]);
  }

  Widget textField() {
    return Row(
      children: textFields.entries.mapL<Widget>(
        (field) => Row(
          children: [
            SizedBox(
              width: 70 - textFields.length * 20,
              height: 28,
              child: CupertinoTextField(
                decoration: BoxDecoration(
                  color: Colors.grey[100]!.withValues(alpha: .8),
                  border: Border.all(color: Colors.grey[400]!, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.only(top: 5, left: 4),
                style: TextStyle(fontSize: 14, color: Colors.grey[900]),
                autocorrect: false,
                controller: field.key,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            if (field.value != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 6),
                child: Text(
                  field.value!,
                  style: TextStyles().value,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void onSubmit() {
    setEditing(false);
    if (textFields.keys.any((e) => e.text.isEmpty)) return;
    widget.onPressed(textFields.keys.mapL((e) => e.text));
  }

  Widget trailingButtonsRight() {
    return Row(children: [
      updateButton(),
      if (_editing) cancelEditingButton(),
    ]);
  }

  void setEditing(bool v) => setState(() => _editing = v);

  Widget updateButton() {
    return ElevatedButton(
      style: Buttons.updateButtonStyle(
          color: _editing
              ? Colors.lightGreen.shade300
              : CupertinoColors.systemGrey6),
      onPressed: () => _editing ? onSubmit() : setEditing(true),
      child: Text(_editing ? 'Submit' : 'Update'),
    );
  }

  Widget cancelEditingButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ElevatedButton(
        style: Buttons.updateButtonStyle(color: Colors.red[300]!),
        onPressed: () => setEditing(false),
        child: Text('Cancel'),
      ),
    );
  }
}
