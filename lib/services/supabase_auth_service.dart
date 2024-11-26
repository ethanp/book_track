import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class SupabaseAuthService {
  static final GoTrueClient _authClient = supabase.auth;

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
}
