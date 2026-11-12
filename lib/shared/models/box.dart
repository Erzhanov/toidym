import 'package:flutter/foundation.dart';
import 'package:toidym/shared/models/enums.dart';

/// Окно самовывоза бокса.
@immutable
class PickupWindow {
  const PickupWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  String get formatted {
    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');
    return '$sH:$sM–$eH:$eM';
  }

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  factory PickupWindow.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return PickupWindow(
      start: DateTime.tryParse(json['start'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day, 20, 0),
      end: DateTime.tryParse(json['end'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day, 21, 0),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PickupWindow && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

/// Модель бокса (сюрприз-бокс или набор остатков дня).
@immutable
class Box {
  const Box({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercent,
    required this.quantity,
    required this.quantityLeft,
    required this.pickupWindow,
    required this.isHalal,
    required this.allergens,
    required this.status,
    required this.createdAt,
    this.isVegetarian = false,
    this.isResale = false,
    this.photos = const [],
    this.repeatWeekdays = const [],
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final BoxType type;
  final BoxCategory category;
  final int originalPrice;
  final int discountPrice;
  final int discountPercent;
  final int quantity;
  final int quantityLeft;
  final PickupWindow pickupWindow;
  final bool isHalal;
  final bool isVegetarian;
  final bool isResale;
  final List<String> allergens;
  final BoxStatus status;
  final DateTime createdAt;
  final List<String> photos;
  final List<int> repeatWeekdays;

  bool get isAvailable => status == BoxStatus.active && quantityLeft > 0;
  bool get isSoldOut => status == BoxStatus.soldOut || quantityLeft <= 0;
  bool get isExpired => status == BoxStatus.expired;
  bool get isEndingSoon => isAvailable && quantityLeft <= 3;
  bool get isLastMinuteResale => isResale && isAvailable;

  Box copyWith({
    String? id,
    String? venueId,
    String? title,
    String? description,
    BoxType? type,
    BoxCategory? category,
    int? originalPrice,
    int? discountPrice,
    int? discountPercent,
    int? quantity,
    int? quantityLeft,
    PickupWindow? pickupWindow,
    bool? isHalal,
    bool? isVegetarian,
    bool? isResale,
    List<String>? allergens,
    BoxStatus? status,
    DateTime? createdAt,
    List<String>? photos,
    List<int>? repeatWeekdays,
  }) {
    return Box(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      quantity: quantity ?? this.quantity,
      quantityLeft: quantityLeft ?? this.quantityLeft,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      isHalal: isHalal ?? this.isHalal,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isResale: isResale ?? this.isResale,
      allergens: allergens ?? this.allergens,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      photos: photos ?? this.photos,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'title': title,
        'description': description,
        'type': type.apiValue,
        'category': category.apiValue,
        'originalPrice': originalPrice,
        'discountPrice': discountPrice,
        'discountPercent': discountPercent,
        'quantity': quantity,
        'quantityLeft': quantityLeft,
        'pickupWindow': pickupWindow.toJson(),
        'isHalal': isHalal,
        'isVegetarian': isVegetarian,
        'isResale': isResale,
        'allergens': allergens,
        'status': status.apiValue,
        'createdAt': createdAt.toIso8601String(),
        'photos': photos,
        'repeatWeekdays': repeatWeekdays,
      };

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      id: json['id'] as String? ?? '',
      venueId: json['venueId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: BoxType.fromApi(json['type'] as String?),
      category: BoxCategory.fromApi(json['category'] as String?),
      originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      quantityLeft: (json['quantityLeft'] as num?)?.toInt() ?? 0,
      pickupWindow: json['pickupWindow'] is Map<String, dynamic>
          ? PickupWindow.fromJson(
              json['pickupWindow'] as Map<String, dynamic>,
            )
          : PickupWindow(
              start: DateTime.now().add(const Duration(hours: 3)),
              end: DateTime.now().add(const Duration(hours: 4)),
            ),
      isHalal: json['isHalal'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      isResale: (json['isResale'] as bool?) ??
          (json['is_resale'] as bool?) ??
          false,
      allergens: (json['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: BoxStatus.fromApi(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      repeatWeekdays: (json['repeatWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Box &&
        other.id == id &&
        other.venueId == venueId &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.category == category &&
        other.originalPrice == originalPrice &&
        other.discountPrice == discountPrice &&
        other.discountPercent == discountPercent &&
        other.quantity == quantity &&
        other.quantityLeft == quantityLeft &&
        other.pickupWindow == pickupWindow &&
        other.isHalal == isHalal &&
        other.isVegetarian == isVegetarian &&
        other.isResale == isResale &&
        listEquals(other.allergens, allergens) &&
        other.status == status &&
        other.createdAt == createdAt &&
        listEquals(other.photos, photos) &&
        listEquals(other.repeatWeekdays, repeatWeekdays);
  }

  @override
  int get hashCode => Object.hash(
        id,
        venueId,
        title,
        description,
        type,
        category,
        originalPrice,
        discountPrice,
        discountPercent,
        quantity,
        quantityLeft,
        pickupWindow,
        isHalal,
        isVegetarian,
        isResale,
        Object.hashAll(allergens),
        status,
        createdAt,
        Object.hashAll(photos),
        Object.hashAll(repeatWeekdays),
      );
}
