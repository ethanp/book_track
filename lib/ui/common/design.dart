import 'package:book_track/data_model.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

extension BookFormatColor on BookFormat {
  Color get color => switch (this) {
    BookFormat.audiobook => EColors.warning,
    BookFormat.eBook => const Color(0xFF5EC8C2),
    BookFormat.paperback => EColors.danger,
    BookFormat.hardcover => EColors.success,
  };
}

abstract final class AppTextStyles() {
  static TextStyle get h1 => EText.headline.medium;
  static TextStyle get h2 => EText.headline.small;
  static TextStyle get h3 => EText.section;
  static TextStyle get h4 => EText.label.large;
  static TextStyle get h5 => EText.label.medium;
  static TextStyle get body => EText.body.medium;
  static TextStyle get bodySecondary => EText.body.small.tertiary;
  static TextStyle get caption => EText.caption;
  static TextStyle get label => EText.label.small;
  static TextStyle get buttonText => EText.section.accent;
  static TextStyle get value => EText.body.small;
  static TextStyle get valueButton => EText.body.small.accent;
  static TextStyle get bottomAxisLabel => EText.label.large;
  static TextStyle get sideAxisLabel => EText.label.medium.secondary;
  static TextStyle get sideAxisLabelThin => EText.label.small;
  static TextStyle get yAxisName => EText.label.medium;
  static TextStyle get h2Skinny => EText.headline.small;
  static TextStyle get h2Fat => EText.headline.small.semibold;
}

abstract final class AppSpacing() {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadii() {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
}

abstract final class AppShadows() {
  static const BoxShadow card = BoxShadow(
    color: Color(0x47000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  );
}
