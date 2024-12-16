import 'package:flutter/cupertino.dart';

class LoginFormControllers {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();
  final TextEditingController tokenC = TextEditingController();

  String get emailInput => emailC.text.trim();

  String get passwordInput => passwordC.text.trim();

  String get tokenInput => tokenC.text.trim();

  void dispose() {
    emailC.dispose();
    passwordC.dispose();
    tokenC.dispose();
  }
}
