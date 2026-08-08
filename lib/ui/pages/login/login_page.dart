import 'dart:async';

import 'package:book_track/main.dart';
import 'package:book_track/services/supabase_auth_service.dart';
import 'package:book_track/ui/common/app_bars.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form.dart';
import 'login_form_controllers.dart';
import 'text_and_button.dart';

const _log = ELogger('LoginPage');

class LoginPage extends StatefulWidget {
  const LoginPage();

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final LoginFormControllers loginFormC = LoginFormControllers();
  late final StreamSubscription<AuthState> _authStateSubscription;

  bool _isSignUpMode = false;
  bool _processingSignIn = false;
  bool _redirectingToLoggedInApp = false;
  String? _authError;

  @override
  void initState() {
    _pushLoggedInAppUponLogin();
    super.initState();
  }

  String signUpText({bool reverse = false}) {
    bool which = _isSignUpMode;
    if (reverse) which = !which;
    return which ? 'Sign Up' : 'Sign In';
  }

  void _pushLoggedInAppUponLogin() {
    _authStateSubscription = SupabaseAuthService.onAuthStateChange(
      onError: (Object error) => _log.error('Auth state change error: $error'),
      onEvent: (AuthState data) {
        _log.log('Auth state changed: $data');
        if (_redirectingToLoggedInApp) return;
        if (SupabaseAuthService.isLoggedIn) {
          _redirectingToLoggedInApp = true;
          if (mounted) context.pushReplacementPage(const TopLevelWidget());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(
        middle: Text(signUpText()),
      ),
      child: SafeArea(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.lg,
            ),
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'Book Track',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.burgundy,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Track your reading journey',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              LoginForm(loginFormC, _doSignIn),
              const SizedBox(height: AppSpacing.lg),
              _signInButton(),
              _showAuthErrorIfPresent(),
              _signInUpToggle(),
              _resetPassword(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showAuthErrorIfPresent() {
    if (_authError == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, top: AppSpacing.sm),
      child: Text(
        _authError!,
        style: const TextStyle(
          color: AppColors.destructive,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _signInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: CupertinoButton(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.md),
        onPressed: _processingSignIn ? null : _doSignIn,
        child: _processingSignIn
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Text(
                signUpText(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _signInUpToggle() {
    return TextAndButton(
      title: '${_isSignUpMode ? "Already" : "Don't"} have an account? ',
      buttonText: signUpText(reverse: true),
      onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
    );
  }

  Widget _resetPassword(BuildContext context) {
    return TextAndButton(
      title: 'Forgot your password? ',
      buttonText: 'Email reset link',
      onTap: () => _sendPasswordResetLink(context),
    );
  }

  Future<void> _sendPasswordResetLink(BuildContext context) async {
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
      _log.error('Unexpected error occurred: $error');
    } finally {
      if (mounted) setState(() => _processingSignIn = false);
    }
  }

  @override
  void dispose() {
    loginFormC.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }
}
