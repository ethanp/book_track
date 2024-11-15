import 'package:flutter/material.dart';

class ColorPalette {
  static final appBarColor =
      Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8);
}

class TextStyles {
  static final h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
  static final h2 = TextStyle(fontWeight: FontWeight.w500);
}
