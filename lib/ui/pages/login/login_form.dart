import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';

class LoginForm extends StatelessWidget {
  const LoginForm(
    this._emailController,
    this._passwordController,
    this._tokenController,
    this._buttonPressed,
  );

  final TextEditingController _emailController;
  final TextEditingController _passwordController;
  final TextEditingController _tokenController;
  final Future<void> Function() _buttonPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Fill this out'),
      children: [
        emailField(),
        passwordField(),
        tokenField(),
      ],
    );
  }

  Widget emailField() {
    return CupertinoTextFormFieldRow(
      controller: _emailController,
      prefix: fieldPrefixText('Email'),
      placeholder: 'email',
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) =>
          !EmailValidator.validate(value!) ? 'Incorrect email format' : null,
      // decoration: textFieldDecoration(),
    );
  }

  Widget passwordField() => submittableField(
        controller: _passwordController,
        name: 'Password',
        obscureText: true,
        validator: (input) =>
            (input?.length ?? 0) < 6 ? 'Must have at least 6 characters' : null,
      );

  Widget tokenField() => submittableField(
        controller: _tokenController,
        name: 'Token (optional)',
        validator: (input) =>
            input == null || input.isEmpty || input.length == 6
                ? null
                : 'Must have 6 numbers',
      );

  CupertinoTextFormFieldRow submittableField({
    required TextEditingController controller,
    required String name,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      placeholder: name,
      obscureText: obscureText,
      prefix: fieldPrefixText(name),
      onFieldSubmitted: (_) => _buttonPressed(),
      // Show "done" button on keyboard
      textInputAction: TextInputAction.done,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      // decoration: textFieldDecoration(),
    );
  }

  Widget fieldPrefixText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: CupertinoColors.systemFill,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
