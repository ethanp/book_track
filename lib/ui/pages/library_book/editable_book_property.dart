import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableBookProperty extends ConsumerStatefulWidget {
  const EditableBookProperty({
    required this.title,
    required this.value,
    required this.onPressed,
    this.defaultValue,
  });

  final String title;
  final String value;
  final String? defaultValue;
  final void Function(String) onPressed;

  @override
  ConsumerState createState() => _EditableBookPropertyState();
}

class _EditableBookPropertyState extends ConsumerState<EditableBookProperty> {
  bool _editing = false;

  late final TextEditingController _textFieldController =
      TextEditingController(text: widget.defaultValue ?? widget.value);

  @override
  void dispose() {
    _textFieldController.dispose();
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
    return SizedBox(
      width: 70,
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
        controller: _textFieldController,
        onSubmitted: onSubmit,
      ),
    );
  }

  void onSubmit(String text) {
    setState(() => _editing = false);
    if (text.isEmpty || text == widget.value) return;
    widget.onPressed(text);
  }

  Widget trailingButtonsRight() {
    return Row(children: [
      updateButton(),
      if (_editing) cancelEditingButton(),
    ]);
  }

  Widget updateButton() {
    return ElevatedButton(
      style: Buttons.updateButtonStyle(
          color: _editing
              ? Colors.lightGreen.shade300
              : CupertinoColors.systemGrey6),
      onPressed: () => _editing
          ? onSubmit(_textFieldController.text)
          : setState(() => _editing = true),
      child: Text(_editing ? 'Submit' : 'Update'),
    );
  }

  Widget cancelEditingButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ElevatedButton(
        style: Buttons.updateButtonStyle(color: Colors.red[300]!),
        onPressed: () => setState(() => _editing = false),
        child: Text('Cancel'),
      ),
    );
  }
}
