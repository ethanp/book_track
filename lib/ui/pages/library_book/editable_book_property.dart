import 'package:book_track/helpers.dart';
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
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    _textFieldController.text = widget.defaultValue ?? widget.value;
    super.initState();
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          titleAndValue(),
          updateButton(),
        ],
      ),
    );
  }

  Widget titleAndValue() {
    return Row(children: [
      Text('${widget.title}: ', style: TextStyles().title),
      SizedBox(width: 10),
      if (_editing) textField() else Text(widget.value, style: TextStyles().h5),
    ]);
  }

  Widget textField() {
    return SizedBox(
      width: 200,
      child: CupertinoTextField(
        enableSuggestions: false,
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

  Widget updateButton() {
    return ElevatedButton(
      style: buttonStyle(),
      onPressed: () => _editing
          ? onSubmit(_textFieldController.text)
          : setState(() => _editing = true),
      child: Text(_editing ? 'Submit' : 'Update'),
    );
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      shape: FlutterHelpers.roundedRect(radius: 10),
      fixedSize: Size(70, 40),
      padding: EdgeInsets.zero,
      backgroundColor:
          _editing ? Colors.lightGreen.shade300 : CupertinoColors.systemGrey6,
    );
  }
}
