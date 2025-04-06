import 'dart:math' as math;

import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension BuildContextExtension on BuildContext {
  static SimpleLogger log = SimpleLogger(prefix: 'BuildContextExtension');

  void showSnackBar(String message, {bool isError = false}) =>
      log('snack bar: $message', error: isError);

  void pushReplacementPage(Widget widget) => Navigator.of(this)
      .pushReplacement(CupertinoPageRoute(builder: (context) => widget));

  void push(Widget widget) =>
      Navigator.of(this).push(CupertinoPageRoute(builder: (context) => widget));

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void popUntilFirst<T>([T? result]) =>
      Navigator.of(this).popUntil((route) => route.isFirst);
}

extension WidgetRefExtension on WidgetRef {
  Widget userLibrary(Widget Function(List<LibraryBook>) body) =>
      watch(userLibraryProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (err, trace) => Text(err.toString()),
        data: body,
      );
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

extension ListExtension<T> on List<T> {
  void sortOn(Comparable Function(T) cmp) =>
      sort((a, b) => cmp(a).compareTo(cmp(b)));

  /// You provide a function, which takes each element, starting at the second
  /// one, and pairs it with the previous element, and turns them into something
  /// else, which is returned in a list (in the same order as the input).
  ///
  /// This is not written with performance in mind 🤪.
  List<B> zipWithPrev<B>(B Function(T prev, T curr) f) {
    if (length < 2) return [];
    return skip(1).zipWithIndex.mapL((e) {
      final T prev = this[e.idx];
      final T curr = e.elem;
      return f(prev, curr);
    });
  }
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

  @override
  String toString() => '{elem: $elem, idx: $idx}';
}

extension NullableObjectExtensions<T> on T? {
  U? map<U>(U Function(T) f) => this == null ? null : f(this as T);
}

extension NumExtension on num {
  double get deg2rad => this * math.pi / 180;
}

extension IntExtension on int {
  String pad(int n) => toString().padLeft(n, '0');

  String get hours => (this ~/ 60).pad(1);

  String get minutes => (this % 60).pad(2);

  String get minsToHhMm {
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

extension EnumName on Enum {
  String get nameAsCapitalizedWords {
    if (name.isEmpty) return name;
    final result = name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }
}
