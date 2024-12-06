import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension BuildContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) =>
      print('snack bar: $message');

  void authError(Object error) {
    final String message = error is AuthException
        ? error.message
        : 'Unexpected error occurred: $error';
    showSnackBar(message, isError: true);
  }

  void pushReplacementPage(Widget widget) => Navigator.of(this)
      .pushReplacement(CupertinoPageRoute(builder: (context) => widget));

  void push(Widget widget) =>
      Navigator.of(this).push(CupertinoPageRoute(builder: (context) => widget));

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void popUntilFirst<T>([T? result]) =>
      Navigator.of(this).popUntil((route) => route.isFirst);
}

extension IterableExtension<T> on Iterable<T> {
  List<U> mapL<U>(U Function(T) f) => map(f).toList();

  Iterable<ElemAndIndex<T>> get zipWithIndex {
    int i = 0;
    return map((e) => ElemAndIndex(elem: e, idx: i++));
  }

  T minBy<U extends Comparable<U>>(U Function(T) fun) =>
      reduce((prev, curr) => fun(prev) < fun(curr) ? prev : curr);

  T maxBy<U extends Comparable<U>>(U Function(T) fun) =>
      reduce((prev, curr) => fun(prev) < fun(curr) ? curr : prev);
}

extension ComparableExtension<T extends Comparable<T>> on T {
  operator <(T other) => compareTo(other) < 0;

  T min(T other) => this < other ? this : other;
}

extension ComparableIterableExtension<T extends Comparable<T>> on Iterable<T> {
  T get min => minBy((t) => t);

  T get max => maxBy((t) => t);
}

/// We need this for [min] and [max] to work on [double] and [int], which
/// don't extend Comparable<T>, they extend num which extends Comparable<num>.
extension ComparableIterableNumExtension<T extends num> on Iterable<T> {
  T get min => minBy<num>((t) => t);

  T get max => maxBy<num>((t) => t);
}

class ElemAndIndex<T> {
  const ElemAndIndex({
    required this.elem,
    required this.idx,
  });

  final T elem;
  final int idx;
}

extension NullableObjectExtensions<T> on T? {
  U? map<U>(U Function(T) f) => this == null ? null : f(this as T);
}

extension NumExtension on num {
  double get deg2rad => this * math.pi / 180;
}

extension IntExtension on int {
  String get pad2 => toString().padLeft(2, '0');

  String get minsToHhMm {
    final hours = (this ~/ 60).pad2;
    final minutes = (this % 60).pad2;
    return '$hours:$minutes';
  }
}

extension DateTimeExtension on DateTime {
  bool sameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => sameDayAs(DateTime.now());

  double get millisSinceEpoch => millisecondsSinceEpoch.toDouble();
}

extension SupaExtension<T> on RawPostgrestBuilder<T, T, T> {
  /// Using this makes the stack trace originate from my code instead of the
  /// supabase protocol implementation, so the actual problem gets exposed.
  Future<T> captureStackTraceOnError() async {
    try {
      return await this;
    } on PostgrestException catch (e) {
      throw Exception(e);
    }
  }
}

extension StringExtension on String {
  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
