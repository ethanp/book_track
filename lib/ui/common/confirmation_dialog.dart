import 'package:book_track/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmationDialog extends ConsumerWidget {
  const ConfirmationDialog({
    required this.text,
    required this.title,
    required this.actionName,
    required this.onConfirm,
  });

  final String text;
  final String title;
  final String actionName;
  final Future<void> Function() onConfirm;

  static void show({
    required BuildContext context,
    required String text,
    required String title,
    required String actionName,
    required Future<void> Function() onConfirm,
  }) =>
      showCupertinoDialog(
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
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [cancelButton(context), confirmButton(ref)],
    );
  }

  CupertinoDialogAction confirmButton(WidgetRef ref) {
    return CupertinoDialogAction(
      onPressed: () {
        Navigator.pop(ref.context);
        onConfirm();
      },
      isDestructiveAction: true,
      child: Text(
        actionName.capitalize,
        style: TextStyle(color: CupertinoColors.destructiveRed),
      ),
    );
  }

  CupertinoDialogAction cancelButton(BuildContext context) {
    return CupertinoDialogAction(
      onPressed: () => Navigator.pop(context),
      isDefaultAction: true,
      child: Text('Cancel'),
    );
  }
}
