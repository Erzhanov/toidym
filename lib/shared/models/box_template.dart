import 'package:flutter/foundation.dart';
import 'package:toidym/shared/models/enums.dart';

/// Шаблон бокса для публикации в 1 клик (BoxTemplate).
@immutable
class BoxTemplate {
  const BoxTemplate({
    required this.id,
    required this.venueId,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.originalPrice,
    required this.discountPercent,
    required this.imageUrl,
    required this.allergens,
    this.isHalal = false,
    this.isVegetarian = false,
  });

  final String id;
  final String venueId;
  final String name;
  final String description;
  final BoxCategory category;
  final BoxType type;
  final int originalPrice;
  final int discountPercent;
  final String imageUrl;
  final List<String> allergens;
  final bool isHalal;
  final bool isVegetarian;

  int get discountPrice =>
      ((originalPrice * (100 - discountPercent)) / 100).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'venue_id': venueId,
        'name': name,
        'description': description,
        'category': category.apiValue,
        'type': type.apiValue,
        'original_price': originalPrice,
        'discount_percent': discountPercent,
        'image_url': imageUrl,
        'allergens': allergens,
        'is_halal': isHalal,
        'is_vegetarian': isVegetarian,
      };
}
