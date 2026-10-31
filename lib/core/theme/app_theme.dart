import 'package:flutter/material.dart';

import '../../ui/tokens/app_tokens.dart';

/// Theme dựng **hoàn toàn** từ token (`lib/ui/tokens/app_tokens.dart`).
///
/// Thay cho theme Material 3 teal cũ: nền kem, CTA san hô, card bo 24 không viền,
/// bottom sheet bo 32 — khớp 8 ảnh tham chiếu.
class AppTheme {
  // --- Tương thích ngược: code cũ còn gọi AppTheme.primaryTeal/... ---
  // Giá trị trỏ về token mới để cả app dùng một bảng màu duy nhất.
  static const Color primaryTeal = AppColors.coral;
  static const Color primaryDark = AppColors.coralDark;
  static const Color accentAmber = AppColors.warning;
  static const Color accentOrange = AppColors.terracotta;
  static const Color surfaceBg = AppColors.bg;
  static const Color cardColor = AppColors.surface;
  static const Color sponsoredIndigo = Color(0xFF4F46E5);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      primary: AppColors.coral,
      secondary: AppColors.terracotta,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ).copyWith(
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: const TextTheme(
        displaySmall: AppText.display,
        headlineMedium: AppText.h1,
        titleLarge: AppText.h2,
        titleMedium: AppText.h3,
        bodyMedium: AppText.body,
        bodySmall: AppText.bodySm,
        labelLarge: AppText.label,
        labelSmall: AppText.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppText.h3,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: AppText.label,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x3, vertical: AppSpace.x1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          textStyle: AppText.h3.copyWith(fontSize: 15, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.x4, vertical: AppSpace.x3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
        ),
        hintStyle: AppText.bodySm,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.bodySm.copyWith(color: AppColors.textOnDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
    );
  }

  // Giữ tương thích với code cũ đang gọi `AppTheme.lightTheme`.
  static ThemeData get lightTheme => light();
}
