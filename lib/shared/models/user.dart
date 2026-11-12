import 'package:flutter/foundation.dart';
import 'package:toidym/shared/models/enums.dart';

/// Статистика спасённой еды пользователя.
@immutable
class UserStats {
  const UserStats({
    required this.boxesSaved,
    required this.kgSaved,
    required this.moneySaved,
  });

  const UserStats.empty()
      : boxesSaved = 0,
        kgSaved = 0,
        moneySaved = 0;

  final int boxesSaved;
  final double kgSaved;
  final int moneySaved;

  UserStats copyWith({
    int? boxesSaved,
    double? kgSaved,
    int? moneySaved,
  }) {
    return UserStats(
      boxesSaved: boxesSaved ?? this.boxesSaved,
      kgSaved: kgSaved ?? this.kgSaved,
      moneySaved: moneySaved ?? this.moneySaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'boxesSaved': boxesSaved,
        'kgSaved': kgSaved,
        'moneySaved': moneySaved,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      boxesSaved: (json['boxesSaved'] as num?)?.toInt() ?? 0,
      kgSaved: (json['kgSaved'] as num?)?.toDouble() ?? 0,
      moneySaved: (json['moneySaved'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserStats &&
        other.boxesSaved == boxesSaved &&
        other.kgSaved == kgSaved &&
        other.moneySaved == moneySaved;
  }

  @override
  int get hashCode => Object.hash(boxesSaved, kgSaved, moneySaved);
}

/// Прогресс пользователя в коллекции «Қызыл кітап».
@immutable
class QyzylKitapProgress {
  const QyzylKitapProgress({
    required this.currentAnimal,
    required this.boxesToNext,
  });

  factory QyzylKitapProgress.fromBoxesSaved(int boxesSaved) {
    final current = QyzylKitapAnimal.fromBoxesSaved(boxesSaved);
    final next = current.nextAnimal;
    final toNext = next == null
        ? 0
        : (next.requiredBoxes - boxesSaved).clamp(0, next.requiredBoxes);
    return QyzylKitapProgress(
      currentAnimal: current,
      boxesToNext: toNext,
    );
  }

  final QyzylKitapAnimal currentAnimal;
  final int boxesToNext;

  QyzylKitapProgress copyWith({
    QyzylKitapAnimal? currentAnimal,
    int? boxesToNext,
  }) {
    return QyzylKitapProgress(
      currentAnimal: currentAnimal ?? this.currentAnimal,
      boxesToNext: boxesToNext ?? this.boxesToNext,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentAnimal': currentAnimal.apiValue,
        'boxesToNext': boxesToNext,
      };

  factory QyzylKitapProgress.fromJson(Map<String, dynamic> json) {
    return QyzylKitapProgress(
      currentAnimal: QyzylKitapAnimal.fromApi(json['currentAnimal'] as String?),
      boxesToNext: (json['boxesToNext'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QyzylKitapProgress &&
        other.currentAnimal == currentAnimal &&
        other.boxesToNext == boxesToNext;
  }

  @override
  int get hashCode => Object.hash(currentAnimal, boxesToNext);
}

/// Модель пользователя (USER, PARTNER, CASHIER, ADMIN).
@immutable
class User {
  const User({
    required this.id,
    required this.phone,
    required this.email,
    required this.name,
    required this.role,
    required this.language,
    required this.stats,
    required this.qyzylKitap,
    this.isVerified = true,
    this.isFirstLogin = false,
    this.dietaryPreferences = const {},
    this.strikesCount = 0,
    this.bannedUntil,
    this.managedVenueId,
  });

  final String id;
  final String phone;
  final String email;
  final String name;
  final UserRole role;
  final AppLanguage language;
  final UserStats stats;
  final QyzylKitapProgress qyzylKitap;
  final bool isVerified;
  final bool isFirstLogin;
  final Set<DietaryPreference> dietaryPreferences;
  final int strikesCount;
  final DateTime? bannedUntil;
  final String? managedVenueId;

  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  bool get canAccessVenueMode =>
      role == UserRole.partner ||
      role == UserRole.cashier ||
      role == UserRole.admin;

  bool get canAccessAdminMode => role == UserRole.admin;

  bool get isCashierOnly => role == UserRole.cashier;

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? name,
    UserRole? role,
    AppLanguage? language,
    UserStats? stats,
    QyzylKitapProgress? qyzylKitap,
    bool? isVerified,
    bool? isFirstLogin,
    Set<DietaryPreference>? dietaryPreferences,
    int? strikesCount,
    DateTime? bannedUntil,
    bool clearBan = false,
    String? managedVenueId,
    bool clearManagedVenue = false,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      language: language ?? this.language,
      stats: stats ?? this.stats,
      qyzylKitap: qyzylKitap ?? this.qyzylKitap,
      isVerified: isVerified ?? this.isVerified,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      strikesCount: strikesCount ?? this.strikesCount,
      bannedUntil: clearBan ? null : (bannedUntil ?? this.bannedUntil),
      managedVenueId:
          clearManagedVenue ? null : (managedVenueId ?? this.managedVenueId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'name': name,
        'role': role.apiValue,
        'language': language.code,
        'stats': stats.toJson(),
        'qyzylKitap': qyzylKitap.toJson(),
        'isVerified': isVerified,
        'isFirstLogin': isFirstLogin,
        'dietaryPreferences':
            dietaryPreferences.map((e) => e.apiValue).toList(growable: false),
        'strikesCount': strikesCount,
        'bannedUntil': bannedUntil?.toIso8601String(),
        'managedVenueId': managedVenueId,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: UserRole.fromApi(json['role'] as String?),
      language: AppLanguage.fromCode(json['language'] as String?),
      stats: json['stats'] is Map<String, dynamic>
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats.empty(),
      qyzylKitap: json['qyzylKitap'] is Map<String, dynamic>
          ? QyzylKitapProgress.fromJson(
              json['qyzylKitap'] as Map<String, dynamic>,
            )
          : QyzylKitapProgress.fromBoxesSaved(0),
      isVerified: json['isVerified'] as bool? ?? true,
      isFirstLogin: json['isFirstLogin'] as bool? ?? false,
      dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => DietaryPreference.fromApi(e.toString()))
              .toSet() ??
          const {},
      strikesCount: (json['strikesCount'] as num?)?.toInt() ?? 0,
      bannedUntil: DateTime.tryParse(json['bannedUntil'] as String? ?? ''),
      managedVenueId: json['managedVenueId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is User &&
        other.id == id &&
        other.phone == phone &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.language == language &&
        other.stats == stats &&
        other.qyzylKitap == qyzylKitap &&
        other.isVerified == isVerified &&
        other.isFirstLogin == isFirstLogin &&
        setEquals(other.dietaryPreferences, dietaryPreferences) &&
        other.strikesCount == strikesCount &&
        other.bannedUntil == bannedUntil &&
        other.managedVenueId == managedVenueId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        phone,
        email,
        name,
        role,
        language,
        stats,
        qyzylKitap,
        isVerified,
        isFirstLogin,
        Object.hashAll(dietaryPreferences),
        strikesCount,
        bannedUntil,
        managedVenueId,
      );
}
