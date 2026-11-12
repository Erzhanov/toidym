import 'dart:async';
import 'dart:math' as math;

import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/user.dart';

/// Коды ошибок авторизации (для локализованного отображения в UI).
enum AuthErrorCode {
  invalidPhone,
  invalidEmail,
  weakPassword,
  emailAlreadyExists,
  invalidCredentials,
  emailNotVerified,
  rateLimited,
  accountBanned,
}

class AuthException implements Exception {
  const AuthException(this.code, {this.details});

  final AuthErrorCode code;
  final String? details;

  @override
  String toString() => 'AuthException(${code.name}${details != null ? ": $details" : ""})';
}

class _UserCredentialRecord {
  _UserCredentialRecord({
    required this.user,
    required this.password,
  });

  User user;
  String password;
}

class _FailedAttemptBucket {
  int count = 0;
  DateTime? lockedUntil;
}

/// Мок-репозиторий Hybrid RBAC авторизации (Email+пароль, 3 Strikes, SecureTokenStorage).
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs, this._tokenStorage) {
    for (final user in SeedData.createInitialUsers()) {
      final password = switch (user.role) {
        UserRole.admin => SeedData.demoAdminPassword,
        UserRole.partner => SeedData.demoPartnerPassword,
        UserRole.cashier => SeedData.demoCashierPassword,
        UserRole.buyer => SeedData.demoUserPassword,
      };
      _records[user.id] = _UserCredentialRecord(user: user, password: password);
    }
  }

  final AppPreferences _prefs;
  final SecureTokenStorage _tokenStorage;
  final _userController = StreamController<User?>.broadcast();
  final _allUsersController = StreamController<List<User>>.broadcast();
  final Map<String, _UserCredentialRecord> _records = {};
  final Map<String, _FailedAttemptBucket> _failedAttempts = {};
  final _rng = math.Random();
  User? _currentUser;

  void _emitCurrent() {
    _userController.add(_currentUser);
  }

  void _emitAll() {
    _allUsersController.add(getAllUsersSnapshot());
  }

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  _UserCredentialRecord? _findByIdentifier(String identifier) {
    final trimmed = identifier.trim().toLowerCase();
    final digits = _normalizePhone(identifier);
    for (final record in _records.values) {
      if (record.user.email.toLowerCase() == trimmed) return record;
      if (digits.length >= 10 &&
          _normalizePhone(record.user.phone) == digits) {
        return record;
      }
    }
    return null;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _userController.stream;
  }

  @override
  List<User> getAllUsersSnapshot() =>
      _records.values.map((r) => r.user).toList(growable: false);

  @override
  Stream<List<User>> watchAllUsers() async* {
    yield getAllUsersSnapshot();
    yield* _allUsersController.stream;
  }

  @override
  Future<void> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    final userId = await _tokenStorage.getSessionUserId();
    if (token == null || token.isEmpty || userId == null) return;
    final rec = _records[userId];
    if (rec != null) {
      _currentUser = rec.user.copyWith(language: _prefs.getLanguage());
      _emitCurrent();
    }
  }

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!AuthValidators.isValidKzPhone(phone)) {
      throw const AuthException(AuthErrorCode.invalidPhone);
    }
    if (!AuthValidators.isValidEmail(email)) {
      throw const AuthException(AuthErrorCode.invalidEmail);
    }
    if (!AuthValidators.isStrongPassword(password)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }
    if (_findByIdentifier(email) != null) {
      throw const AuthException(AuthErrorCode.emailAlreadyExists);
    }

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final user = User(
      id: id,
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
      name: name.trim(),
      role: UserRole.buyer,
      language: _prefs.getLanguage(),
      isVerified: true,
      isFirstLogin: false,
      stats: const UserStats.empty(),
      qyzylKitap: QyzylKitapProgress.fromBoxesSaved(0),
    );
    _records[id] = _UserCredentialRecord(user: user, password: password);
    final now = DateTime.now();
    await _tokenStorage.saveSession(
      accessToken: 'jwt_access_${user.id}_${now.millisecondsSinceEpoch}',
      refreshToken: 'jwt_refresh_${user.id}_${now.millisecondsSinceEpoch}',
      userId: user.id,
    );
    _currentUser = user;
    _emitCurrent();
    _emitAll();
    return user;
  }

  @override
  Future<User> verifyEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final rec = _findByIdentifier(email);
    if (rec == null) {
      throw const AuthException(AuthErrorCode.invalidEmail);
    }
    rec.user = rec.user.copyWith(isVerified: true);
    if (_currentUser?.id == rec.user.id) {
      _currentUser = rec.user;
      _emitCurrent();
    }
    _emitAll();
    return rec.user;
  }

  @override
  Future<AuthSessionResult> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = identifier.trim().toLowerCase();
    final bucket = _failedAttempts.putIfAbsent(key, _FailedAttemptBucket.new);
    final now = DateTime.now();

    if (bucket.lockedUntil != null && bucket.lockedUntil!.isAfter(now)) {
      final mins = bucket.lockedUntil!.difference(now).inMinutes + 1;
      throw AuthException(AuthErrorCode.rateLimited, details: '$mins');
    }

    final rec = _findByIdentifier(identifier);
    if (rec == null || rec.password != password) {
      bucket.count += 1;
      if (bucket.count >= BusinessRulesConfig.maxLoginAttempts) {
        bucket.lockedUntil = now.add(
          const Duration(minutes: BusinessRulesConfig.loginLockoutMinutes),
        );
        bucket.count = 0;
        throw const AuthException(
          AuthErrorCode.rateLimited,
          details: '${BusinessRulesConfig.loginLockoutMinutes}',
        );
      }
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }

    bucket.count = 0;
    bucket.lockedUntil = null;

    final access = 'jwt_access_${rec.user.id}_${now.millisecondsSinceEpoch}';
    final refresh = 'jwt_refresh_${rec.user.id}_${now.millisecondsSinceEpoch}';
    await _tokenStorage.saveSession(
      accessToken: access,
      refreshToken: refresh,
      userId: rec.user.id,
    );

    _currentUser = rec.user.copyWith(language: _prefs.getLanguage());
    _emitCurrent();

    return AuthSessionResult(
      user: _currentUser!,
      accessToken: access,
      refreshToken: refresh,
      isFirstLogin: _currentUser!.isFirstLogin,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!AuthValidators.isValidEmail(email)) {
      throw const AuthException(AuthErrorCode.invalidEmail);
    }
  }

  @override
  Future<User> changeTemporaryPassword(String newPassword) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!AuthValidators.isStrongPassword(newPassword)) {
      throw const AuthException(AuthErrorCode.weakPassword);
    }
    final user = _currentUser;
    if (user == null) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    final rec = _records[user.id];
    if (rec != null) {
      rec.password = newPassword;
      rec.user = rec.user.copyWith(isFirstLogin: false);
      _currentUser = rec.user;
    } else {
      _currentUser = user.copyWith(isFirstLogin: false);
    }
    _emitCurrent();
    _emitAll();
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    await _tokenStorage.clearSession();
    await _prefs.setActiveMode(AppMode.buyer);
    _emitCurrent();
  }

  @override
  Future<({User user, String temporaryPassword})> provisionPartnerAccount({
    required String venueId,
    required String venueName,
    required String phone,
    required String email,
  }) async {
    final code = 100 + _rng.nextInt(899);
    final tempPassword = 'Toidym$code';
    final cleanEmail = email.trim().isEmpty
        ? 'partner_$venueId@toidym.kz'
        : email.trim().toLowerCase();
    final id = 'partner_$venueId';
    final partner = User(
      id: id,
      phone: phone.trim(),
      email: cleanEmail,
      name: '$venueName (Партнёр)',
      role: UserRole.partner,
      language: _prefs.getLanguage(),
      isVerified: true,
      isFirstLogin: true,
      stats: const UserStats.empty(),
      qyzylKitap: QyzylKitapProgress.fromBoxesSaved(0),
      managedVenueId: venueId,
    );
    _records[id] = _UserCredentialRecord(user: partner, password: tempPassword);
    _emitAll();
    return (user: partner, temporaryPassword: tempPassword);
  }

  @override
  Future<User> switchRole(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final targetId = switch (role) {
      UserRole.buyer => SeedData.demoUserId,
      UserRole.partner => SeedData.demoPartnerId,
      UserRole.cashier => SeedData.demoCashierId,
      UserRole.admin => SeedData.demoAdminId,
    };
    final rec = _records[targetId];
    final nextUser = (rec?.user ??
            SeedData.createDemoUser(language: _prefs.getLanguage()))
        .copyWith(language: _prefs.getLanguage());

    final now = DateTime.now().millisecondsSinceEpoch;
    await _tokenStorage.saveSession(
      accessToken: 'jwt_access_${nextUser.id}_$now',
      refreshToken: 'jwt_refresh_${nextUser.id}_$now',
      userId: nextUser.id,
    );
    _currentUser = nextUser;
    _emitCurrent();
    return nextUser;
  }

  @override
  Future<User?> updateLanguage(AppLanguage language) async {
    await _prefs.setLanguage(language);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(language: language);
      final rec = _records[_currentUser!.id];
      if (rec != null) rec.user = _currentUser!;
      _emitCurrent();
    }
    return _currentUser;
  }

  @override
  Future<User?> updateDietaryPreferences(
    Set<DietaryPreference> preferences,
  ) async {
    if (_currentUser == null) return null;
    _currentUser = _currentUser!.copyWith(dietaryPreferences: preferences);
    final rec = _records[_currentUser!.id];
    if (rec != null) rec.user = _currentUser!;
    _emitCurrent();
    _emitAll();
    return _currentUser;
  }

  @override
  Future<User?> recordSavedBoxes({
    required int boxesCount,
    required int savedMoneyTenge,
  }) async {
    final user = _currentUser;
    if (user == null) return null;
    final newBoxesSaved = user.stats.boxesSaved + boxesCount;
    final newKgSaved = double.parse(
      (user.stats.kgSaved + boxesCount * 0.65).toStringAsFixed(1),
    );
    final newMoneySaved = user.stats.moneySaved + savedMoneyTenge;
    final updated = user.copyWith(
      stats: user.stats.copyWith(
        boxesSaved: newBoxesSaved,
        kgSaved: newKgSaved,
        moneySaved: newMoneySaved,
      ),
      qyzylKitap: QyzylKitapProgress.fromBoxesSaved(newBoxesSaved),
    );
    _currentUser = updated;
    final rec = _records[updated.id];
    if (rec != null) rec.user = updated;
    _emitCurrent();
    _emitAll();
    return updated;
  }

  @override
  Future<User?> addStrike(String userId) async {
    final rec = _records[userId];
    if (rec == null) return null;
    final nextStrikes = rec.user.strikesCount + 1;
    final banUntil = nextStrikes >= BusinessRulesConfig.maxStrikesBeforeBan
        ? DateTime.now().add(
            const Duration(days: BusinessRulesConfig.strikeBanDurationDays),
          )
        : rec.user.bannedUntil;
    rec.user = rec.user.copyWith(
      strikesCount: nextStrikes,
      bannedUntil: banUntil,
    );
    if (_currentUser?.id == userId) {
      _currentUser = rec.user;
      _emitCurrent();
    }
    _emitAll();
    return rec.user;
  }

  @override
  Future<User?> removeStrike(String userId) async {
    final rec = _records[userId];
    if (rec == null) return null;
    final nextStrikes = (rec.user.strikesCount - 1).clamp(0, 99);
    rec.user = rec.user.copyWith(
      strikesCount: nextStrikes,
      clearBan: nextStrikes < BusinessRulesConfig.maxStrikesBeforeBan,
    );
    if (_currentUser?.id == userId) {
      _currentUser = rec.user;
      _emitCurrent();
    }
    _emitAll();
    return rec.user;
  }

  @override
  Future<User?> unbanUser(String userId) async {
    final rec = _records[userId];
    if (rec == null) return null;
    rec.user = rec.user.copyWith(
      strikesCount: 0,
      clearBan: true,
    );
    if (_currentUser?.id == userId) {
      _currentUser = rec.user;
      _emitCurrent();
    }
    _emitAll();
    return rec.user;
  }
}
