import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/venue.dart';

/// Конфигурация бизнес-правил toıdym (Офлайн-бронирование + Hybrid RBAC + 3 Strikes).
abstract final class BusinessRulesConfig {
  /// Минимальная скидка на бокс.
  static const int minDiscountPercent = 50;

  /// Минимальная длительность окна самовывоза (15-минутный Спринт).
  static const int minPickupWindowMinutes = 15;

  /// Правило 15-минутного Спринта: старт за 1 час до закрытия, длительность 15 мин (напр. 19:00–19:15 при закрытии в 20:00).
  static const int sprintLeadBeforeCloseMinutes = 60;
  static const int sprintWindowMinutes = 15;
  static const int lastMinuteResaleDurationMinutes = 45;
  static const int resaleCronIntervalMinutes = 1;

  /// Публикация не позднее чем за 2 часа до начала выдачи.
  static const int minPublishLeadMinutes = 120;

  /// Подача жалобы в течение 24 часов после получения, ответ до 3 рабочих дней.
  static const int complaintDeadlineHours = 24;
  static const int complaintResponseBusinessDays = 3;

  /// Модель офлайн-бронирования: комиссия и депозиты отсутствуют (0%).
  static const double platformCommissionRate = 0.0;

  /// Отмена заказа покупателем разрешена не позднее чем за 60 минут до начала окна.
  static const int cancelBuyerUntilMinutesBeforeWindow = 60;

  /// Система 3 Strike: после 3 неявок (NO_SHOW) аккаунт блокируется на 30 дней.
  static const int maxStrikesBeforeBan = 3;
  static const int strikeBanDurationDays = 30;

  /// Брутфорс-защита авторизации: 5 неверных попыток -> блокировка на 15 минут.
  static const int maxLoginAttempts = 5;
  static const int loginLockoutMinutes = 15;

  /// Запрещённые категории товаров (алкоголь, табак, просрочка).
  static const List<String> prohibitedKeywords = [
    'алкоголь',
    'пиво',
    'вино',
    'водка',
    'коньяк',
    'виски',
    'табак',
    'сигарет',
    'вейп',
    'кальян',
    'просроч',
    'спирт',
    'арақ',
    'сыра',
    'темекі',
  ];
}

/// Типы нарушений бизнес-правил при публикации или работе с заказами.
enum BusinessRuleViolation {
  invalidPrice,
  invalidQuantity,
  discountBelowMinimum,
  pickupWindowTooShort,
  pickupWindowOutsideWorkHours,
  publishTooLate,
  halalCertNotVerified,
  prohibitedContent,
}

/// Исключение доменного слоя при нарушении бизнес-правил.
class BusinessRuleException implements Exception {
  const BusinessRuleException(this.violations);

  final List<BusinessRuleViolation> violations;

  @override
  String toString() => 'BusinessRuleException($violations)';
}

/// Чистые доменные проверки и формулы расчёта.
abstract final class BoxBusinessRules {
  static int calculateDiscountPercent({
    required int originalPrice,
    required int discountPrice,
  }) {
    if (originalPrice <= 0 ||
        discountPrice <= 0 ||
        discountPrice >= originalPrice) {
      return 0;
    }
    return (((originalPrice - discountPrice) / originalPrice) * 100).round();
  }

  /// Офлайн-оплата на месте: магазин получает 100% суммы (без комиссии).
  static int calculateVenuePayoutPerBox(int discountPrice) {
    if (discountPrice <= 0) return 0;
    return (discountPrice * (1 - BusinessRulesConfig.platformCommissionRate))
        .round();
  }

  /// Вычисляет строгое 15-минутное Спринт-окно за 1 час до закрытия заведения.
  /// Например, если заведение закрывается в 20:00 -> окно выдачи 19:00–19:15.
  static PickupWindow calculateSprintPickupWindow(
    Venue venue, {
    DateTime? now,
    bool ensureLeadTime = true,
  }) {
    final currentTime = now ?? DateTime.now();
    final closeMin = venue.workHours.closeMinuteOfDay;
    final openMin = venue.workHours.openMinuteOfDay;

    final startMin = (closeMin - BusinessRulesConfig.sprintLeadBeforeCloseMinutes)
        .clamp(openMin, closeMin - BusinessRulesConfig.sprintWindowMinutes);
    var start = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      startMin ~/ 60,
      startMin % 60,
    );

    if (ensureLeadTime &&
        start.difference(currentTime).inMinutes <
            BusinessRulesConfig.minPublishLeadMinutes) {
      final tomorrow = currentTime.add(const Duration(days: 1));
      start = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        startMin ~/ 60,
        startMin % 60,
      );
    }

    return PickupWindow(
      start: start,
      end: start.add(
        const Duration(minutes: BusinessRulesConfig.sprintWindowMinutes),
      ),
    );
  }

  /// Вычисляет окно «Второго шанса» (Last Minute Resale): от конца спринта до закрытия заведения (45 минут, напр. 19:15–20:00).
  static PickupWindow calculateResalePickupWindow({
    required Venue venue,
    required PickupWindow sprintWindow,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final closeMin = venue.workHours.closeMinuteOfDay;
    final dayClose = DateTime(
      sprintWindow.end.year,
      sprintWindow.end.month,
      sprintWindow.end.day,
      closeMin ~/ 60,
      closeMin % 60,
    );

    // Если конец спринта до закрытия (классический случай 19:15 -> 20:00), ставим [19:15 .. 20:00].
    if (sprintWindow.end.isBefore(dayClose) && dayClose.isAfter(currentTime)) {
      final start = sprintWindow.end.isAfter(currentTime)
          ? sprintWindow.end
          : currentTime;
      if (dayClose.difference(start).inMinutes >= 5) {
        return PickupWindow(start: start, end: dayClose);
      }
    }

    // Демо/вечерний фолбэк: если закрытие сегодня уже близко, открываем Last Minute окно на 45 минут с текущего момента.
    return PickupWindow(
      start: currentTime,
      end: currentTime.add(
        const Duration(
          minutes: BusinessRulesConfig.lastMinuteResaleDurationMinutes,
        ),
      ),
    );
  }

  /// Формула упущенной выгоды: `(Original_Price - Discounted_Price) * Expired_Boxes_Count`.
  static int calculateLostProfit(List<Box> expiredBoxes) {
    var total = 0;
    for (final box in expiredBoxes) {
      final unsold = box.quantityLeft > 0 ? box.quantityLeft : 1;
      final diff = (box.originalPrice - box.discountPrice).clamp(0, box.originalPrice);
      total += diff * unsold;
    }
    return total;
  }

  /// Метка «Халал» доступна только при проверенном сертификате заведения.
  static bool canUseHalalBadge(Venue venue) => venue.hasVerifiedHalalBadge;

  /// Проверяет соответствие бокса диетическим предпочтениям пользователя.
  static bool matchesDietaryPreferences(
    Box box,
    Set<DietaryPreference> preferences,
  ) {
    if (preferences.contains(DietaryPreference.halalOnly) && !box.isHalal) {
      return false;
    }
    if (preferences.contains(DietaryPreference.vegetarian) && !box.isVegetarian) {
      return false;
    }
    if (preferences.contains(DietaryPreference.nutFree)) {
      final hasNuts = box.allergens.any(
        (a) => a.toLowerCase().contains('орех') || a.toLowerCase().contains('жаңғақ'),
      );
      if (hasNuts) return false;
    }
    return true;
  }

  static List<BusinessRuleViolation> validateNewBox({
    required String title,
    required String description,
    required int originalPrice,
    required int discountPrice,
    required int quantity,
    required PickupWindow pickupWindow,
    required Venue venue,
    required bool markAsHalal,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final violations = <BusinessRuleViolation>[];

    if (originalPrice <= 0 ||
        discountPrice <= 0 ||
        discountPrice >= originalPrice) {
      violations.add(BusinessRuleViolation.invalidPrice);
    } else {
      final discount = calculateDiscountPercent(
        originalPrice: originalPrice,
        discountPrice: discountPrice,
      );
      if (discount < BusinessRulesConfig.minDiscountPercent) {
        violations.add(BusinessRuleViolation.discountBelowMinimum);
      }
    }

    if (quantity <= 0) {
      violations.add(BusinessRuleViolation.invalidQuantity);
    }

    if (pickupWindow.duration.inMinutes <
        BusinessRulesConfig.minPickupWindowMinutes) {
      violations.add(BusinessRuleViolation.pickupWindowTooShort);
    }

    if (!venue.workHours.containsWindow(pickupWindow.start, pickupWindow.end)) {
      violations.add(BusinessRuleViolation.pickupWindowOutsideWorkHours);
    }

    final leadMinutes = pickupWindow.start.difference(currentTime).inMinutes;
    if (leadMinutes < BusinessRulesConfig.minPublishLeadMinutes) {
      violations.add(BusinessRuleViolation.publishTooLate);
    }

    if (markAsHalal && !canUseHalalBadge(venue)) {
      violations.add(BusinessRuleViolation.halalCertNotVerified);
    }

    final combinedText = '${title.toLowerCase()} ${description.toLowerCase()}';
    final hasProhibited = BusinessRulesConfig.prohibitedKeywords.any(
      combinedText.contains,
    );
    if (hasProhibited) {
      violations.add(BusinessRuleViolation.prohibitedContent);
    }

    return violations;
  }

  static bool canBuyerCancelOrder({
    required Order order,
    required Box box,
    DateTime? now,
  }) {
    if (!order.status.isActive || order.isCharityBox) {
      return false;
    }
    final currentTime = now ?? DateTime.now();
    final minutesUntilStart =
        box.pickupWindow.start.difference(currentTime).inMinutes;
    return minutesUntilStart >=
        BusinessRulesConfig.cancelBuyerUntilMinutesBeforeWindow;
  }

  static bool canSubmitComplaint({
    required Order order,
    DateTime? now,
  }) {
    if (order.complaintSubmitted) return false;
    if (order.status != OrderStatus.completed &&
        order.status != OrderStatus.noShow) {
      return false;
    }
    final referenceTime = order.pickedUpAt ?? order.createdAt;
    final currentTime = now ?? DateTime.now();
    return currentTime.difference(referenceTime).inHours <=
        BusinessRulesConfig.complaintDeadlineHours;
  }
}
