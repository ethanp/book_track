import 'dart:async';

import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:book_track/services/supabase_auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form.dart';
import 'login_form_controllers.dart';
import 'sign_up_toggle.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUpMode = false;
  final formKey = GlobalKey<FormState>();

  String get _signUpText => _isSignUpMode ? 'Sign Up' : 'Sign In';

  String get _reverseSignUpText => !_isSignUpMode ? 'Sign Up' : 'Sign In';
  bool _processingSignIn = false;
  bool _redirectingToLoggedInApp = false;
  final LoginFormControllers loginFormC = LoginFormControllers();
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    pushLoggedInAppUponLogin();
    super.initState();
  }

  void pushLoggedInAppUponLogin() {
    _authStateSubscription = SupabaseAuthService.onAuthStateChange(
      onEvent: (AuthState data) {
        if (_redirectingToLoggedInApp) return;
        if (SupabaseAuthService.isLoggedIn) {
          _redirectingToLoggedInApp = true;
          if (mounted) context.pushReplacementPage(const WholeAppWidget());
        }
      },
      onError: (Object error) {
        if (mounted) context.authError(error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(_signUpText)),
      child: SafeArea(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          // TODO(simplify) remove this? Not sure if it's used or not.
          onChanged: () => Form.maybeOf(primaryFocus!.context!)?.save(),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 12,
            ),
            children: [
              LoginForm(loginFormC, _doSignIn),
              const SizedBox(height: 18),
              signInButton(),
              signInUpToggle(),
              resetPassword(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget signInButton() {
    return ElevatedButton(
      onPressed: _processingSignIn ? null : _doSignIn,
      child: Text(_processingSignIn ? 'Processing...' : _signUpText),
    );
  }

  Widget signInUpToggle() {
    return SignInUpToggle(
      signUpMode: _isSignUpMode,
      reverseSignUpText: _reverseSignUpText,
      onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
    );
  }

  Widget resetPassword(BuildContext context) {
    return ElevatedButton(
      onPressed: () => sendPasswordResetLink(context),
      child: Text('Send reset password for email'),
    );
  }

  BoxDecoration textFieldDecoration() {
    return BoxDecoration(
      border: Border.all(color: CupertinoColors.systemGrey, width: 1.0),
      borderRadius: BorderRadius.circular(8),
    );
  }

  Future<void> sendPasswordResetLink(BuildContext context) async {
    try {
      await SupabaseAuthService.sentPasswordResetLink(loginFormC.emailInput);
      if (context.mounted) context.showSnackBar('Reset email sent');
    } catch (error) {
      if (context.mounted) {
        context.showSnackBar('error: $error', isError: true);
      }
    }
  }

  Future<void> _doSignIn() async {
    if (loginFormC.tokenInput.isNotEmpty) return await updatePassword();
    try {
      setState(() => _processingSignIn = true);
      final serviceFunc = _isSignUpMode
          ? SupabaseAuthService.signUp
          : SupabaseAuthService.signIn;
      await serviceFunc(loginFormC.emailInput, loginFormC.passwordInput);
      if (mounted) context.showSnackBar('Success');
    } catch (error) {
      if (mounted) context.authError(error);
    } finally {
      if (mounted) setState(() => _processingSignIn = false);
    }
  }

  Future<void> updatePassword() async {
    try {
      await SupabaseAuthService.resetPassword(
        emailInput: loginFormC.emailInput,
        passwordInput: loginFormC.passwordInput,
        tokenInput: loginFormC.tokenInput,
      );
      if (mounted) context.showSnackBar('Password updated');
    } catch (e) {
      if (mounted) context.showSnackBar("Couldn't update password: $e");
    }
    return;
  }

  @override
  void dispose() {
    loginFormC.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }
}
