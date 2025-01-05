import 'package:book_track/helpers.dart';
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
  TextStyle get h3 => h2.copyWith(fontSize: 19, fontWeight: FontWeight.w600);
  TextStyle get h4 => h3.copyWith(fontSize: 18, fontWeight: FontWeight.w500);
  TextStyle get h5 => h4.copyWith(fontSize: 16);
  TextStyle get title => h2.copyWith(fontSize: 13);
  TextStyle get value => TextStyle(
        fontSize: 14,
        color: Colors.grey[900],
        fontWeight: FontWeight.w500,
        letterSpacing: -.5,
      );

  final bottomAxisLabel = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  TextStyle get sideAxisLabel => bottomAxisLabel.copyWith(fontSize: 16);

  TextStyle get h2Skinny => h2.copyWith(fontWeight: FontWeight.w300);
  TextStyle get h2Fat => h2.copyWith(fontWeight: FontWeight.w600);
}

class Buttons {
  static ButtonStyle updateButtonStyle({required Color color}) {
    return ElevatedButton.styleFrom(
      shape: FlutterHelpers.roundedRect(radius: 10),
      elevation: 0.3,
      visualDensity: VisualDensity.compact,
      fixedSize: Size(70, /* ignored :( */ 10),
      padding: EdgeInsets.zero,
      backgroundColor: color,
    );
  }
}
