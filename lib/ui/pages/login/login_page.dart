import 'dart:async';

import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:book_track/services/supabase_auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sign_up_toggle.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _signUpMode = false;
  String get _signUpText => _signUpMode ? 'Sign Up' : 'Sign In';
  String get _reverseSignUpText => !_signUpMode ? 'Sign Up' : 'Sign In';
  bool _processingSignIn = false;
  bool _redirectingToLoggedInApp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          children: [
            CupertinoTextField(
              controller: _emailController,
              placeholder: 'email',
              decoration: BoxDecoration(
                border:
                    Border.all(color: CupertinoColors.systemGrey, width: 1.0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            CupertinoTextField(
              controller: _passwordController,
              placeholder: 'Password',
              obscureText: true,
              onSubmitted: (_) => _buttonPressed(),
              textInputAction:
                  TextInputAction.done, // Shows "done" button on keyboard
              decoration: BoxDecoration(
                border:
                    Border.all(color: CupertinoColors.systemGrey, width: 1.0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _processingSignIn ? null : _buttonPressed,
              child: Text(_processingSignIn ? 'Processing...' : _signUpText),
            ),
            SignInUpToggle(
              signUpMode: _signUpMode,
              reverseSignUpText: _reverseSignUpText,
              onTap: () => setState(() => _signUpMode = !_signUpMode),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _buttonPressed() async {
    try {
      setState(() => _processingSignIn = true);
      final emailInput = _emailController.text.trim();
      final passwordInput = _passwordController.text.trim();
      final f =
          _signUpMode ? SupabaseAuthService.signUp : SupabaseAuthService.signIn;
      await f(emailInput, passwordInput);
      if (mounted) context.showSnackBar('Success');
    } catch (error) {
      if (mounted) context.authError(error);
    } finally {
      if (mounted) setState(() => _processingSignIn = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }
}
