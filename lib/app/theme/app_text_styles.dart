import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';

/// Типографика дизайн-системы toıdym (Figma U01 · Nunito).
abstract final class AppTextStyles {
  static const String fontFamily = 'Nunito';

  static const List<String> _fontFallback = [
    'Nunito',
    'Inter',
    'Roboto',
    'SF Pro Text',
  ];

  static const TextStyle displayHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 44 / 40,
    letterSpacing: -0.8,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 36 / 32,
    letterSpacing: -0.64,
    color: AppColors.primary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 32 / 28,
    letterSpacing: -0.56,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 28 / 22,
    letterSpacing: -0.22,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 24 / 18,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 20 / 16,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle bodyLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle label14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 20 / 14,
    color: AppColors.primaryDark,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textSecondary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 18 / 13,
    color: AppColors.textSecondary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    color: AppColors.textSecondary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 20 / 16,
    color: AppColors.primary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle priceNew = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    height: 24 / 20,
    color: AppColors.primary,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle priceOld = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 16 / 13,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textSecondary,
    fontFamilyFallback: _fontFallback,
  );
}
