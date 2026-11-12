import 'dart:async';

import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/audit_log_repository.dart';
import 'package:toidym/shared/models/audit_log.dart';

/// Мок-репозиторий журнала аудита администратора (`AuditLogs`).
class MockAuditLogRepository implements AuditLogRepository {
  MockAuditLogRepository() : _logs = SeedData.createAuditLogs().toList();

  final List<AuditLogEntry> _logs;
  final _controller = StreamController<List<AuditLogEntry>>.broadcast();

  @override
  List<AuditLogEntry> getAuditLogsSnapshot() =>
      List<AuditLogEntry>.unmodifiable(_logs);

  @override
  Stream<List<AuditLogEntry>> watchAuditLogs() async* {
    yield getAuditLogsSnapshot();
    yield* _controller.stream;
  }

  @override
  Future<AuditLogEntry> recordAction({
    required String actorEmail,
    required String action,
    required String targetType,
    required String targetId,
    required String details,
  }) async {
    final entry = AuditLogEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      actorEmail: actorEmail,
      action: action,
      targetType: targetType,
      targetId: targetId,
      details: details,
      createdAt: DateTime.now(),
    );
    _logs.insert(0, entry);
    _controller.add(getAuditLogsSnapshot());
    return entry;
  }
}
