import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_form_controllers.dart';

class LoginForm extends StatelessWidget {
  const LoginForm(this.loginFormC, this.onSubmit);

  final LoginFormControllers loginFormC;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: CupertinoFormSection.insetGrouped(
        backgroundColor: Colors.grey[400]!,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: .5,
            ),
          ),
          color: Colors.white.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(10),
        ),
        children: [
          emailField(),
          passwordField(),
          tokenField(),
        ],
      ),
    );
  }

  Widget emailField() {
    return CupertinoTextFormFieldRow(
      controller: loginFormC.emailC,
      prefix: fieldPrefixText('Email'),
      placeholder: 'ethanp@utexas.edu',
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) =>
          !EmailValidator.validate(value!) ? 'Requires valid email' : null,
      // decoration: textFieldDecoration(),
    );
  }

  Widget passwordField() => submittableField(
        controller: loginFormC.passwordC,
        name: 'Password',
        placeholder: 'atg1',
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        validator: (input) =>
            (input?.length ?? 0) < 6 ? 'Requires at least 6 characters' : null,
      );

  Widget tokenField() => submittableField(
        controller: loginFormC.tokenC,
        name: 'Token (deprecated)',
        placeholder: 'leave it blank',
        validator: (input) =>
            input == null || input.isEmpty || input.length == 6
                ? null
                : 'Must have 6 numbers',
      );

  Widget submittableField({
    required TextEditingController controller,
    required String name,
    required String? Function(String?) validator,
    bool obscureText = false,
    List<String>? autofillHints,
    String? placeholder,
  }) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      placeholder: placeholder ?? name,
      obscureText: obscureText,
      prefix: fieldPrefixText(name),
      autofillHints: autofillHints,
      onFieldSubmitted: (_) {
        TextInput.finishAutofillContext();
        onSubmit();
      },
      // Show "done" button on keyboard
      textInputAction: TextInputAction.done,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      // decoration: textFieldDecoration(),
    );
  }

  Widget fieldPrefixText(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}
