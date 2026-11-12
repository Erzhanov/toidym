import 'package:flutter/foundation.dart';

/// Уведомление внутри приложения (колокольчик на главном экране).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.titleRu,
    required this.titleKk,
    required this.bodyRu,
    required this.bodyKk,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String titleRu;
  final String titleKk;
  final String bodyRu;
  final String bodyKk;
  final DateTime createdAt;
  final bool isRead;

  String title(String languageCode) => languageCode == 'kk' ? titleKk : titleRu;
  String body(String languageCode) => languageCode == 'kk' ? bodyKk : bodyRu;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      titleRu: titleRu,
      titleKk: titleKk,
      bodyRu: bodyRu,
      bodyKk: bodyKk,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
