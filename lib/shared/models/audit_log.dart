import 'package:flutter/foundation.dart';

/// Запись аудита критических действий администратора (AuditLogs).
@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String actorEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String details;
  final DateTime createdAt;
}
