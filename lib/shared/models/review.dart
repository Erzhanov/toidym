import 'package:flutter/foundation.dart';

/// Модель отзыва покупателя на полученный бокс.
@immutable
class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.venueId,
    required this.rating,
    required this.tags,
    required this.comment,
    required this.createdAt,
    this.authorName = 'Покупатель',
  });

  final String id;
  final String orderId;
  final String userId;
  final String venueId;
  final int rating;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;
  final String authorName;

  Review copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? venueId,
    int? rating,
    List<String>? tags,
    String? comment,
    DateTime? createdAt,
    String? authorName,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      venueId: venueId ?? this.venueId,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'venueId': venueId,
        'rating': rating,
        'tags': tags,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'authorName': authorName,
      };

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      venueId: json['venueId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      authorName: json['authorName'] as String? ?? 'Покупатель',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Review &&
        other.id == id &&
        other.orderId == orderId &&
        other.userId == userId &&
        other.venueId == venueId &&
        other.rating == rating &&
        listEquals(other.tags, tags) &&
        other.comment == comment &&
        other.createdAt == createdAt &&
        other.authorName == authorName;
  }

  @override
  int get hashCode => Object.hash(
        id,
        orderId,
        userId,
        venueId,
        rating,
        Object.hashAll(tags),
        comment,
        createdAt,
        authorName,
      );
}
