import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignInUpToggle extends StatelessWidget {
  const SignInUpToggle({
    required this.signUpMode,
    required this.reverseSignUpText,
    required this.onTap,
  });

  final bool signUpMode;
  final String reverseSignUpText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: RichText(
        text: TextSpan(
          text: '${signUpMode ? "Already" : "Don't"} have an account? ',
          style: TextStyle(
            color: Colors.black, // Regular text color
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: reverseSignUpText,
              style: TextStyle(
                color: Colors.blue,
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
