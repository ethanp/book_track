import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
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
    required this.initialTextFieldValues,
    required this.onPressed,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [titleAndValueLeft(), trailingButtonsRight()],
      ),
    );
  }

  Widget titleAndValueLeft() {
    return Row(children: [
      Text('${widget.title}: ', style: TextStyles.title),
      SizedBox(width: 10),
      if (_editing)
        textField()
      else
        Text(widget.value, style: TextStyles.value),
    ]);
  }

  Widget textField() {
    return Row(
      children: textFields.entries.mapL<Widget>(
        (field) => Row(
          children: [
            SizedBox(
              width: textFields.length == 2 ? 26 : 150,
              height: 26,
              child: CupertinoTextField(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  border:
                      Border.all(color: CupertinoColors.systemGrey, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.only(top: 5, left: 4),
                style: TextStyle(fontSize: 14, color: CupertinoColors.label),
                autocorrect: false,
                controller: field.key,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            if (field.value != null)
              Padding(
                padding: const EdgeInsets.only(left: 3, right: 4),
                child: Text(
                  field.value!,
                  style: TextStyles.value,
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
    return _editing
        ? Row(children: [
            submitButton(),
            SizedBox(width: 8),
            cancelEditingButton(),
          ])
        : updateButton();
  }

  Widget submitButton() {
    return buttonStyle(
      color: CupertinoColors.systemGreen,
      onPressed: onSubmit,
      child: Icon(
        CupertinoIcons.check_mark,
        color: CupertinoColors.white,
      ),
    );
  }

  void setEditing(bool v) => setState(() => _editing = v);

  Widget updateButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setEditing(true),
      child: Text('Update', style: TextStyles.valueButton),
    );
  }

  Widget cancelEditingButton() {
    return buttonStyle(
      color: CupertinoColors.systemRed,
      onPressed: () => setEditing(false),
      child: Icon(
        CupertinoIcons.clear,
        color: CupertinoColors.white,
      ),
    );
  }

  Widget buttonStyle({
    required void Function() onPressed,
    required Widget child,
    required Color color,
  }) =>
      CupertinoButton(
        onPressed: onPressed,
        color: color,
        padding: EdgeInsets.zero,
        child: child,
      );
}
