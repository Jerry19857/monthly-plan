import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeData, Brightness, Colors;

/// Catppuccin Mocha palette — ported from legacy/style.css:2-11
class AppColors {
  static const base = Color(0xFF1E1E2E);
  static const mantle = Color(0xFF181825);
  static const crust = Color(0xFF11111B);
  static const surface0 = Color(0xFF313244);
  static const surface1 = Color(0xFF45475A);
  static const surface2 = Color(0xFF585B70);
  static const overlay0 = Color(0xFF6C7086);
  static const overlay1 = Color(0xFF7F849C);
  static const subtext0 = Color(0xFFA6ADC8);
  static const subtext1 = Color(0xFFBAC2DE);
  static const text = Color(0xFFCDD6F4);
  static const blue = Color(0xFF89B4FA);
  static const teal = Color(0xFF94E2D5);
  static const green = Color(0xFFA6E3A1);
  static const yellow = Color(0xFFF9E2AF);
  static const peach = Color(0xFFFAB387);
  static const maroon = Color(0xFFEBA0AC);
  static const red = Color(0xFFF38BA8);
  static const mauve = Color(0xFFCBA6F7);
}

class AppRadius {
  static const sm = 10.0;
  static const r = 16.0;
  static const lg = 20.0;
}

// ponytail: use the iOS system font; it renders Thai fine. Bundle IBM Plex Sans
// Thai / JetBrains Mono into assets/fonts only if exact typography matters.
const String kMonoFontFamily = 'Menlo';

CupertinoThemeData buildCupertinoTheme() => const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.mauve,
      scaffoldBackgroundColor: AppColors.crust,
      barBackgroundColor: AppColors.mantle,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.mauve,
        textStyle: TextStyle(color: AppColors.text, fontSize: 15),
      ),
    );

ThemeData buildMaterialTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.crust,
      primaryColor: AppColors.mauve,
      colorScheme: ThemeData.dark().colorScheme.copyWith(
            primary: AppColors.mauve,
            surface: AppColors.mantle,
          ),
      canvasColor: AppColors.mantle,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
