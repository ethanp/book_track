import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class const TextAndButton({
  required final String title,
  required final String buttonText,
  required final void Function() onActivated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 20),
      child: Text.rich(
        TextSpan(
          text: title,
          style: EText.body.medium.secondary,
          children: [
            TextSpan(
              text: buttonText,
              style: EText.body.medium.semibold.accent,
              recognizer: TapGestureRecognizer()..onTap = onActivated,
            ),
          ],
        ),
      ),
    );
  }
}
