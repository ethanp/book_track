import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFC8956C);
  static const Color primaryLight = Color(0xFFE8C9A8);
  static const Color surface = Color(0xFFFFF9F3);
  static const Color background = Color(0xFFF5F0EA);
  static const Color burgundy = Color(0xFF8B3A3A);
  static const Color burgundyLight = Color(0xFFC27070);
  static const Color teal = Color(0xFF2A7C76);
  static const Color tealLight = Color(0xFF7BC4BF);
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF7A6B5D);
  static const Color destructive = Color(0xFFB84040);
  static const Color success = Color(0xFF4A8B5C);
  static const Color successLight = Color(0xFFCDE7D4);
  static const Color divider = Color(0xFFE5DDD4);
  static const Color shimmer = Color(0xFFE8E0D6);

  static const Color navBarBackground = Color(0xF5F5F0EA);
  static const Color tabBarActive = Color(0xFFC8956C);
  static const Color tabBarInactive = Color(0xFF9A8B7D);

  static const Color progressBarTrack = Color(0xFFE8E0D6);

  static const Color heatmapEmpty = Color(0xFFEDE7DF);
  static const Color heatmapLight = Color(0xFFE8C9A8);
  static const Color heatmapMedium = Color(0xFFC8956C);
  static const Color heatmapDark = Color(0xFFA86E4A);
  static const Color heatmapFull = Color(0xFF8B3A3A);

  static const Color audiobook = Color(0xFFC8956C);
  static const Color ebook = Color(0xFF2A7C76);
  static const Color paperback = Color(0xFF8B3A3A);
  static const Color hardcover = Color(0xFF5B7A5E);
}

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.merriweather(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static const TextStyle h4 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: -0.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle value = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
  );

  static const TextStyle valueButton = TextStyle(
    fontSize: 14,
    color: AppColors.primary,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  static const TextStyle bottomAxisLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get sideAxisLabel =>
      bottomAxisLabel.copyWith(fontSize: 16, color: AppColors.textSecondary);

  static TextStyle get sideAxisLabelThin => sideAxisLabel.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 12.5,
      );

  /// Unified style for vertical (y) axis name labels across all charts.
  static TextStyle get yAxisName => sideAxisLabel.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle get h2Skinny => h2.copyWith(fontWeight: FontWeight.w300);

  static TextStyle get h2Fat => h2.copyWith(fontWeight: FontWeight.w600);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadii {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
}

class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: Color(0x1A8B7B6B),
    spreadRadius: 0,
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow cardHover = BoxShadow(
    color: Color(0x268B7B6B),
    spreadRadius: 1,
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow coverArt = BoxShadow(
    color: Color(0x338B7B6B),
    spreadRadius: 0,
    blurRadius: 6,
    offset: Offset(2, 3),
  );
}
