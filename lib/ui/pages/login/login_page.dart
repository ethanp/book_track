import 'dart:async';

import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _processingSignIn = false;
  bool _redirectingToLoggedInApp = false;
  final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    pushLoggedInAppUponLogin();
    super.initState();
  }

  void pushLoggedInAppUponLogin() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (AuthState data) {
        if (_redirectingToLoggedInApp) return;
        if (data.session != null) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Sign in via the magic link with your email below'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _processingSignIn ? null : _signIn,
            child: Text(_processingSignIn ? 'Sending...' : 'Send Magic Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    try {
      setState(() => _processingSignIn = true);
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) context.showSnackBar('Login link sent to your email!');
    } catch (error) {
      if (mounted) context.authError(error);
    } finally {
      if (mounted) setState(() => _processingSignIn = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }
}
