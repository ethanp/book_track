import 'package:flutter/cupertino.dart';

class ColorPalette {
  static const Color appBarColor = CupertinoColors.systemGrey5;
}

class TextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: CupertinoColors.black,
  );

  static TextStyle get h2 => h1.copyWith(fontSize: 20);

  static TextStyle get h3 =>
      h2.copyWith(fontSize: 19, fontWeight: FontWeight.w600);

  static TextStyle get h4 =>
      h3.copyWith(fontSize: 18, fontWeight: FontWeight.w500);

  static TextStyle get h5 => h4.copyWith(fontSize: 16);

  static TextStyle get title => h2.copyWith(fontSize: 13);

  static TextStyle value = TextStyle(
    fontSize: 14,
    color: CupertinoColors.black,
    fontWeight: FontWeight.w400,
    letterSpacing: -.5,
  );

  static TextStyle valueButton =
      value.copyWith(color: CupertinoColors.activeBlue);

  static const TextStyle bottomAxisLabel =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get sideAxisLabel => bottomAxisLabel.copyWith(fontSize: 16);

  static TextStyle get sideAxisLabelThin =>
      sideAxisLabel.copyWith(fontWeight: FontWeight.w300, fontSize: 12.5);

  static TextStyle get h2Skinny => h2.copyWith(fontWeight: FontWeight.w300);

  static TextStyle get h2Fat => h2.copyWith(fontWeight: FontWeight.w600);
}
