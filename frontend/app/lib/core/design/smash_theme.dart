import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// SMASH 라이트 테마. 디자인 토큰을 Material 위젯의 기본 모양으로 옮긴다.
///
/// 기존 [ThemeData] 기반 앱 테마와 따로 두었다. 화면을 하나씩 옮기는 동안
/// 화면 루트를 `Theme(data: SmashTheme.light(), child: ...)`로 감싸 쓰고,
/// 모든 화면을 옮긴 뒤 `app.dart`의 `theme:` 한 줄만 바꿔 전체에 적용한다.
abstract final class SmashTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: SmashColors.brand,
      onPrimary: SmashColors.onBrand,
      primaryContainer: SmashColors.brandTint,
      onPrimaryContainer: SmashColors.brandPressed,
      secondary: SmashColors.brand,
      onSecondary: SmashColors.onBrand,
      surface: SmashColors.surface,
      onSurface: SmashColors.text,
      onSurfaceVariant: SmashColors.textSecondary,
      error: SmashColors.danger,
      onError: SmashColors.onBrand,
      errorContainer: SmashColors.dangerBg,
      onErrorContainer: SmashColors.danger,
      outline: SmashColors.border,
      outlineVariant: SmashColors.line,
      surfaceTint: Colors.transparent, // 떠 있는 표면에 보라색 기운이 끼지 않게
      scrim: SmashColors.scrim,
    );

    final textTheme = TextTheme(
      displaySmall: SmashText.display,
      headlineSmall: SmashText.title,
      titleLarge: SmashText.title,
      titleMedium: SmashText.heading,
      titleSmall: SmashText.bodyStrong,
      bodyLarge: SmashText.body,
      bodyMedium: SmashText.body,
      bodySmall: SmashText.caption,
      labelLarge: SmashText.bodyStrong,
      labelMedium: SmashText.caption,
      labelSmall: SmashText.caption,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: SmashRadius.circular(SmashRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: SmashText.family,
      textTheme: textTheme,
      scaffoldBackgroundColor: SmashColors.background,
      canvasColor: SmashColors.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashColor: SmashColors.brand.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      dividerColor: SmashColors.line,
      iconTheme: const IconThemeData(color: SmashColors.text, size: 24),
      dividerTheme: const DividerThemeData(
        color: SmashColors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SmashColors.surface,
        foregroundColor: SmashColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: SmashText.title,
        // 밝은 배경에서는 상태 표시줄 아이콘이 어두워야 보인다 (iOS는 statusBarBrightness)
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: const WidgetStatePropertyAll(SmashText.bodyStrong),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? SmashColors.textDisabled
                : SmashColors.onBrand,
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SmashColors.fillDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return SmashColors.brandPressed;
            }
            return SmashColors.brand;
          }),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: const WidgetStatePropertyAll(SmashText.bodyStrong),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? SmashColors.textDisabled
                : SmashColors.text,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? SmashColors.line
                  : SmashColors.border,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: const WidgetStatePropertyAll(SmashText.bodyStrong),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? SmashColors.textDisabled
                : SmashColors.brand,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SmashColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SmashSpacing.md,
          vertical: 14,
        ),
        constraints: const BoxConstraints(minHeight: 52),
        hintStyle: SmashText.body.copyWith(color: SmashColors.textSecondary),
        helperStyle: SmashText.caption,
        errorStyle: SmashText.caption.copyWith(color: SmashColors.danger),
        border: _inputBorder(SmashColors.border, 1),
        enabledBorder: _inputBorder(SmashColors.border, 1),
        focusedBorder: _inputBorder(SmashColors.brand, 2),
        errorBorder: _inputBorder(SmashColors.danger, 1),
        focusedErrorBorder: _inputBorder(SmashColors.danger, 2),
        disabledBorder: _inputBorder(SmashColors.line, 1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SmashColors.onBrand
              : SmashColors.border,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SmashColors.brand
              : SmashColors.surface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : SmashColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SmashColors.brand
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(SmashColors.onBrand),
        side: const BorderSide(color: SmashColors.border, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SmashColors.brand
              : SmashColors.border,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SmashColors.surface,
        selectedColor: SmashColors.brandTint,
        side: const BorderSide(color: SmashColors.border),
        labelStyle: SmashText.body,
        shape: RoundedRectangleBorder(
          borderRadius: SmashRadius.circular(SmashRadius.sm),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsets.symmetric(horizontal: SmashSpacing.md),
        iconColor: SmashColors.textSecondary,
        textColor: SmashColors.text,
        titleTextStyle: SmashText.body,
        subtitleTextStyle: SmashText.caption,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SmashColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: SmashColors.scrim,
        elevation: 0,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: SmashRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SmashColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SmashRadius.circular(SmashRadius.lg),
        ),
        titleTextStyle: SmashText.heading,
        contentTextStyle: SmashText.body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SmashColors.text,
        contentTextStyle: SmashText.body.copyWith(color: SmashColors.onBrand),
        actionTextColor: SmashColors.brandTint,
        insetPadding: const EdgeInsets.all(SmashSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: SmashRadius.circular(SmashRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: SmashColors.brand,
        linearTrackColor: SmashColors.brandTint,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: SmashColors.brand,
        selectionColor: SmashColors.brand.withValues(alpha: 0.2),
        selectionHandleColor: SmashColors.brand,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: SmashRadius.circular(SmashRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
