import 'package:toidym/shared/models/audit_log.dart';

/// Журнал аудита критических действий администратора (AuditLogs).
abstract interface class AuditLogRepository {
  Stream<List<AuditLogEntry>> watchAuditLogs();

  List<AuditLogEntry> getAuditLogsSnapshot();

  Future<AuditLogEntry> recordAction({
    required String actorEmail,
    required String action,
    required String targetType,
    required String targetId,
    required String details,
  });
}
