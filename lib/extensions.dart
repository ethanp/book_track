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

  void showSnackBar(String message, {bool isError = false}) {
    showCupertinoDialog(
      context: this,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(isError ? 'Error' : 'Info'),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

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

extension Flattenable<T> on Iterable<Iterable<T>> {
  Iterable<T> get flatten => expand((e) => e);
}

extension ListExtension<T> on List<T> {
  void sortOn(Comparable Function(T) cmp) =>
      sort((a, b) => cmp(a).compareTo(cmp(b)));

  /// You provide a function, which takes each element, paired with the
  /// element [diff] away, a turns them into a [B], which is
  /// returned in an [Iterable], in the same order as `this` [List].
  ///
  /// Iteration stops when there are no two elements [diff] away.
  /// So if `diff=n`, then the resulting iterable will have
  /// `length = orig.length - n`. If `n > orig.length`, then the
  /// returned [Iterable] will be empty.
  ///
  /// [diff] is allowed to be positive or negative or zero.
  Iterable<B> zipWithDiff<B>(int diff, B Function(T curr, T diffAway) f) sync* {
    int i = math.max(0, -diff);
    int j = math.max(0, diff);

    while (math.max(i, j) < length) {
      yield f(this[i++], this[j++]);
    }
  }
}

extension ComparableExtension<T extends Comparable<T>> on T {
  bool operator <(T other) => compareTo(other) < 0;

  T min(T other) => this < other ? this : other;
}

extension ComparableIterableExtension<T extends Comparable<T>> on Iterable<T> {
  T get min => minBy((t) => t);

  T get max => maxBy((t) => t);
}

/// We need this for [min] and [max] to work on [double] and [int], which
/// don't extend [Comparable<T>], they extend num which extends [Comparable<num>].
/// Perhaps there's some way to combine them together?
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
      isEmpty ? this : characters.first.toUpperCase() + substring(1);
}

extension EnumName on Enum {
  /// Captures a single capital letter.
  static final isCapital = RegExp(r'([A-Z])');

  String get nameAsCapitalizedWords => name
      .replaceAllMapped(isCapital, (match) => ' ${match.group(0)}')
      .trim()
      .capitalize;
}
