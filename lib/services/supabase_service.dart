import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _base = Supabase.instance.client;

class SupabaseAuthService {
  static final GoTrueClient _authClient = _base.auth;

  static bool get isLoggedOut => _authClient.currentSession == null;

  static String? get loggedInUserId => _authClient.currentSession?.user.id;

  static bool get isLoggedIn => !isLoggedOut;

  static Future<void> signOut() => _authClient.signOut();

  static Future<void> signIn(String trim, String passwordInput) {
    return _authClient.signInWithPassword(
      email: trim,
      password: passwordInput,
    );
  }

  static Future<void> signUp(String email, String password) =>
      _authClient.signUp(email: email, password: password);

  static StreamSubscription<AuthState> onAuthStateChange(
      {required void Function(AuthState) onEvent,
      required void Function(Object) onError}) {
    return _authClient.onAuthStateChange.listen(onEvent, onError: onError);
  }
}

class SupabaseDataService {
  static final _bucketClient = _base.storage;

  static Future<String> storeCoverArtS(int coverI, Uint8List data) async =>
      await _bucketClient.from('cover_art').uploadBinary('s/$coverI.jpg', data);

  static Future<void> storeBook(Book book, BookType bookType) async {
    final String? coverStorageLoc = book.coverArtS == null
        ? null
        : await storeCoverArtS(book.openLibCoverId!, book.coverArtS!);

    return await _base.from('books').insert({
      'added_at': DateTime.now().toIso8601String(),
      'title': book.title,
      'author': book.author,
      'first_year_published': book.yearFirstPublished,
      'type': bookType.name,
      'length': book.bookLength,
      'openlib_cover_id': book.openLibCoverId,
      'small_cover_key': coverStorageLoc,
    });
  }
}
