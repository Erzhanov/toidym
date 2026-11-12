import 'package:flutter/material.dart';

/// Цветовые токены дизайн-системы toıdym (Design Toidym.svg).
abstract final class AppColors {
  // Основные цвета бренда (глубокий индиго #2B2350, жёлтый #FFC94D, крем #FFF5DF)
  static const Color primary = Color(0xFF2B2350);
  static const Color raisedIndigo = Color(0xFF3A3168);
  static const Color primaryDark = Color(0xFF1B1633);
  static const Color primaryLight = Color(0xFFEFECF5);

  static const Color accent = Color(0xFFFFC94D);
  static const Color accentDark = Color(0xFFE6AE30);
  static const Color accentLight = Color(0xFFFFE8A8);

  static const Color background = Color(0xFFFFF5DF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFCF6EB);
  static const Color lavenderBg = Color(0xFFF7F6FA);
  static const Color lavenderChip = Color(0xFFC9C2E6);

  // Навигация
  static const Color navPill = Color(0xFF2B2350);
  static const Color navInactive = Color(0xFFC9C2E6);

  // Текст (контраст ≥ 4.5:1 по WCAG AA)
  static const Color textPrimary = Color(0xFF1B1633);
  static const Color textSecondary = Color(0xFF5A527A);
  static const Color textOnCreamSecondary = Color(0xFF5A527A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF2B2350);

  // Семантические цвета (Design Toidym.svg)
  static const Color success = Color(0xFF315B40);
  static const Color successLight = Color(0xFFE6EDDC);
  static const Color successText = Color(0xFF315B40);

  static const Color error = Color(0xFFA63D35);
  static const Color errorLight = Color(0xFFFCE7DB);
  static const Color errorText = Color(0xFF9A3D32);

  static const Color warning = Color(0xFF9A3D32);
  static const Color warningLight = Color(0xFFFFE8A8);
  static const Color warningText = Color(0xFF2B2350);

  // Границы, разделители, тени, шиммер
  static const Color border = Color(0xFFE7E3EE);
  static const Color inputBorder = Color(0xFFD6D0E6);
  static const Color cardBorder = Color(0xFFEAE3CF);
  static const Color divider = Color(0xFFEFEBF5);
  static const Color shadow = Color(0x1A2B244F);
  static const Color navShadow = Color(0x2E1B1633);
  static const Color scrim = Color(0x661B1633);
  static const Color sidebarActiveCard = Color(0xFF3A3168);

  static const List<BoxShadow> cardShadows = [
    BoxShadow(
      color: shadow,
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> navShadows = [
    BoxShadow(
      color: navShadow,
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];
  static const Color shimmerBase = Color(0xFFEDE5CE);
  static const Color shimmerHighlight = Color(0xFFFFFBF0);

  // Специальные цвета маскота Құмбек и карточек (без глаз!)
  static const Color mascotSand = Color(0xFFE6B97A);
  static const Color mascotSandDark = Color(0xFFC48E4D);
  static const Color mascotEarInner = Color(0xFFF5D8AE);
  static const Color mascotGlasses = Color(0xFF1E2235);
  static const Color mascotGlassesGlare = Color(0xFF5A6594);
  static const Color silhouetteLocked = Color(0xFF393E59);
}
