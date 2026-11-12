/// Роль пользователя в Hybrid RBAC системе toıdym.
///
/// - [buyer] (`USER`): покупатель, прошедший email-регистрацию.
/// - [partner] (`PARTNER`): владелец одобренного заведения.
/// - [cashier] (`CASHIER`): сотрудник выдачи магазина (видит только «Выдача»).
/// - [admin] (`ADMIN`): администратор платформы.
enum UserRole {
  buyer('USER'),
  partner('PARTNER'),
  cashier('CASHIER'),
  admin('ADMIN');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole fromApi(String? value) {
    final normalized = value?.toUpperCase();
    return switch (normalized) {
      'USER' || 'BUYER' => UserRole.buyer,
      'PARTNER' || 'OWNER' => UserRole.partner,
      'CASHIER' => UserRole.cashier,
      'ADMIN' => UserRole.admin,
      _ => UserRole.buyer,
    };
  }
}

/// Поддерживаемые языки приложения.
enum AppLanguage {
  kk('kk'),
  ru('ru');

  const AppLanguage(this.code);
  final String code;

  static AppLanguage fromCode(String? value) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == value,
      orElse: () => AppLanguage.ru,
    );
  }
}

/// Активный режим интерфейса (Покупатель / Магазин / Админ-панель).
enum AppMode {
  buyer('buyer'),
  venue('venue'),
  admin('admin');

  const AppMode(this.code);
  final String code;

  static AppMode fromCode(String? value) {
    return AppMode.values.firstWhere(
      (e) => e.code == value,
      orElse: () => AppMode.buyer,
    );
  }
}

/// Диетические предпочтения покупателя.
enum DietaryPreference {
  halalOnly('halal_only'),
  vegetarian('vegetarian'),
  nutFree('nut_free');

  const DietaryPreference(this.apiValue);
  final String apiValue;

  static DietaryPreference fromApi(String? value) {
    return DietaryPreference.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => DietaryPreference.halalOnly,
    );
  }
}

/// Критерий умной сортировки каталога боксов.
enum BoxSortOption {
  nearest,
  endingSoon,
  maxDiscount,
}

/// Статус рассмотрения жалобы по заказу.
enum ComplaintStatus {
  none('none'),
  open('open'),
  inReview('in_review'),
  resolved('resolved');

  const ComplaintStatus(this.apiValue);
  final String apiValue;

  bool get isOpen => this == open || this == inReview;

  static ComplaintStatus fromApi(String? value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ComplaintStatus.none,
    );
  }
}

/// Жители коллекции «Қызыл кітап».
enum QyzylKitapAnimal {
  qumbek(apiValue: 'qumbek', requiredBoxes: 0),
  irbis(apiValue: 'irbis', requiredBoxes: 15),
  saigak(apiValue: 'saigak', requiredBoxes: 30),
  seal(apiValue: 'seal', requiredBoxes: 50);

  const QyzylKitapAnimal({
    required this.apiValue,
    required this.requiredBoxes,
  });

  final String apiValue;
  final int requiredBoxes;

  QyzylKitapAnimal? get nextAnimal {
    final idx = QyzylKitapAnimal.values.indexOf(this);
    if (idx < 0 || idx + 1 >= QyzylKitapAnimal.values.length) {
      return null;
    }
    return QyzylKitapAnimal.values[idx + 1];
  }

  static QyzylKitapAnimal fromBoxesSaved(int boxesSaved) {
    QyzylKitapAnimal result = QyzylKitapAnimal.qumbek;
    for (final animal in QyzylKitapAnimal.values) {
      if (boxesSaved >= animal.requiredBoxes) {
        result = animal;
      }
    }
    return result;
  }

  static QyzylKitapAnimal fromApi(String? value) {
    return QyzylKitapAnimal.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => QyzylKitapAnimal.qumbek,
    );
  }
}

/// Районы Астаны.
enum AstanaDistrict {
  esil('esil', 51.1282, 71.4304),
  almaty('almaty', 51.1486, 71.4712),
  saryarka('saryarka', 51.1694, 71.4126),
  baiqonyr('baiqonyr', 51.1742, 71.4519);

  const AstanaDistrict(this.code, this.centerLat, this.centerLng);
  final String code;
  final double centerLat;
  final double centerLng;

  static AstanaDistrict fromCode(String? value) {
    return AstanaDistrict.values.firstWhere(
      (e) => e.code == value,
      orElse: () => AstanaDistrict.esil,
    );
  }

  static AstanaDistrict fromDynamic(dynamic value) {
    if (value is num) {
      final idx = value.toInt();
      if (idx >= 0 && idx < AstanaDistrict.values.length) {
        return AstanaDistrict.values[idx];
      }
      return AstanaDistrict.esil;
    }
    return fromCode(value?.toString());
  }
}

/// Категория заведения.
enum VenueCategory {
  bakery('bakery'),
  hotFood('hot_food'),
  coffee('coffee'),
  grocery('grocery');

  const VenueCategory(this.apiValue);
  final String apiValue;

  static VenueCategory fromApi(String? value) {
    return VenueCategory.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => VenueCategory.bakery,
    );
  }
}

/// Статус проверки сертификата «Халал».
enum HalalCertStatus {
  none('none'),
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const HalalCertStatus(this.apiValue);
  final String apiValue;

  static HalalCertStatus fromApi(String? value) {
    return HalalCertStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => HalalCertStatus.none,
    );
  }
}

/// Статус модерации заведения.
enum VenueStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  banned('BANNED');

  const VenueStatus(this.apiValue);
  final String apiValue;

  static VenueStatus fromApi(String? value) {
    final normalized = value?.toUpperCase();
    return VenueStatus.values.firstWhere(
      (e) => e.apiValue == normalized,
      orElse: () => VenueStatus.pending,
    );
  }
}

/// Тип бокса: сюрприз-бокс или конкретный набор.
enum BoxType {
  surprise('surprise'),
  set('set');

  const BoxType(this.apiValue);
  final String apiValue;

  static BoxType fromApi(String? value) {
    return BoxType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => BoxType.surprise,
    );
  }
}

/// Категория бокса для фильтрации покупателем.
enum BoxCategory {
  bakery('bakery'),
  hotFood('hot_food'),
  coffee('coffee');

  const BoxCategory(this.apiValue);
  final String apiValue;

  static BoxCategory fromApi(String? value) {
    return BoxCategory.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => BoxCategory.bakery,
    );
  }
}

/// Фильтр на главной экране и карте.
enum BoxFilterChip {
  all,
  bakery,
  hotFood,
  halal,
  coffee,
}

/// Статус бокса (включая EXPIRED / ARCHIVED после окончания окна выдачи).
enum BoxStatus {
  active('ACTIVE'),
  soldOut('SOLD_OUT'),
  disabled('DISABLED'),
  expired('EXPIRED');

  const BoxStatus(this.apiValue);
  final String apiValue;

  static BoxStatus fromApi(String? value) {
    final normalized = value?.toUpperCase();
    return switch (normalized) {
      'ACTIVE' => BoxStatus.active,
      'SOLD_OUT' => BoxStatus.soldOut,
      'DISABLED' => BoxStatus.disabled,
      'EXPIRED' || 'ARCHIVED' => BoxStatus.expired,
      _ => BoxStatus.active,
    };
  }
}

/// Статус заказа в модели доверительного бронирования (офлайн-оплата на месте).
enum OrderStatus {
  reserved('RESERVED'),
  completed('COMPLETED'),
  cancelledByUser('CANCELLED_BY_USER'),
  cancelledByVenue('CANCELLED_BY_VENUE'),
  noShow('NO_SHOW');

  const OrderStatus(this.apiValue);
  final String apiValue;

  bool get isActive => this == reserved;
  bool get isCancelled =>
      this == cancelledByUser || this == cancelledByVenue;

  static OrderStatus fromApi(String? value) {
    final normalized = value?.toUpperCase();
    return switch (normalized) {
      'RESERVED' || 'PAID' || 'READY' => OrderStatus.reserved,
      'COMPLETED' || 'PICKED_UP' => OrderStatus.completed,
      'CANCELLED_BY_USER' || 'CANCELLED' => OrderStatus.cancelledByUser,
      'CANCELLED_BY_VENUE' => OrderStatus.cancelledByVenue,
      'NO_SHOW' || 'EXPIRED' => OrderStatus.noShow,
      _ => OrderStatus.reserved,
    };
  }
}

/// Метод расчёта: бронирование с оплатой на месте (офлайн).
enum PaymentMethod {
  onSite('on_site');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod fromApi(String? value) => PaymentMethod.onSite;
}
