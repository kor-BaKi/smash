import 'package:flutter/material.dart';

/// 시맨틱 색상 (참여/불참/이월/자유활동 등 상태별 고정 색상)
/// ColorScheme에 없는 세부 톤(연한 배경색 등)은 여기서 관리합니다.
class AppColors {
  AppColors._();

  // Primary - 참여/확정/저장
  static const primary = Color(0xFF1F6FEB);
  static const primaryDeep = Color(0xFF0B3A86);
  static const primaryLight = Color(0xFF6FA8F5);
  static const primaryBg = Color(0xFFE8F1FE);

  // Secondary - 자유활동
  static const freeActivity = Color(0xFF05A66B);
  static const freeActivityText = Color(0xFF05854F);
  static const freeActivityBg = Color(0xFFE4F7EF);

  // Tertiary - 이월/타조참
  static const amber = Color(0xFFE8890C);
  static const amberBg = Color(0xFFFFF4E0);

  // Error - 경고/취소/불합격
  static const danger = Color(0xFFF04452);
  static const dangerBg = Color(0xFFFEECEE);

  // Neutral - 텍스트/배경
  static const ink = Color(0xFF191F28);
  static const inkSub = Color(0xFF333D4B);
  static const textSecondary = Color(0xFF4E5968);
  static const textTertiary = Color(0xFF8B95A1);
  static const divider = Color(0xFFD1D6DB);
  static const neutralBg = Color(0xFFF2F4F6);
  static const scaffoldBg = Color(0xFFF2F4F6);
  static const cardBg = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: AppColors.scaffoldBg,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.freeActivity,
        tertiary: AppColors.amber,
        error: AppColors.danger,
        surface: AppColors.cardBg,
        onSurface: AppColors.ink,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.inkSub,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutralBg,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      ),
    );
  }
}
