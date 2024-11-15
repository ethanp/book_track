import 'package:flutter/material.dart';

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
}

extension IterableExtension<T> on Iterable<T> {
  List<U> mapL<U>(U Function(T) f) => map(f).toList();
}
