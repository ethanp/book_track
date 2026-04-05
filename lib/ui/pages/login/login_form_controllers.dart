import 'package:flutter/cupertino.dart';

class LoginFormControllers {
  final TextEditingController emailC =
      TextEditingController(text: 'ethanp@utexas.edu');
  final TextEditingController passwordC = TextEditingController();

  String get emailInput => emailC.text.trim();

  String get passwordInput => passwordC.text.trim();

  void dispose() {
    emailC.dispose();
    passwordC.dispose();
  }
}
