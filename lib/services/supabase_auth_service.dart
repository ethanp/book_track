import 'dart:async';

import 'package:book_track/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class SupabaseAuthService {
  static final GoTrueClient _authClient = supabase.auth;

  static SimpleLogger log = SimpleLogger(prefix: 'SupabaseAuthService');

  static bool get isLoggedOut => _authClient.currentSession == null;

  static String? get loggedInUserId => _authClient.currentSession?.user.id;

  static bool get isLoggedIn => !isLoggedOut;

  static Future<void> signOut() => _authClient.signOut();

  static Future<void> signIn(String trim, String passwordInput) {
    try {
      return _authClient.signInWithPassword(
        email: trim,
        password: passwordInput,
      );
    } on AuthException catch (e) {
      // Doing this captures the stack trace better.
      throw Exception(e);
    }
  }

  static Future<void> signUp(String email, String password) =>
      _authClient.signUp(email: email, password: password);

  static StreamSubscription<AuthState> onAuthStateChange(
      {required void Function(AuthState) onEvent,
      required void Function(Object) onError}) {
    return _authClient.onAuthStateChange.listen(onEvent, onError: onError);
  }

  static Future<void> sentPasswordResetLink(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  static Future<void> resetPassword({
    required String emailInput,
    required String passwordInput,
    required String tokenInput,
  }) async {
    final recovery = await supabase.auth.verifyOTP(
      email: emailInput,
      token: tokenInput,
      type: OtpType.recovery,
    );
    log('recovery $recovery');
    await supabase.auth.updateUser(UserAttributes(
      password: passwordInput,
    ));
  }
}
