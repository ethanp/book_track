import 'dart:io';
import 'dart:typed_data';

import 'package:book_track/ui/common/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads JPEG cover pixel size from the unknown-cover asset', () {
    final Uint8List bytes = File('assets/images/unknown_book_cover.jpg')
        .readAsBytesSync();

    expect(BookCover.pixelSizeOf(bytes), const Size(682, 1024));
    expect(BookCover.aspectRatioOf(bytes), 682 / 1024);
  });

  test('falls back to the unknown-cover aspect when bytes are missing', () {
    expect(BookCover.pixelSizeOf(null), isNull);
    expect(BookCover.aspectRatioOf(null), BookCover.fallbackAspectRatio);
  });
}
