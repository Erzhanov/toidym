import 'package:flutter/material.dart';

/// Токены отступов и размеров дизайн-системы toıdym.
abstract final class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const double screenHorizontal = 16.0;
  static const double cardPadding = 16.0;
  static const double buttonHeight = 56.0;
  static const double smallButtonHeight = 44.0;
  static const double chipHeight = 44.0;
  static const double minTouchTarget = 48.0;
}

/// Токены скруглений дизайн-системы toıdym (H02: Card 22 · CTA 28 · Chip 20 · Sheet 32).
abstract final class AppRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double chip = 20.0;
  static const double lg = 22.0;
  static const double cta = 28.0;
  static const double sheet = 32.0;
  static const double dock = 36.0;
  static const double pill = 999.0;

  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(lg),
  );
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(cta),
  );
  static const BorderRadius chipBorderRadius = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius badgeBorderRadius = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius inputBorderRadius = BorderRadius.all(
    Radius.circular(26),
  );
}
