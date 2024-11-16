import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _base = Supabase.instance.client;
  static bool get isLoggedOut => _base.auth.currentSession == null;
  static bool get isLoggedIn => !isLoggedOut;
  static Future<void> signOut() => _base.auth.signOut();

  static Future<void> signIn(String trim, String passwordInput) {
    return _base.auth.signInWithPassword(
      email: trim,
      password: passwordInput,
    );
  }

  static Future<void> signUp(String email, String password) =>
      _base.auth.signUp(email: email, password: password);

  static StreamSubscription<AuthState> onAuthStateChange(
      {required void Function(AuthState) onEvent,
      required void Function(Object) onError}) {
    return _base.auth.onAuthStateChange.listen(onEvent, onError: onError);
  }
}
