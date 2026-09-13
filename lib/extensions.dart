import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart'
    show CircularProgressIndicator, Text, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension WidgetRefExtension on WidgetRef {
  Widget userLibrary(Widget Function(List<LibraryBook>) body) =>
      watch(userLibraryProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (err, trace) => Text(err.toString()),
        data: body,
      );
}
