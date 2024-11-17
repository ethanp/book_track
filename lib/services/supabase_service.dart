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

class SupabaseBookService {
  static final _bucketClient = _base.storage;

  static Future<PostgrestMap> storeBook(Book book) async {
    final PostgrestList preExistResponse = await _fetchPreExisting(book);
    if (preExistResponse.isNotEmpty) return preExistResponse.first;
    final String? coverStorageLoc = book.coverArtS == null
        ? null
        : await _storeCoverArtS(book.openLibCoverId!, book.coverArtS!);

    return await _base
        .from('books')
        .insert({
          'added_at': DateTime.now().toIso8601String(),
          'title': book.title,
          'author': book.author,
          'first_year_published': book.yearFirstPublished,
          'length': book.bookLength,
          'openlib_cover_id': book.openLibCoverId,
          'small_cover_key': coverStorageLoc,
        })
        .select()
        .single();
  }

  static Future<PostgrestList> _fetchPreExisting(Book book) async {
    PostgrestFilterBuilder<PostgrestList> preExistQuery =
        _base.from('books').select('id');
    preExistQuery = preExistQuery.eq('title', book.title);
    if (book.author != null) {
      preExistQuery = preExistQuery.eq('author', book.author!);
    }
    if (book.openLibCoverId != null) {
      preExistQuery =
          preExistQuery.eq('openlib_cover_id', book.openLibCoverId!);
    }
    try {
      final PostgrestList preExistResponse = await preExistQuery.limit(1);
      return preExistResponse;
    } on StorageException catch (e) {
      print('pre-existing book query error $e');
      return [];
    }
  }

  static Future<String> _storeCoverArtS(int coverI, Uint8List data) async =>
      await _bucketClient.from('cover_art').uploadBinary('s/$coverI.jpg', data);
}

class SupabaseLibraryService {
  static Future<void> addBook(Book book, BookType bookType) async {
    final PostgrestMap storedBook = await SupabaseBookService.storeBook(book);
    final PostgrestList preExistQuery = await _base
        .from('library')
        .select('id')
        .eq('book_id', storedBook['id'])
        .eq('user_id', SupabaseAuthService.loggedInUserId!)
        .eq('format', bookType.name)
        .limit(1);
    if (preExistQuery.isNotEmpty) {
      print('library item already exists, not adding.');
      return;
    }
    return await _base.from('library').insert({
      'book_id': storedBook['id'],
      'user_id': SupabaseAuthService.loggedInUserId,
      'format': bookType.name,
    });
  }
}
