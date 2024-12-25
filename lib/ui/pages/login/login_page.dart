import 'dart:async';

import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/main.dart';
import 'package:book_track/services/supabase_auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form.dart';
import 'login_form_controllers.dart';
import 'text_and_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static SimpleLogger log = SimpleLogger(prefix: 'LoginPage');
  final formKey = GlobalKey<FormState>();

  final LoginFormControllers loginFormC = LoginFormControllers();
  late final StreamSubscription<AuthState> _authStateSubscription;

  bool _isSignUpMode = false;
  bool _processingSignIn = false;
  bool _redirectingToLoggedInApp = false;
  String? _authError;

  @override
  void initState() {
    pushLoggedInAppUponLogin();
    super.initState();
  }

  String signUpText({bool reverse = false}) {
    bool which = _isSignUpMode;
    if (reverse) which = !which;
    return which ? 'Sign Up' : 'Sign In';
  }

  void pushLoggedInAppUponLogin() {
    _authStateSubscription = SupabaseAuthService.onAuthStateChange(
      onEvent: (AuthState data) {
        log('Auth state changed: $data');
        if (_redirectingToLoggedInApp) return;
        if (SupabaseAuthService.isLoggedIn) {
          _redirectingToLoggedInApp = true;
          // TODO(bug) probably need to call this when we log OUT as well
          if (mounted) context.pushReplacementPage(const WholeAppWidget());
        }
      },
      onError: (Object error) =>
          log('Unexpected error occurred: $error', error: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.grey[400],
      navigationBar: CupertinoNavigationBar(middle: Text(signUpText())),
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
              const SizedBox(height: 10),
              signInButton(),
              showAuthErrorIfPresent(),
              signInUpToggle(),
              resetPassword(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget showAuthErrorIfPresent() {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 10),
      child: Text(
        _authError ?? '',
        style: TextStyle(
          color: Colors.red[800],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget signInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[100],
          shape: FlutterHelpers.roundedRect(radius: 8),
        ),
        onPressed: _processingSignIn ? null : _doSignIn,
        child: Text(_processingSignIn ? 'Processing...' : signUpText()),
      ),
    );
  }

  Widget signInUpToggle() {
    return TextAndButton(
      title: '${_isSignUpMode ? "Already" : "Don't"} have an account? ',
      buttonText: signUpText(reverse: true),
      onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
    );
  }

  Widget resetPassword(BuildContext context) {
    return TextAndButton(
      title: 'Forgot your password? ',
      buttonText: 'Email reset link',
      onTap: () => sendPasswordResetLink(context),
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
    } on AuthException catch (error) {
      _authError = error.message;
    } catch (error) {
      log('Unexpected error occurred: $error', error: true);
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
