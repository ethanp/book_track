import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension BuildContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }

  void authError(Object error) {
    final String message = error is AuthException
        ? error.message
        : 'Unexpected error occurred: $error';
    showSnackBar(message, isError: true);
  }

  void pushReplacementPage(Widget widget) => Navigator.of(this)
      .pushReplacement(MaterialPageRoute(builder: (context) => widget));

  void push(Widget widget) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (context) => widget));
}

extension IterableExtension<T> on Iterable<T> {
  List<U> mapL<U>(U Function(T) f) => map(f).toList();
}
