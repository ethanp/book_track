import 'package:flutter/material.dart';

/// These could all be `static`, except then they couldn't be hot-reloaded.

class ColorPalette {
  final appBarColor = Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8);
}

class TextStyles {
  final h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );
  TextStyle get h2 => h1.copyWith(fontSize: 20);

  final bottomAxisLabel = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  TextStyle get sideAxisLabel => bottomAxisLabel.copyWith(fontSize: 16);

  TextStyle get h2Skinny => h2.copyWith(fontWeight: FontWeight.w300);
  TextStyle get h2Fat => h2.copyWith(fontWeight: FontWeight.w600);
}
