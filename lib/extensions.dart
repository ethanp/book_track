import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension BuildContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
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

  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}

extension IterableExtension<T> on Iterable<T> {
  List<U> mapL<U>(U Function(T) f) => map(f).toList();

  Iterable<ElemAndIndex<T>> get zipWithIndex {
    int i = 0;
    return map((e) => ElemAndIndex(elem: e, idx: i++));
  }
}

class ElemAndIndex<T> {
  const ElemAndIndex({required this.elem, required this.idx});
  final T elem;
  final int idx;
}

extension NullableObjectExtensions<T> on T? {
  U? ifExists<U>(U Function(T) f) => this == null ? null : f(this as T);
}

extension NumExtension on num {
  double get deg2rad => this * math.pi / 180;
}
