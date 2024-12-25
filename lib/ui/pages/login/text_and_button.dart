import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TextAndButton extends StatelessWidget {
  const TextAndButton(
      {required this.title, required this.buttonText, required this.onTap});

  final String title;
  final String buttonText;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 20),
      child: RichText(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            color: Colors.black, // Regular text color
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: buttonText,
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}
