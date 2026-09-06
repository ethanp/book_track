import 'package:book_track/ui/common/design.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const TextFieldValueAndSuffix(final String value, final String? suffix);

class const EditableBookProperty({
  required final String title,
  required final String value,
  required final List<TextFieldValueAndSuffix> initialTextFieldValues,
  required final void Function(List<String>) onValuesCommitted,
}) extends StatefulWidget {
  @override
  State<EditableBookProperty> createState() => _EditableBookPropertyState();
}

class _EditableBookPropertyState() extends State<EditableBookProperty> {
  bool _editing = false;

  late final Map<TextEditingController, String?> textFields = {
    for (final field in widget.initialTextFieldValues)
      TextEditingController(text: field.value): field.suffix,
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
        children: [
          Expanded(child: titleAndValueLeft()),
          trailingButtonsRight(),
        ],
      ),
    );
  }

  Widget titleAndValueLeft() {
    return Row(
      children: [
        Text('${widget.title}: ', style: AppTextStyles.label),
        const SizedBox(width: 10),
        if (_editing) textField() else Text(widget.value, style: AppTextStyles.value),
      ],
    );
  }

  Widget textField() {
    return Row(
      children: textFields.entries.mapL<Widget>(
        (field) => Row(
          children: [
            SizedBox(
              width: textFields.length == 2 ? 44 : 150,
              height: 26,
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceInset,
                  contentPadding: const EdgeInsets.only(top: 5, left: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                style: AppTextStyles.value,
                autocorrect: false,
                controller: field.key,
                onSubmitted: (_) => _commitEditedValues(),
              ),
            ),
            if (field.value != null)
              Padding(
                padding: const EdgeInsets.only(left: 3, right: 4),
                child: Text(field.value!, style: AppTextStyles.value),
              ),
          ],
        ),
      ),
    );
  }

  void _commitEditedValues() {
    setEditing(false);
    if (textFields.keys.any((field) => field.text.isEmpty)) return;
    widget.onValuesCommitted(textFields.keys.mapL((field) => field.text));
  }

  Widget trailingButtonsRight() {
    return _editing
        ? Row(
            children: [
              submitButton(),
              const SizedBox(width: 8),
              cancelEditingButton(),
            ],
          )
        : updateButton();
  }

  Widget submitButton() {
    return _iconAction(
      backgroundColor: AppColors.success,
      onPressed: _commitEditedValues,
      icon: Icons.check,
    );
  }

  void setEditing(bool editing) => setState(() => _editing = editing);

  Widget updateButton() {
    return TextButton(
      onPressed: () => setEditing(true),
      child: Text('Update', style: AppTextStyles.valueButton),
    );
  }

  Widget cancelEditingButton() {
    return _iconAction(
      backgroundColor: AppColors.destructive,
      onPressed: () => setEditing(false),
      icon: Icons.close,
    );
  }

  Widget _iconAction({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
  }) => IconButton.filled(
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(36, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: Icon(icon, size: 18),
  );
}
