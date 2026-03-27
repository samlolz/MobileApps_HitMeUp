import 'package:flutter/material.dart';

class AppColors {
  static const Color pinkTop = Color(0xFFFF4081);
  static const Color mintMid = Color(0xFFE0F2F1);
  static const Color blueBottom = Color(0xFF448AFF);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color accent = Color(0xFFFF4081);
}

class AppGradient {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFF4081),
      Color(0xFFE0F2F1),
      Color(0xFF448AFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: AppColors.textDark,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    fontFamily: 'Nunito',
    primaryColor: AppColors.pinkTop,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.pinkTop,
      brightness: Brightness.light,
    ),
  );
}
