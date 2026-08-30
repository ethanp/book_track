import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const ConfirmationDialog({
  required final String text,
  required final String title,
  required final String actionName,
  required final Future<void> Function() onConfirm,
}) extends ConsumerWidget {
  static void show({
    required BuildContext context,
    required String text,
    required String title,
    required String actionName,
    required Future<void> Function() onConfirm,
  }) => showDialog<void>(
    context: context,
    builder: (_) => ConfirmationDialog(
      text: text,
      title: title,
      actionName: actionName,
      onConfirm: onConfirm,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [_cancelButton(context), _confirmButton(ref)],
    );
  }

  Widget _confirmButton(WidgetRef ref) {
    return TextButton(
      onPressed: () {
        Navigator.pop(ref.context);
        onConfirm();
      },
      child: Text(
        actionName.capitalize,
        style: EText.section.copyWith(color: EColors.danger),
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    );
  }
}
