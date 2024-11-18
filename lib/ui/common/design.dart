import 'package:flutter/material.dart';

/// These could all be static, except then I can't hot reload it so well.

class ColorPalette {
  final appBarColor = Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8);
}

class TextStyles {
  final h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );
  final h2 = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  final bottomAxisLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  final sideAxisLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  get h2Skinny => h2.copyWith(fontWeight: FontWeight.w300);
  get h2Fat => h2.copyWith(fontWeight: FontWeight.w600);
}
