import 'package:book_track/ui/common/design.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
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
        backgroundColor: AppColors.background,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        children: [
          _emailField(),
          _passwordField(),
        ],
      ),
    );
  }

  Widget _emailField() {
    return CupertinoTextFormFieldRow(
      controller: loginFormC.emailC,
      prefix: _fieldPrefixText('Email'),
      placeholder: 'ethanp@utexas.edu',
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) =>
          !EmailValidator.validate(value!) ? 'Requires valid email' : null,
    );
  }

  Widget _passwordField() => _submittableField(
        controller: loginFormC.passwordC,
        name: 'Password',
        placeholder: 'atg1',
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        validator: (input) =>
            (input?.length ?? 0) < 6 ? 'Requires at least 6 characters' : null,
      );

  Widget _submittableField({
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
      prefix: _fieldPrefixText(name),
      autofillHints: autofillHints,
      onFieldSubmitted: (_) {
        TextInput.finishAutofillContext();
        onSubmit();
      },
      textInputAction: TextInputAction.done,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
    );
  }

  Widget _fieldPrefixText(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}
