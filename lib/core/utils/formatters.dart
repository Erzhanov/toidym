import 'dart:math' as math;

import 'package:toidym/core/l10n/app_localizations.dart';
import 'package:toidym/shared/models/box.dart';

/// Утилиты форматирования цен, расстояний, времени и расчёта дистанции в Астане.
abstract final class AppFormatters {
  static const String nbsp = '\u00A0';
  static const String minusSign = '\u2212';

  /// Форматирует сумму в тенге с неразрывным пробелом: `2 970 ₸`.
  static String formatPrice(int tenge) {
    final absValue = tenge.abs();
    final digits = absValue.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromRight = digits.length - i;
      if (i > 0 && positionFromRight % 3 == 0) {
        buffer.write(nbsp);
      }
      buffer.write(digits[i]);
    }
    final prefix = tenge < 0 ? minusSign : '';
    return '$prefix$buffer$nbsp₸';
  }

  /// Форматирует процент скидки: `−67%`.
  static String formatDiscount(int percent) {
    final safePercent = percent.clamp(0, 99);
    return '$minusSign$safePercent%';
  }

  /// Форматирует окно выдачи: `20:00–21:00`.
  static String formatPickupWindow(PickupWindow window) => window.formatted;

  /// Форматирует расстояние в метрах или километрах с учётом локали.
  static String formatDistance(double km, AppLocalizations l10n) {
    if (km < 1.0) {
      final meters = ((km * 1000) / 10).round() * 10;
      return l10n.distanceMeters(meters.clamp(50, 990));
    }
    return l10n.distanceKm(km.toStringAsFixed(1));
  }

  /// Форматирует вес спасённой еды: `8.4 кг`.
  static String formatWeightKg(double kg, AppLocalizations l10n) {
    return l10n.weightKg(kg.toStringAsFixed(1));
  }

  /// Форматирует оставшееся время обратного отсчёта.
  static String formatRemainingDuration(
    Duration remaining,
    AppLocalizations l10n,
  ) {
    if (remaining.isNegative || remaining.inMinutes < 1) {
      return l10n.timerMinutesShort(0);
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) {
      return l10n.timerHoursMinutes(hours, minutes);
    }
    return l10n.timerMinutesShort(minutes);
  }

  /// Вычисляет расстояние между двумя координатами в километрах (формула Хаверсина).
  static double calculateDistanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(toLat - fromLat);
    final dLng = _degToRad(toLng - fromLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(fromLat)) *
            math.cos(_degToRad(toLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
