import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, Text, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:ethan_utils/ethan_utils.dart';

extension WidgetRefExtension on WidgetRef {
  Widget userLibrary(Widget Function(List<LibraryBook>) body) =>
      watch(userLibraryProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (err, trace) => Text(err.toString()),
        data: body,
      );
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
