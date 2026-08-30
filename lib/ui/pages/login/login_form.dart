import 'package:book_track/ui/common/design.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_form_controllers.dart';

class const LoginForm(
  final LoginFormControllers loginFormC,
  final Future<void> Function() onCredentialsSubmitted,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          _emailField(),
          const SizedBox(height: AppSpacing.md),
          _passwordField(),
        ],
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: loginFormC.emailC,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'ethanp@utexas.edu',
      ),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) =>
          !EmailValidator.validate(value ?? '') ? 'Requires valid email' : null,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: loginFormC.passwordC,
      decoration: const InputDecoration(
        labelText: 'Password',
        hintText: 'atg1',
      ),
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) {
        TextInput.finishAutofillContext();
        onCredentialsSubmitted();
      },
      textInputAction: TextInputAction.done,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (input) =>
          (input?.length ?? 0) < 6 ? 'Requires at least 6 characters' : null,
    );
  }
}
