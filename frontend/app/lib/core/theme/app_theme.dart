import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 배경
  static const bg = Color(0xFF111111);
  static const card = Color(0xFF1C1C1C);
  static const card2 = Color(0xFF242424);
  static const border = Color(0xFF2A2A2A);

  // 포인트 컬러
  static const lime = Color(0xFFCDD04F);
  static const green = Color(0xFF5EB58C);
  static const coral = Color(0xFFD06C52);

  // 텍스트
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFF8A8A8A);
  static const darkGray = Color(0xFF555555);

  // 상태 배지
  static const limeTag = Color(0xFFCDD04F);
  static const greenTag = Color(0x335EB58C);
  static const coralTag = Color(0x33D06C52);
  static const amberTag = Color(0x33FFB432);
  static const grayTag = Color(0xFF2A2A2A);
  static const greenTagText = Color(0xFF5EB58C);
  static const coralTagText = Color(0xFFD06C52);
  static const amberTagText = Color(0xFFC8901A);
  static const grayTagText = Color(0xFF8A8A8A);

  // 레거시 호환
  static const primary = lime;
  static const primaryDeep = Color(0xFF9DA030);
  static const primaryBg = Color(0xFF2A2C10);
  static const danger = coral;
  static const dangerBg = Color(0xFF2A1510);
  static const scaffoldBg = bg;
  static const cardBg = card;
  static const ink = white;
  static const inkSub = Color(0xFFCCCCCC);
  static const textSecondary = Color(0xFFAAAAAA);
  static const textTertiary = gray;
  static const neutralBg = card2;
  static const divider = border;
  static const freeActivity = green;
  static const freeActivityText = Color(0xFF5EB58C);
  static const freeActivityBg = Color(0xFF1A3028);
  static const amber = Color(0xFFFFB432);
  static const amberBg = Color(0xFF2A2010);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'BMJUA',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        secondary: AppColors.green,
        tertiary: AppColors.coral,
        error: AppColors.coral,
        surface: AppColors.card,
        onSurface: AppColors.white,
        onPrimary: Color(0xFF111111),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.lime,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.gray,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: const Color(0xFF111111),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.gray),
        labelStyle: const TextStyle(color: AppColors.white),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.white),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card2,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.lime,
        unselectedItemColor: AppColors.darkGray,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card2,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
