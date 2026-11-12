import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/user.dart';

/// Результат успешного входа / регистрации с JWT и флагом первого входа партнёра.
class AuthSessionResult {
  const AuthSessionResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.isFirstLogin,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final bool isFirstLogin;
}

/// Интерфейс репозитория Hybrid RBAC авторизации и дисциплины (3 Strikes).
abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> watchCurrentUser();

  List<User> getAllUsersSnapshot();

  Stream<List<User>> watchAllUsers();

  /// Восстановление сессии при старте из SecureTokenStorage.
  Future<void> restoreSession();

  /// `POST /api/v1/auth/register` (Email + пароль, статус `isVerified: false`).
  Future<User> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  /// `GET /api/v1/auth/verify-email`
  Future<User> verifyEmail(String email);

  /// `POST /api/v1/auth/login` (Email или телефон + пароль, защита от брутфорса 5 попыток -> 15 мин).
  Future<AuthSessionResult> login({
    required String identifier,
    required String password,
  });

  /// Отправка ссылки сброса пароля на Email.
  Future<void> requestPasswordReset(String email);

  /// Мәжбүрлі ауыстыру: смена временного пароля при `isFirstLogin == true`.
  Future<User> changeTemporaryPassword(String newPassword);

  /// Выход из аккаунта (возврат в режим гостя + очистка SecureTokenStorage).
  Future<void> logout();

  /// Внутреннее создание PARTNER-аккаунта после одобрения заявки админом.
  Future<({User user, String temporaryPassword})> provisionPartnerAccount({
    required String venueId,
    required String venueName,
    required String phone,
    required String email,
  });

  Future<User> switchRole(UserRole role);

  Future<User?> updateLanguage(AppLanguage language);

  Future<User?> updateDietaryPreferences(Set<DietaryPreference> preferences);

  Future<User?> recordSavedBoxes({
    required int boxesCount,
    required int savedMoneyTenge,
  });

  /// Начисляет 1 Strike при NO_SHOW; при 3 Strikes блокирует на 30 дней.
  Future<User?> addStrike(String userId);

  /// Админ снимает 1 Strike или полностью разблокирует пользователя.
  Future<User?> removeStrike(String userId);

  Future<User?> unbanUser(String userId);
}
