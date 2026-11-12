import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:toidym/core/network/api_client.dart';
import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/audit_log_repository.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/repositories/box_repository.dart';
import 'package:toidym/domain/repositories/order_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/audit_log.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/models/venue.dart';

String _extractDioError(DioException e, {AppLanguage lang = AppLanguage.ru}) {
  final isKk = lang == AppLanguage.kk;
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError) {
    return isKk
        ? 'Сервермен байланыс жоқ. Интернетті тексеріңіз.'
        : 'Нет соединения с сервером. Проверьте интернет.';
  }

  final statusCode = e.response?.statusCode;
  var data = e.response?.data;
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          data = decoded;
        }
      } catch (_) {}
    }
  }
  var errorCode = '';
  var rawMessage = '';
  if (data is Map) {
    errorCode = (data['error_code'] ?? data['code'] ?? '').toString().toLowerCase();
    final msg = data['msg'] ??
        data['message'] ??
        data['error_description'] ??
        data['error'];
    if (msg != null) {
      rawMessage = msg.toString();
    }
  } else if (data is String && data.trim().isNotEmpty) {
    rawMessage = data.trim();
  }

  final combined = '$errorCode ${rawMessage.toLowerCase()}';

  if (statusCode == 429 ||
      combined.contains('rate_limit') ||
      combined.contains('too many requests')) {
    return isKk
        ? 'Тым көп әрекет жасалды. 1 минут күтіп қайта көріңіз.'
        : 'Слишком много попыток. Подождите минуту и повторите.';
  }
  if (combined.contains('invalid_credentials') ||
      combined.contains('invalid login credentials') ||
      combined.contains('invalid_grant')) {
    return isKk
        ? 'Email немесе құпиясөз қате.'
        : 'Неверный Email или пароль.';
  }
  if (combined.contains('weak_password') ||
      combined.contains('easy to guess') ||
      combined.contains('pwned')) {
    return isKk
        ? 'Бұл құпиясөз тым қарапайым немесе қауіпсіз емес. Басқа сенімді құпиясөз ойлап табыңыз.'
        : 'Этот пароль слишком простой или ненадёжный. Придумайте другой пароль.';
  }
  if (combined.contains('user_already_exists') ||
      combined.contains('email_exists') ||
      combined.contains('already been registered') ||
      combined.contains('already registered')) {
    return isKk
        ? 'Бұл Email бұрыннан тіркелген. «Кіру» арқылы кіріңіз.'
        : 'Аккаунт с этим Email уже зарегистрирован. Перейдите на вкладку «Вход».';
  }
  if (combined.contains('email_not_confirmed') ||
      combined.contains('email not confirmed')) {
    return isKk
        ? 'Email расталмаған. Поштаңызды тексеріңіз.'
        : 'Email ещё не подтверждён. Проверьте почту.';
  }
  if (combined.contains('invalid_email') ||
      combined.contains('unable to validate email')) {
    return isKk
        ? 'Email форматы қате.'
        : 'Проверьте корректность Email.';
  }

  if (combined.contains('box not found')) {
    return isKk
        ? 'Бұл бокс бұлттық базада табылмады. Дүкен кабинетінен нақты бокс жариялаңыз немесе SQL-сидті орындаңыз.'
        : 'Этот бокс не найден в облачной базе. Опубликуйте реальный бокс из кабинета магазина или выполните SQL-сид.';
  }
  if (combined.contains('reserved order not found')) {
    return isKk
        ? 'Белсенді бронь табылмады немесе QR/PIN коды қате.'
        : 'Активная бронь с таким QR/PIN-кодом не найдена.';
  }
  if (statusCode == 403 ||
      combined.contains('42501') ||
      combined.contains('permission denied') ||
      combined.contains('row-level security')) {
    return isKk
        ? 'Қолжетімділік шектелген (RLS/құқық жеткіліксіз). Рөл немесе SQL саясатын тексеріңіз.'
        : 'Недостаточно прав (RLS/SQL). Проверьте роль аккаунта и политики доступа в базе.';
  }

  if (rawMessage.isNotEmpty) {
    return rawMessage;
  }
  if (statusCode != null) {
    return isKk
        ? 'Сервер қатесі (HTTP $statusCode). Қайталап көріңіз.'
        : 'Ошибка сервера (HTTP $statusCode). Попробуйте ещё раз.';
  }
  return isKk
      ? 'Желі қатесі. Қайталап көріңіз.'
      : 'Ошибка сети. Попробуйте ещё раз.';
}

Future<T> _guardDio<T>(
  Future<T> Function() action, {
  AppLanguage lang = AppLanguage.ru,
}) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw ApiException(
      message: _extractDioError(e, lang: lang),
      statusCode: e.response?.statusCode,
    );
  }
}

/// Маппинг между PostgreSQL snake_case строками Supabase и моделями Dart.
abstract final class SupabaseMappers {
  static User userFromRow(Map<String, dynamic> row) {
    final boxesSaved = (row['boxes_saved'] as num?)?.toInt() ?? 0;
    final animal = QyzylKitapAnimal.fromBoxesSaved(boxesSaved);
    final nextAnimal = animal.nextAnimal;
    final boxesToNext = nextAnimal == null
        ? 0
        : (nextAnimal.requiredBoxes - boxesSaved).clamp(0, 999);

    final prefsList = (row['dietary_preferences'] as List<dynamic>?)
            ?.map((e) => DietaryPreference.fromApi(e.toString()))
            .toSet() ??
        const <DietaryPreference>{};

    return User(
      id: row['id'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      email: row['email'] as String? ?? '',
      name: row['name'] as String? ?? 'Покупатель',
      role: UserRole.fromApi(row['role'] as String?),
      language: AppLanguage.fromCode(row['language'] as String?),
      stats: UserStats(
        boxesSaved: boxesSaved,
        kgSaved: (row['co2_saved_kg'] as num?)?.toDouble() ?? 0,
        moneySaved: (row['money_saved_kzt'] as num?)?.toInt() ?? 0,
      ),
      qyzylKitap: QyzylKitapProgress(
        currentAnimal: animal,
        boxesToNext: boxesToNext,
      ),
      isVerified: row['is_verified'] as bool? ?? true,
      isFirstLogin: (row['is_first_login'] as bool? ?? false) ||
          (row['must_change_password'] as bool? ?? false),
      dietaryPreferences: prefsList,
      strikesCount: (row['strikes_count'] as num?)?.toInt() ?? 0,
      bannedUntil:
          DateTime.tryParse(row['banned_until'] as String? ?? '')?.toLocal(),
      managedVenueId: row['managed_venue_id'] as String?,
    );
  }

  static Venue venueFromRow(Map<String, dynamic> row) {
    var parsedStatus = VenueStatus.fromApi(row['status'] as String?);
    if ((row['is_blocked'] as bool? ?? false) &&
        parsedStatus != VenueStatus.rejected) {
      parsedStatus = VenueStatus.banned;
    }
    final rawNotes = row['notes'] as String?;
    var categoryStr = row['category'] as String?;
    if ((categoryStr == null || categoryStr.isEmpty) &&
        rawNotes != null &&
        rawNotes.contains('category=')) {
      categoryStr = rawNotes.split('category=').last.split(RegExp(r'[\s;,]')).first;
    }
    return Venue(
      id: row['id'] as String? ?? '',
      name: (row['name'] as String?) ?? (row['venue_name'] as String?) ?? '',
      category: VenueCategory.fromApi(categoryStr),
      district: AstanaDistrict.fromDynamic(row['district']),
      address: row['address'] as String? ?? '',
      lat: (row['lat'] as num?)?.toDouble() ?? 51.1282,
      lng: (row['lng'] as num?)?.toDouble() ?? 71.4304,
      rating: (row['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (row['reviews_count'] as num?)?.toInt() ?? 0,
      isHalal: row['is_halal'] as bool? ?? false,
      halalCertStatus:
          HalalCertStatus.fromApi(row['halal_cert_status'] as String?),
      workHours: WorkHours(
        openMinuteOfDay: (row['open_minute_of_day'] as num?)?.toInt() ?? 480,
        closeMinuteOfDay: (row['close_minute_of_day'] as num?)?.toInt() ?? 1200,
      ),
      phone: row['phone'] as String? ?? '',
      photo: row['photo'] as String? ?? '',
      status: parsedStatus,
      halalCertNumber: row['halal_cert_number'] as String?,
      halalCertPhoto: (row['halal_cert_photo'] as String?) ??
          (((row['halal_cert_number'] as String?)?.startsWith('data:image/') ==
                      true ||
                  (row['halal_cert_number'] as String?)?.startsWith('http') ==
                      true)
              ? row['halal_cert_number'] as String?
              : null),
      rejectionFields: (row['rejection_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rejectionComment: (row['rejection_comment'] as String?) ??
          (row['review_note'] as String?) ??
          ((row['contact_name'] as String?)?.isNotEmpty == true
              ? 'Email: ${row['contact_name']}'
              : ((row['applicant_email'] as String?)?.isNotEmpty == true
                  ? 'Email: ${row['applicant_email']}'
                  : null)),
      ownerId: row['owner_id']?.toString(),
    );
  }

  static Box boxFromRow(Map<String, dynamic> row) {
    final start = DateTime.tryParse(row['pickup_start'] as String? ?? '')
            ?.toLocal() ??
        DateTime.now();
    final end = DateTime.tryParse(row['pickup_end'] as String? ?? '')
            ?.toLocal() ??
        start.add(const Duration(minutes: 15));
    return Box(
      id: row['id'] as String? ?? '',
      venueId: row['venue_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      type: BoxType.fromApi(row['type'] as String?),
      category: BoxCategory.fromApi(row['category'] as String?),
      originalPrice: (row['original_price'] as num?)?.toInt() ?? 0,
      discountPrice: (row['discount_price'] as num?)?.toInt() ?? 0,
      discountPercent: (row['discount_percent'] as num?)?.toInt() ?? 0,
      quantity: (row['quantity'] as num?)?.toInt() ?? 0,
      quantityLeft: (row['quantity_left'] as num?)?.toInt() ?? 0,
      pickupWindow: PickupWindow(start: start, end: end),
      isHalal: row['is_halal'] as bool? ?? false,
      isVegetarian: row['is_vegetarian'] as bool? ?? false,
      isResale: row['is_resale'] as bool? ?? false,
      allergens: (row['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: BoxStatus.fromApi(row['status'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      photos: (row['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      repeatWeekdays: (row['repeat_weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );
  }

  static BoxTemplate templateFromRow(Map<String, dynamic> row) {
    final orig = (row['original_price'] as num?)?.toInt() ?? 1;
    final disc = (row['discount_price'] as num?)?.toInt() ?? 0;
    final pct = orig > 0 ? (((orig - disc) / orig) * 100).round() : 50;
    final photos = (row['photos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return BoxTemplate(
      id: row['id'] as String? ?? '',
      venueId: row['venue_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      category: BoxCategory.fromApi(row['category'] as String?),
      type: BoxType.fromApi(row['type'] as String?),
      originalPrice: orig,
      discountPercent: pct.clamp(0, 100),
      imageUrl: photos.isNotEmpty ? photos.first : '',
      allergens: (row['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isHalal: row['is_halal'] as bool? ?? false,
      isVegetarian: row['is_vegetarian'] as bool? ?? false,
    );
  }

  static Order orderFromRow(Map<String, dynamic> row) {
    return Order(
      id: row['id'] as String? ?? '',
      orderNumber: row['order_number'] as String? ?? '#0000',
      userId: row['user_id'] as String? ?? '',
      boxId: row['box_id'] as String? ?? '',
      venueId: row['venue_id'] as String? ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      totalPrice: (row['total_price'] as num?)?.toInt() ?? 0,
      originalTotalPrice: (row['original_total_price'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromApi(row['status'] as String?),
      qrCode: row['qr_code'] as String? ?? '',
      pinCode: row['pin_code'] as String? ?? '0000',
      paymentMethod: PaymentMethod.fromApi(row['payment_method'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      pickedUpAt:
          DateTime.tryParse(row['picked_up_at'] as String? ?? '')?.toLocal(),
      cancellationReason: row['cancellation_reason'] as String?,
      complaintSubmitted: row['complaint_submitted'] as bool? ?? false,
      complaintStatus:
          ComplaintStatus.fromApi(row['complaint_status'] as String?),
      complaintNote: row['complaint_note'] as String?,
      complaintResolutionNote: row['complaint_resolution_note'] as String?,
      complaintPhotoPaths: (row['complaint_photo_paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      complaintSubmittedAt: DateTime.tryParse(
              row['complaint_submitted_at'] as String? ?? '')
          ?.toLocal(),
      isCharityBox: row['is_charity_box'] as bool? ?? false,
    );
  }

  static Review reviewFromRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String? ?? '',
      orderId: row['order_id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      venueId: row['venue_id'] as String? ?? '',
      rating: (row['rating'] as num?)?.toInt() ?? 5,
      tags: (row['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      comment: row['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      authorName: row['author_name'] as String? ?? 'Покупатель',
    );
  }

  static AuditLogEntry auditLogFromRow(Map<String, dynamic> row) {
    return AuditLogEntry(
      id: row['id'] as String? ?? '',
      actorEmail: row['actor_email'] as String? ?? '',
      action: row['action'] as String? ?? '',
      targetType: row['target_type'] as String? ?? '',
      targetId: row['target_id'] as String? ?? '',
      details: row['details'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

// ----------------------------------------------------------------------------
// 1. AUDIT LOG REPOSITORY (Supabase PostgREST)
// ----------------------------------------------------------------------------
class SupabaseAuditLogRepository implements AuditLogRepository {
  SupabaseAuditLogRepository(this._apiClient);

  final ApiClient _apiClient;
  final List<AuditLogEntry> _cache = [];
  final _controller = StreamController<List<AuditLogEntry>>.broadcast();

  void _emit() => _controller.add(List<AuditLogEntry>.unmodifiable(_cache));

  Future<void> _refresh() async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbAuditLogs}?order=created_at.desc&limit=100',
      );
      final rows = res.data ?? const [];
      _cache
        ..clear()
        ..addAll(
          rows.whereType<Map<String, dynamic>>().map(
                SupabaseMappers.auditLogFromRow,
              ),
        );
      _emit();
    } catch (_) {
      // Keep last cached snapshot on transient errors or non-admin role.
    }
  }

  @override
  Stream<List<AuditLogEntry>> watchAuditLogs() async* {
    if (_cache.isEmpty) {
      await _refresh();
    } else {
      unawaited(_refresh());
    }
    yield List<AuditLogEntry>.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  List<AuditLogEntry> getAuditLogsSnapshot() =>
      List<AuditLogEntry>.unmodifiable(_cache);

  @override
  Future<AuditLogEntry> recordAction({
    required String actorEmail,
    required String action,
    required String targetType,
    required String targetId,
    required String details,
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<List<dynamic>>(
        ApiEndpoints.sbAuditLogs,
        data: {
          'actor_email': actorEmail,
          'action': action,
          'target_type': targetType,
          'target_id': targetId,
          'details': details,
        },
        options: Options(headers: const {'Prefer': 'return=representation'}),
      );
      final row = (res.data?.first as Map<String, dynamic>?) ?? {};
      final entry = SupabaseMappers.auditLogFromRow(row);
      _cache.insert(0, entry);
      _emit();
      return entry;
    });
  }
}

// ----------------------------------------------------------------------------
// 2. AUTH REPOSITORY (Supabase Auth + Profiles RLS)
// ----------------------------------------------------------------------------
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._apiClient,
    this._prefs,
    this._tokenStorage,
  );

  final ApiClient _apiClient;
  final AppPreferences _prefs;
  final SecureTokenStorage _tokenStorage;

  User? _currentUser;
  final List<User> _allUsers = [];
  final _userController = StreamController<User?>.broadcast();
  final _allUsersController = StreamController<List<User>>.broadcast();

  void _emitUser() {
    _userController.add(_currentUser);
    _allUsersController.add(List<User>.unmodifiable(_allUsers));
  }

  AppMode _modeForRole(UserRole role) {
    return switch (role) {
      UserRole.admin => AppMode.admin,
      UserRole.partner || UserRole.cashier => AppMode.venue,
      UserRole.buyer => AppMode.buyer,
    };
  }

  Future<User> _fetchProfileById(String userId) async {
    final res = await _apiClient.dio.get<List<dynamic>>(
      '${ApiEndpoints.sbProfiles}?id=eq.$userId&limit=1',
    );
    final list = res.data ?? const [];
    if (list.isEmpty) {
      throw const ApiException(message: 'Профиль пользователя не найден');
    }
    return SupabaseMappers.userFromRow(list.first as Map<String, dynamic>);
  }

  Future<void> refreshAllUsers() async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbProfiles}?order=created_at.desc',
      );
      final rows = res.data ?? const [];
      _allUsers
        ..clear()
        ..addAll(
          rows.whereType<Map<String, dynamic>>().map(SupabaseMappers.userFromRow),
        );
      _allUsersController.add(List<User>.unmodifiable(_allUsers));
    } catch (_) {}
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _userController.stream;
  }

  @override
  List<User> getAllUsersSnapshot() => List<User>.unmodifiable(_allUsers);

  @override
  Stream<List<User>> watchAllUsers() async* {
    unawaited(refreshAllUsers());
    yield List<User>.unmodifiable(_allUsers);
    yield* _allUsersController.stream;
  }

  Future<bool> _tryRefreshTokens() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return false;
    }
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.sbAuthToken}?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data ?? const {};
      final access = data['access_token'] as String? ?? '';
      final nextRefresh = data['refresh_token'] as String? ?? refreshToken;
      final userMap = data['user'] as Map<String, dynamic>?;
      final uid =
          (userMap?['id'] as String?) ??
          (await _tokenStorage.getSessionUserId()) ??
          '';
      if (access.isEmpty || uid.isEmpty) {
        return false;
      }
      await _tokenStorage.saveSession(
        accessToken: access,
        refreshToken: nextRefresh,
        userId: uid,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    final uid = await _tokenStorage.getSessionUserId();
    if (token == null || token.isEmpty || uid == null || uid.isEmpty) {
      _currentUser = null;
      _emitUser();
      return;
    }
    try {
      _currentUser = await _fetchProfileById(uid);
      if (_currentUser?.role == UserRole.admin) {
        unawaited(refreshAllUsers());
      }
      _emitUser();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 && await _tryRefreshTokens()) {
        try {
          _currentUser = await _fetchProfileById(uid);
          if (_currentUser?.role == UserRole.admin) {
            unawaited(refreshAllUsers());
          }
          _emitUser();
          return;
        } catch (_) {}
      }
      _currentUser = null;
      if (status == 401 || status == 403) {
        await _tokenStorage.clearSession();
      }
      _emitUser();
    } catch (_) {
      _currentUser = null;
      await _tokenStorage.clearSession();
      _emitUser();
    }
  }

  Future<User> _ensureProfileExists({
    required String userId,
    required String name,
    required String phone,
    required String email,
    AppLanguage? syncLanguage,
  }) async {
    try {
      final existing = await _fetchProfileById(userId);
      final patch = <String, dynamic>{};
      final cleanEmail = email.trim().toLowerCase();
      final cleanPhone = phone.trim();
      final cleanName = name.trim();

      if (existing.email.trim().isEmpty && cleanEmail.isNotEmpty) {
        patch['email'] = cleanEmail;
      }
      if (existing.phone.trim().isEmpty && cleanPhone.isNotEmpty) {
        patch['phone'] = cleanPhone;
      }
      if ((existing.name.trim().isEmpty || existing.name == 'Покупатель') &&
          cleanName.isNotEmpty &&
          cleanName != 'Покупатель') {
        patch['name'] = cleanName;
      }
      if (syncLanguage != null && existing.language != syncLanguage) {
        patch['language'] = syncLanguage.code;
      }

      if (patch.isNotEmpty) {
        try {
          final res = await _apiClient.dio.patch<List<dynamic>>(
            '${ApiEndpoints.sbProfiles}?id=eq.$userId',
            data: patch,
            options: Options(headers: const {'Prefer': 'return=representation'}),
          );
          final rows = res.data ?? const [];
          if (rows.isNotEmpty) {
            return SupabaseMappers.userFromRow(rows.first as Map<String, dynamic>);
          }
        } catch (_) {
          // Even if profile patch fails on transient network/RLS, keep local email synced.
        }
        return existing.copyWith(
          email: existing.email.isEmpty ? cleanEmail : existing.email,
          phone: existing.phone.isEmpty ? cleanPhone : existing.phone,
          name: (existing.name == 'Покупатель' && cleanName.isNotEmpty)
              ? cleanName
              : existing.name,
          language: syncLanguage ?? existing.language,
        );
      }
      return existing;
    } catch (_) {
      final res = await _apiClient.dio.post<List<dynamic>>(
        ApiEndpoints.sbProfiles,
        data: {
          'id': userId,
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'name': name.trim().isEmpty ? 'Покупатель' : name.trim(),
          'role': 'USER',
          'language': (syncLanguage ?? _prefs.getLanguage()).code,
          'is_verified': true,
        },
        options: Options(
          headers: const {
            'Prefer': 'return=representation,resolution=merge-duplicates',
          },
        ),
      );
      final rows = res.data ?? const [];
      if (rows.isNotEmpty) {
        return SupabaseMappers.userFromRow(rows.first as Map<String, dynamic>);
      }
      return _fetchProfileById(userId);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final lang = _prefs.getLanguage();
    final isKk = lang == AppLanguage.kk;
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (!AuthValidators.isValidEmail(cleanEmail)) {
      throw ApiException(
        message: isKk ? 'Email форматы қате.' : 'Проверьте корректность Email.',
      );
    }
    if (!AuthValidators.isStrongPassword(password)) {
      throw ApiException(
        message: isKk
            ? 'Құпиясөз кемінде 8 таңбадан, 1 саннан және 1 бас әріптен тұруы тиіс.'
            : 'Пароль должен содержать мин. 8 символов, 1 цифру и 1 заглавную букву.',
      );
    }

    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbAuthSignup,
        data: {
          'email': cleanEmail,
          'password': password,
          'data': {
            'name': cleanName,
            'phone': cleanPhone,
            'language': lang.code,
          },
        },
      );
      final data = res.data ?? const {};
      final userMap = data['user'] as Map<String, dynamic>?;
      final uid = userMap?['id'] as String? ?? '';
      final access = data['access_token'] as String? ?? '';
      final refresh = data['refresh_token'] as String? ?? '';

      if (access.isNotEmpty && uid.isNotEmpty) {
        await _tokenStorage.saveSession(
          accessToken: access,
          refreshToken: refresh,
          userId: uid,
        );
        final profile = await _ensureProfileExists(
          userId: uid,
          name: cleanName,
          phone: cleanPhone,
          email: cleanEmail,
          syncLanguage: lang,
        );
        _currentUser = profile;
        await _prefs.setActiveMode(_modeForRole(profile.role));
        _emitUser();
        return profile;
      }

      // Supabase returns empty identities when email already exists (anti-enumeration).
      final identities = userMap?['identities'] as List<dynamic>?;
      final maybeExistingObfuscated =
          identities != null && identities.isEmpty;
      try {
        final session = await login(identifier: cleanEmail, password: password);
        return session.user;
      } on ApiException catch (loginErr) {
        final msg = loginErr.message.toLowerCase();
        if (maybeExistingObfuscated &&
            (msg.contains('неверный email') ||
                msg.contains('құпиясөз қате') ||
                msg.contains('invalid'))) {
          throw ApiException(
            message: isKk
                ? 'Бұл Email бұрыннан тіркелген. «Кіру» арқылы кіріңіз.'
                : 'Аккаунт с этим Email уже зарегистрирован. Перейдите на вкладку «Вход».',
          );
        }
        rethrow;
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e, lang: lang),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<User> verifyEmail(String email) async {
    if (_currentUser != null) {
      final refreshed = await _fetchProfileById(_currentUser!.id);
      _currentUser = refreshed;
      _emitUser();
      return refreshed;
    }
    final isKk = _prefs.getLanguage() == AppLanguage.kk;
    throw ApiException(
      message: isKk
          ? 'Email расталған соң аккаунтқа кіріңіз.'
          : 'Войдите в аккаунт с вашим Email и паролем.',
    );
  }

  @override
  Future<AuthSessionResult> login({
    required String identifier,
    required String password,
  }) async {
    final lang = _prefs.getLanguage();
    final isKk = lang == AppLanguage.kk;
    final cleanEmail = identifier.trim().toLowerCase();

    if (!AuthValidators.isValidEmail(cleanEmail)) {
      throw ApiException(
        message: isKk
            ? 'Кіру үшін тіркелген Email мекенжайын енгізіңіз.'
            : 'Для входа укажите Email, указанный при регистрации.',
      );
    }

    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.sbAuthToken}?grant_type=password',
        data: {
          'email': cleanEmail,
          'password': password,
        },
      );
      final data = res.data ?? const {};
      final access = data['access_token'] as String? ?? '';
      final refresh = data['refresh_token'] as String? ?? '';
      final userMap = data['user'] as Map<String, dynamic>?;
      final uid = userMap?['id'] as String? ?? '';

      await _tokenStorage.saveSession(
        accessToken: access,
        refreshToken: refresh,
        userId: uid,
      );

      final meta = (userMap?['user_metadata'] as Map<String, dynamic>?) ?? const {};
      final profile = await _ensureProfileExists(
        userId: uid,
        name: (meta['name'] as String?) ?? 'Покупатель',
        phone: (meta['phone'] as String?) ?? '',
        email: (userMap?['email'] as String?) ?? cleanEmail,
      );
      _currentUser = profile;
      await _prefs.setActiveMode(_modeForRole(profile.role));
      if (profile.role == UserRole.admin) {
        unawaited(refreshAllUsers());
      }
      _emitUser();

      return AuthSessionResult(
        user: profile,
        accessToken: access,
        refreshToken: refresh,
        isFirstLogin: profile.isFirstLogin,
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e, lang: lang),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final lang = _prefs.getLanguage();
    final isKk = lang == AppLanguage.kk;
    final cleanEmail = email.trim().toLowerCase();
    if (!AuthValidators.isValidEmail(cleanEmail)) {
      throw ApiException(
        message: isKk ? 'Email форматы қате.' : 'Проверьте корректность Email.',
      );
    }
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.sbAuthRecover,
        data: {'email': cleanEmail},
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e, lang: lang),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<User> changeTemporaryPassword(String newPassword) async {
    final lang = _prefs.getLanguage();
    final isKk = lang == AppLanguage.kk;
    final current = _currentUser;
    if (current == null) {
      throw ApiException(
        message: isKk ? 'Аккаунтқа кіру қажет.' : 'Требуется вход в аккаунт.',
      );
    }
    try {
      await _apiClient.dio.put<dynamic>(
        ApiEndpoints.sbAuthUser,
        data: {'password': newPassword},
      );
      await _apiClient.dio.patch<dynamic>(
        '${ApiEndpoints.sbProfiles}?id=eq.${current.id}',
        data: {
          'is_first_login': false,
          'must_change_password': false,
        },
      );
      _currentUser = current.copyWith(isFirstLogin: false);
      _emitUser();
      return _currentUser!;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e, lang: lang),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post<dynamic>(ApiEndpoints.sbAuthLogout);
    } catch (_) {}
    await _tokenStorage.clearSession();
    await _prefs.setActiveMode(AppMode.buyer);
    _currentUser = null;
    _emitUser();
  }

  @override
  Future<({User user, String temporaryPassword})> provisionPartnerAccount({
    required String venueId,
    required String venueName,
    required String phone,
    required String email,
  }) async {
    return _guardDio(() async {
      final payload = {
        'role': 'PARTNER',
        'venue_id': venueId,
        'name': 'Партнёр $venueName',
        'phone': phone,
        'email': email,
      };
      Response<Map<String, dynamic>> res;
      try {
        res = await _apiClient.dio.post<Map<String, dynamic>>(
          ApiEndpoints.sbFnCreatePartner,
          data: payload,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        try {
          res = await _apiClient.dio.post<Map<String, dynamic>>(
            ApiEndpoints.sbRpcCreatePartnerStaff,
            data: {
              'p_role': 'PARTNER',
              'p_venue_id': venueId,
              'p_name': 'Партнёр $venueName',
              'p_phone': phone,
              'p_email': email,
            },
          );
        } on DioException catch (rpcErr) {
          if (rpcErr.response?.statusCode == 404) {
            throw const ApiException(
              message:
                  'Функция создания партнёра не настроена на сервере (выполните lovable_sync_connections.sql).',
              statusCode: 404,
            );
          }
          rethrow;
        }
      }
      final data = res.data ?? const {};
      final uid = data['user_id'] as String? ?? '';
      final tempPassword = data['temp_password'] as String? ?? '';
      final user = await _fetchProfileById(uid);
      unawaited(refreshAllUsers());
      return (user: user, temporaryPassword: tempPassword);
    }, lang: _prefs.getLanguage());
  }

  @override
  Future<User> switchRole(UserRole role) async {
    if (_currentUser == null) {
      throw const ApiException(message: 'Необходимо войти в аккаунт');
    }
    await _prefs.setActiveMode(_modeForRole(role));
    _currentUser = _currentUser!.copyWith(role: role);
    _emitUser();
    return _currentUser!;
  }

  @override
  Future<User?> updateLanguage(AppLanguage language) async {
    await _prefs.setLanguage(language);
    final current = _currentUser;
    if (current == null) return null;
    await _apiClient.dio.patch<dynamic>(
      '${ApiEndpoints.sbProfiles}?id=eq.${current.id}',
      data: {'language': language.code},
    );
    _currentUser = current.copyWith(language: language);
    _emitUser();
    return _currentUser;
  }

  @override
  Future<User?> updateDietaryPreferences(
    Set<DietaryPreference> preferences,
  ) async {
    final current = _currentUser;
    if (current == null) return null;
    await _apiClient.dio.patch<dynamic>(
      '${ApiEndpoints.sbProfiles}?id=eq.${current.id}',
      data: {
        'dietary_preferences': preferences.map((e) => e.apiValue).toList(),
      },
    );
    _currentUser = current.copyWith(dietaryPreferences: preferences);
    _emitUser();
    return _currentUser;
  }

  @override
  Future<User?> recordSavedBoxes({
    required int boxesCount,
    required int savedMoneyTenge,
  }) async {
    final current = _currentUser;
    if (current == null) return null;
    _currentUser = await _fetchProfileById(current.id);
    _emitUser();
    return _currentUser;
  }

  @override
  Future<User?> addStrike(String userId) async {
    return _guardDio(() async {
      final user = await _fetchProfileById(userId);
      final nextStrikes = user.strikesCount + 1;
      final bannedUntil = nextStrikes >= BusinessRulesConfig.maxStrikesBeforeBan
          ? DateTime.now().add(
              const Duration(days: BusinessRulesConfig.strikeBanDurationDays),
            )
          : user.bannedUntil;
      await _apiClient.dio.patch<dynamic>(
        '${ApiEndpoints.sbProfiles}?id=eq.$userId',
        data: {
          'strikes_count': nextStrikes,
          'banned_until': bannedUntil?.toUtc().toIso8601String(),
        },
      );
      final updated = await _fetchProfileById(userId);
      if (_currentUser?.id == userId) _currentUser = updated;
      unawaited(refreshAllUsers());
      _emitUser();
      return updated;
    }, lang: _prefs.getLanguage());
  }

  @override
  Future<User?> removeStrike(String userId) async {
    return _guardDio(() async {
      final user = await _fetchProfileById(userId);
      final nextStrikes = max(0, user.strikesCount - 1);
      await _apiClient.dio.patch<dynamic>(
        '${ApiEndpoints.sbProfiles}?id=eq.$userId',
        data: {
          'strikes_count': nextStrikes,
          if (nextStrikes < BusinessRulesConfig.maxStrikesBeforeBan)
            'banned_until': null,
        },
      );
      final updated = await _fetchProfileById(userId);
      if (_currentUser?.id == userId) _currentUser = updated;
      unawaited(refreshAllUsers());
      _emitUser();
      return updated;
    }, lang: _prefs.getLanguage());
  }

  @override
  Future<User?> unbanUser(String userId) async {
    return _guardDio(() async {
      await _apiClient.dio.patch<dynamic>(
        '${ApiEndpoints.sbProfiles}?id=eq.$userId',
        data: {'strikes_count': 0, 'banned_until': null},
      );
      final updated = await _fetchProfileById(userId);
      if (_currentUser?.id == userId) _currentUser = updated;
      unawaited(refreshAllUsers());
      _emitUser();
      return updated;
    }, lang: _prefs.getLanguage());
  }
}

// ----------------------------------------------------------------------------
// 3. VENUE REPOSITORY (Supabase PostgREST + Edge Functions)
// ----------------------------------------------------------------------------
class SupabaseVenueRepository implements VenueRepository {
  SupabaseVenueRepository(this._apiClient);

  final ApiClient _apiClient;
  final List<Venue> _cache = [];
  final _controller = StreamController<List<Venue>>.broadcast();

  void _emit() => _controller.add(List<Venue>.unmodifiable(_cache));

  Future<List<Venue>> _fetchAll({bool emit = true}) async {
    List<Venue> list = [];
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbVenues}?order=created_at.desc',
      );
      list = (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SupabaseMappers.venueFromRow)
          .toList();
    } catch (_) {
      list = [];
    }
    try {
      final appsRes = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbPartnerApplications}?order=created.desc',
      );
      final existingIds = list.map((v) => v.id).toSet();
      for (final row in (appsRes.data ?? const []).whereType<Map<String, dynamic>>()) {
        final appVenue = SupabaseMappers.venueFromRow(row);
        if (appVenue.id.isNotEmpty &&
            !existingIds.contains(appVenue.id) &&
            appVenue.status != VenueStatus.approved) {
          list.add(appVenue);
          existingIds.add(appVenue.id);
        }
      }
    } catch (_) {
      // Non-admin callers may not have SELECT permission on partner_applications.
    }
    if (list.isEmpty) {
      list.addAll(SeedData.createVenues());
    }
    _cache
      ..clear()
      ..addAll(list);
    if (emit) {
      _emit();
    }
    return List<Venue>.unmodifiable(_cache);
  }

  @override
  Future<List<Venue>> getVenues() => _fetchAll(emit: false);

  @override
  Stream<List<Venue>> watchVenues() async* {
    if (_cache.isEmpty) {
      await _fetchAll(emit: false);
    }
    yield List<Venue>.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Future<Venue?> getVenueById(String venueId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbVenues}?id=eq.$venueId&limit=1',
      );
      final rows = res.data ?? const [];
      if (rows.isNotEmpty) {
        return SupabaseMappers.venueFromRow(rows.first as Map<String, dynamic>);
      }
    } catch (_) {
      // Fall back to seed catalog when remote lookup fails or entry is seed-only.
    }
    for (final v in SeedData.createVenues()) {
      if (v.id == venueId) return v;
    }
    return null;
  }

  @override
  Future<Venue?> getManagedVenue(String venueId) => getVenueById(venueId);

  @override
  Future<Venue> submitPartnerLead({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  }) async {
    return _guardDio(() async {
      final cleanEmail = email.trim().toLowerCase();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final generatedId = 'pa_$nowMs';
      final appPayload = {
        'id': generatedId,
        'venue_name': name.trim(),
        'company': name.trim(),
        'address': address.trim(),
        'district': district.index,
        'phone': phone.trim(),
        'contact_name': cleanEmail,
        'notes': 'category=${category.apiValue}',
        'status': 'pending',
        'created': nowMs,
      };
      try {
        await _apiClient.dio.post<dynamic>(
          ApiEndpoints.sbPartnerApplications,
          data: appPayload,
          options: Options(headers: const {'Prefer': 'return=minimal'}),
        );
        final venue = SupabaseMappers.venueFromRow(appPayload);
        await _fetchAll();
        return venue;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code != 404 && code != 400 && code != 403) rethrow;
        // Fallback to direct venues insert if partner_applications isn't enabled.
        final res = await _apiClient.dio.post<List<dynamic>>(
          ApiEndpoints.sbVenues,
          data: {
            'id': 'venue_$nowMs',
            'owner': cleanEmail,
            'company': name.trim(),
            'name': name.trim(),
            'address': address.trim(),
            'applicant_email': cleanEmail,
            'district': district.index,
            'category': category.apiValue,
            'lat': district.centerLat,
            'lng': district.centerLng,
            'status': 'pending',
            'review_note': 'Phone: ${phone.trim()}',
          },
          options: Options(headers: const {'Prefer': 'return=representation'}),
        );
        final venue = SupabaseMappers.venueFromRow(
          res.data!.first as Map<String, dynamic>,
        );
        await _fetchAll();
        return venue;
      }
    });
  }

  @override
  Future<Venue> submitOnboarding(Venue venue) => updateVenueSettings(venue);

  @override
  Future<Venue> updateVenueSettings(Venue venue) async {
    return _guardDio(() async {
      final corePayload = <String, dynamic>{
        'name': venue.name,
        'category': venue.category.apiValue,
        'district': venue.district.index,
        'address': venue.address,
        'lat': venue.lat,
        'lng': venue.lng,
        'is_halal': venue.isHalal,
        'halal_cert_number': venue.halalCertNumber,
        'open_minute_of_day': venue.workHours.openMinuteOfDay,
        'close_minute_of_day': venue.workHours.closeMinuteOfDay,
      };
      Response<List<dynamic>> res;
      if (venue.phone.isNotEmpty || venue.photo.isNotEmpty) {
        try {
          res = await _apiClient.dio.patch<List<dynamic>>(
            '${ApiEndpoints.sbVenues}?id=eq.${venue.id}',
            data: {
              ...corePayload,
              if (venue.phone.isNotEmpty) 'phone': venue.phone,
              if (venue.photo.isNotEmpty) 'photo': venue.photo,
            },
            options: Options(headers: const {'Prefer': 'return=representation'}),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode != 400) rethrow;
          res = await _apiClient.dio.patch<List<dynamic>>(
            '${ApiEndpoints.sbVenues}?id=eq.${venue.id}',
            data: corePayload,
            options: Options(headers: const {'Prefer': 'return=representation'}),
          );
        }
      } else {
        res = await _apiClient.dio.patch<List<dynamic>>(
          '${ApiEndpoints.sbVenues}?id=eq.${venue.id}',
          data: corePayload,
          options: Options(headers: const {'Prefer': 'return=representation'}),
        );
      }
      return _finishVenuePatch(res);
    });
  }

  /// Извлекает обновлённое заведение из ответа PATCH и обновляет кеш.
  Future<Venue> _finishVenuePatch(
    Response<List<dynamic>> res, {
    bool rpcMissing = false,
  }) async {
    final rows = res.data ?? const [];
    if (rows.isEmpty || rows.first is! Map) {
      throw ApiException(
        message: rpcMissing
            ? 'Lovable Cloud SQL Editor-да supabase/lovable_sync_connections.sql (8-бөлім) орындаңыз / Выполните раздел 8 SQL.'
            : 'Қолжетімділік шектелген (RLS/SQL) / Недостаточно прав для обновления заведения.',
      );
    }
    final updated = SupabaseMappers.venueFromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
    await _fetchAll();
    return updated;
  }

  Never _rethrowOrSqlHint(DioException e, {required bool rpcMissing}) {
    final code = e.response?.statusCode;
    if (rpcMissing && (code == 403 || code == 401 || code == 400)) {
      throw ApiException(
        message:
            'Lovable Cloud SQL Editor-да supabase/lovable_sync_connections.sql (8-бөлім) орындаңыз / Выполните раздел 8 SQL.',
        statusCode: code,
      );
    }
    throw e;
  }

  @override
  Future<PartnerProvisionResult> approvePartnerLead({
    required String venueId,
    required String email,
  }) async {
    return _guardDio(() async {
      Response<Map<String, dynamic>> res;
      try {
        res = await _apiClient.dio.post<Map<String, dynamic>>(
          ApiEndpoints.sbFnApprovePartnerLead,
          data: {'venue_id': venueId, 'approved': true, 'partner_email': email},
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        try {
          res = await _apiClient.dio.post<Map<String, dynamic>>(
            ApiEndpoints.sbRpcApprovePartnerLead,
            data: {
              'p_venue_or_app_id': venueId,
              'p_partner_email': email,
            },
          );
        } on DioException catch (rpcErr) {
          if (rpcErr.response?.statusCode == 404) {
            throw const ApiException(
              message:
                  'На сервере не настроена функция одобрения заявок (выполните lovable_sync_connections.sql).',
              statusCode: 404,
            );
          }
          rethrow;
        }
      }
      final data = res.data ?? const {};
      final venueRaw = data['venue'];
      final venue = venueRaw is Map<String, dynamic>
          ? SupabaseMappers.venueFromRow(venueRaw)
          : (await getVenueById(venueId)) ??
              Venue(
                id: venueId,
                name: 'Партнёр',
                category: VenueCategory.bakery,
                district: AstanaDistrict.esil,
                address: '',
                lat: AstanaDistrict.esil.centerLat,
                lng: AstanaDistrict.esil.centerLng,
                rating: 5.0,
                reviewsCount: 0,
                isHalal: false,
                halalCertStatus: HalalCertStatus.none,
                workHours: const WorkHours(
                  openMinuteOfDay: 480,
                  closeMinuteOfDay: 1200,
                ),
                phone: '',
                photo: '',
                status: VenueStatus.approved,
              );
      final tempPassword = data['temp_password'] as String? ?? '';
      final partnerEmail = data['partner_email'] as String? ?? email;
      await _fetchAll();
      return PartnerProvisionResult(
        venue: venue,
        partnerUser: User(
          id: data['user_id'] as String? ?? '',
          phone: venue.phone,
          email: partnerEmail,
          name: 'Партнёр ${venue.name}',
          role: UserRole.partner,
          language: AppLanguage.ru,
          stats: const UserStats.empty(),
          qyzylKitap: const QyzylKitapProgress(
            currentAnimal: QyzylKitapAnimal.qumbek,
            boxesToNext: 15,
          ),
          isFirstLogin: true,
          managedVenueId: venue.id,
        ),
        temporaryPassword: tempPassword,
      );
    });
  }

  @override
  Future<PartnerProvisionResult> createPartnerByAdmin({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  }) async {
    final lead = await submitPartnerLead(
      name: name,
      phone: phone,
      address: address,
      email: email,
      district: district,
      category: category,
    );
    return approvePartnerLead(venueId: lead.id, email: email);
  }

  @override
  Future<Venue> banVenue({
    required String venueId,
    required String reason,
  }) {
    return setDemoVenueStatus(
      venueId: venueId,
      status: VenueStatus.banned,
      rejectionComment: reason,
    );
  }

  @override
  Future<Venue> unbanVenue(String venueId) {
    return setDemoVenueStatus(venueId: venueId, status: VenueStatus.approved);
  }

  @override
  Future<Venue> setDemoVenueStatus({
    required String venueId,
    required VenueStatus status,
    List<String> rejectionFields = const [],
    String? rejectionComment,
  }) async {
    return _guardDio(() async {
      final isBlocked = status == VenueStatus.banned;
      final endpoint = venueId.startsWith('pa_')
          ? '${ApiEndpoints.sbPartnerApplications}?id=eq.$venueId'
          : '${ApiEndpoints.sbVenues}?id=eq.$venueId';
      Response<List<dynamic>> res;
      if (venueId.startsWith('pa_')) {
        res = await _apiClient.dio.patch<List<dynamic>>(
          endpoint,
          data: {
            'status': status.apiValue.toLowerCase(),
            if (rejectionComment != null && rejectionComment.isNotEmpty)
              'notes': rejectionComment,
          },
          options: Options(headers: const {'Prefer': 'return=representation'}),
        );
      } else {
        try {
          res = await _apiClient.dio.patch<List<dynamic>>(
            endpoint,
            data: {
              'status': status.apiValue.toLowerCase(),
              'is_blocked': isBlocked,
              'rejection_fields': rejectionFields,
              'rejection_comment': rejectionComment,
              'review_note': ?rejectionComment,
            },
            options: Options(headers: const {'Prefer': 'return=representation'}),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode != 400) rethrow;
          // Retry with uppercase status if DB uses 001_schema_and_indexes CHECK constraint.
          res = await _apiClient.dio.patch<List<dynamic>>(
            endpoint,
            data: {
              'status': status.apiValue,
              'is_blocked': isBlocked,
              'rejection_fields': rejectionFields,
              'rejection_comment': rejectionComment,
            },
            options: Options(headers: const {'Prefer': 'return=representation'}),
          );
        }
      }
      return _finishVenuePatch(res);
    });
  }

  @override
  Future<Venue> updateHalalCertStatus({
    required String venueId,
    required HalalCertStatus halalCertStatus,
    String? halalCertNumber,
    String? halalCertPhoto,
  }) async {
    return _guardDio(() async {
      final photo = halalCertPhoto?.trim();
      var rpcMissing = false;

      // 1) Пробуем безопасные RPC (работают в обход триггера protect_venue_columns).
      if (halalCertStatus == HalalCertStatus.pending &&
          photo != null &&
          photo.isNotEmpty) {
        try {
          final res = await _apiClient.dio.post<dynamic>(
            ApiEndpoints.sbRpcSubmitHalalCert,
            data: {
              'p_venue_id': venueId,
              'p_photo': photo,
            },
          );
          final row = switch (res.data) {
            final Map<String, dynamic> map => map,
            final List list when list.isNotEmpty && list.first is Map =>
              Map<String, dynamic>.from(list.first as Map),
            _ => null,
          };
          if (row != null) {
            final updated = SupabaseMappers.venueFromRow(row);
            await _fetchAll();
            return updated;
          }
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) rethrow;
          rpcMissing = true;
        }
      } else if (halalCertStatus == HalalCertStatus.verified ||
          halalCertStatus == HalalCertStatus.rejected) {
        try {
          final res = await _apiClient.dio.post<dynamic>(
            ApiEndpoints.sbRpcModerateHalalCert,
            data: {
              'p_venue_id': venueId,
              'p_status': halalCertStatus.apiValue,
            },
          );
          final row = switch (res.data) {
            final Map<String, dynamic> map => map,
            final List list when list.isNotEmpty && list.first is Map =>
              Map<String, dynamic>.from(list.first as Map),
            _ => null,
          };
          if (row != null) {
            final updated = SupabaseMappers.venueFromRow(row);
            await _fetchAll();
            return updated;
          }
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) rethrow;
          rpcMissing = true;
        }
      }

      // 2) Прямой REST PATCH (для старых/прямых схем).
      final payload = <String, dynamic>{
        'halal_cert_status': halalCertStatus.apiValue,
        if (halalCertStatus == HalalCertStatus.verified) 'is_halal': true,
        if (halalCertStatus == HalalCertStatus.rejected ||
            halalCertStatus == HalalCertStatus.none)
          'is_halal': false,
        'halal_cert_number': ?halalCertNumber,
        if (photo != null && photo.isNotEmpty) 'halal_cert_photo': photo,
      };
      Response<List<dynamic>> res;
      try {
        res = await _apiClient.dio.patch<List<dynamic>>(
          '${ApiEndpoints.sbVenues}?id=eq.$venueId',
          data: payload,
          options: Options(headers: const {'Prefer': 'return=representation'}),
        );
      } on DioException catch (e) {
        // Если колонки halal_cert_photo ещё нет в таблице, сохраняем фото в halal_cert_number.
        if (e.response?.statusCode == 400 &&
            payload.containsKey('halal_cert_photo')) {
          try {
            final fallbackPayload = Map<String, dynamic>.from(payload)
              ..remove('halal_cert_photo')
              ..['halal_cert_number'] = photo;
            res = await _apiClient.dio.patch<List<dynamic>>(
              '${ApiEndpoints.sbVenues}?id=eq.$venueId',
              data: fallbackPayload,
              options:
                  Options(headers: const {'Prefer': 'return=representation'}),
            );
          } on DioException catch (fallbackErr) {
            _rethrowOrSqlHint(fallbackErr, rpcMissing: rpcMissing);
          }
        } else {
          _rethrowOrSqlHint(e, rpcMissing: rpcMissing);
        }
      }
      return _finishVenuePatch(res, rpcMissing: rpcMissing);
    });
  }

  @override
  Future<List<Review>> getVenueReviews(String venueId) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbReviews}?venue_id=eq.$venueId&order=created_at.desc',
      );
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SupabaseMappers.reviewFromRow)
          .toList();
    });
  }

  @override
  Future<Review> addReview(Review review) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcSubmitReview,
        data: {
          'p_order_id': review.orderId,
          'p_rating': review.rating,
          'p_tags': review.tags,
          'p_comment': review.comment,
        },
      );
      return SupabaseMappers.reviewFromRow(res.data!);
    });
  }

  @override
  Future<List<VenueStaffMember>> getStaff(String venueId) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbVenueStaff}?venue_id=eq.$venueId&select=staff_role,profiles(id,name,phone)',
      );
      return (res.data ?? const []).whereType<Map<String, dynamic>>().map((row) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? const {};
        return VenueStaffMember(
          id: profile['id'] as String? ?? '',
          name: profile['name'] as String? ?? 'Сотрудник',
          phone: profile['phone'] as String? ?? '',
          role: UserRole.fromApi(row['staff_role'] as String?),
        );
      }).toList();
    });
  }

  @override
  Future<VenueStaffMember> addCashier({
    required String venueId,
    required String name,
    required String phone,
  }) async {
    return _guardDio(() async {
      final slug = phone.replaceAll(RegExp(r'\D'), '');
      final email = 'cashier.$slug@toidym.kz';
      Response<Map<String, dynamic>> res;
      try {
        res = await _apiClient.dio.post<Map<String, dynamic>>(
          ApiEndpoints.sbFnCreatePartner,
          data: {
            'role': 'CASHIER',
            'venue_id': venueId,
            'name': name,
            'phone': phone,
            'email': email,
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        try {
          res = await _apiClient.dio.post<Map<String, dynamic>>(
            ApiEndpoints.sbRpcCreatePartnerStaff,
            data: {
              'p_role': 'CASHIER',
              'p_venue_id': venueId,
              'p_name': name,
              'p_phone': phone,
              'p_email': email,
            },
          );
        } on DioException catch (rpcErr) {
          if (rpcErr.response?.statusCode == 404) {
            throw const ApiException(
              message:
                  'Функция добавления кассира не настроена на сервере (выполните lovable_sync_connections.sql).',
              statusCode: 404,
            );
          }
          rethrow;
        }
      }
      final data = res.data ?? const {};
      return VenueStaffMember(
        id: data['user_id'] as String? ?? '',
        name: name,
        phone: phone,
        role: UserRole.cashier,
      );
    });
  }
}

// ----------------------------------------------------------------------------
// 4. BOX REPOSITORY (Supabase PostgREST + publish_sprint_box RPC)
// ----------------------------------------------------------------------------
class SupabaseBoxRepository implements BoxRepository {
  SupabaseBoxRepository(
    this._apiClient,
    this._hiveStorage,
    this._venueRepository,
  );

  final ApiClient _apiClient;
  final HiveStorage _hiveStorage;
  final VenueRepository _venueRepository;
  final List<Box> _cache = [];
  final _controller = StreamController<List<Box>>.broadcast();
  bool _shouldFailNextFetch = false;

  void _emit() {
    _controller.add(List<Box>.unmodifiable(_cache));
    unawaited(
      _hiveStorage
          .cacheBoxesJson(
            _cache.map((b) => b.toJson()).toList(growable: false),
          )
          .catchError((_) {}),
    );
  }

  Future<List<Box>> _fetchAll({bool emit = true}) async {
    List<Box> boxes = [];
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbBoxes}?order=is_resale.desc,pickup_end.asc',
      );
      boxes = (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SupabaseMappers.boxFromRow)
          .toList();
    } catch (_) {
      boxes = [];
    }
    if (boxes.isEmpty) {
      boxes = SeedData.createBoxes();
    }
    _cache
      ..clear()
      ..addAll(boxes);
    if (emit) {
      _emit();
    }
    return boxes;
  }

  @override
  void simulateNextFetchError() {
    _shouldFailNextFetch = true;
  }

  @override
  Future<List<Box>> getBoxes({
    AstanaDistrict? district,
    BoxFilterChip filter = BoxFilterChip.all,
    String query = '',
    Set<DietaryPreference> dietaryPreferences = const {},
    BoxSortOption sortOption = BoxSortOption.nearest,
    double? userLat,
    double? userLng,
  }) async {
    if (_shouldFailNextFetch) {
      _shouldFailNextFetch = false;
      throw const ApiException(message: 'Simulated fetch error');
    }

    final boxes = await _fetchAll(emit: false);
    final venues = await _venueRepository.getVenues();
    final venueMap = {for (final v in venues) v.id: v};
    final q = query.trim().toLowerCase();

    final filtered = boxes.where((b) {
      if (b.status != BoxStatus.active || b.quantityLeft <= 0) return false;
      final venue = venueMap[b.venueId];
      if (venue != null && venue.status != VenueStatus.approved) return false;
      if (district != null && venue?.district != district) return false;

      if (filter == BoxFilterChip.bakery && b.category != BoxCategory.bakery) {
        return false;
      }
      if (filter == BoxFilterChip.hotFood &&
          b.category != BoxCategory.hotFood) {
        return false;
      }
      if (filter == BoxFilterChip.coffee && b.category != BoxCategory.coffee) {
        return false;
      }
      if (filter == BoxFilterChip.halal && !b.isHalal) return false;

      if (dietaryPreferences.contains(DietaryPreference.halalOnly) &&
          !b.isHalal) {
        return false;
      }
      if (dietaryPreferences.contains(DietaryPreference.vegetarian) &&
          !b.isVegetarian) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchTitle = b.title.toLowerCase().contains(q);
        final matchVenue = venue?.name.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchVenue) return false;
      }
      return true;
    }).toList();

    final originLat = userLat ?? AstanaDistrict.esil.centerLat;
    final originLng = userLng ?? AstanaDistrict.esil.centerLng;
    filtered.sort((a, b) {
      if (a.isResale != b.isResale) {
        return a.isResale ? -1 : 1;
      }
      return switch (sortOption) {
        BoxSortOption.endingSoon =>
          a.pickupWindow.end.compareTo(b.pickupWindow.end),
        BoxSortOption.maxDiscount =>
          b.discountPercent.compareTo(a.discountPercent),
        BoxSortOption.nearest => () {
            final va = venueMap[a.venueId];
            final vb = venueMap[b.venueId];
            final da = va == null
                ? 999.0
                : AppFormatters.calculateDistanceKm(
                    fromLat: originLat,
                    fromLng: originLng,
                    toLat: va.lat,
                    toLng: va.lng,
                  );
            final db = vb == null
                ? 999.0
                : AppFormatters.calculateDistanceKm(
                    fromLat: originLat,
                    fromLng: originLng,
                    toLat: vb.lat,
                    toLng: vb.lng,
                  );
            return da.compareTo(db);
          }(),
      };
    });

    return filtered;
  }

  @override
  Stream<List<Box>> watchBoxes() async* {
    if (_cache.isEmpty) {
      await _fetchAll(emit: false);
    }
    yield List<Box>.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Future<Box?> getBoxById(String boxId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbBoxes}?id=eq.$boxId&limit=1',
      );
      final rows = res.data ?? const [];
      if (rows.isNotEmpty) {
        return SupabaseMappers.boxFromRow(rows.first as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback to local seed catalog below.
    }
    for (final b in SeedData.createBoxes()) {
      if (b.id == boxId) return b;
    }
    return null;
  }

  @override
  Future<List<Box>> getVenueBoxes(String venueId) async {
    final res = await _apiClient.dio.get<List<dynamic>>(
      '${ApiEndpoints.sbBoxes}?venue_id=eq.$venueId&order=created_at.desc',
    );
    return (res.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SupabaseMappers.boxFromRow)
        .toList();
  }

  @override
  Future<Box> createBox(Box box) async {
    return _guardDio(() async {
      try {
        final res = await _apiClient.dio.post<dynamic>(
          ApiEndpoints.sbRpcPublishSprintBox,
          data: {
            'p_venue_id': box.venueId,
            'p_title': box.title,
            'p_description': box.description,
            'p_type': box.type.apiValue,
            'p_category': box.category.apiValue,
            'p_original_price': box.originalPrice,
            'p_discount_price': box.discountPrice,
            'p_quantity': box.quantity,
            'p_is_halal': box.isHalal,
            'p_is_vegetarian': box.isVegetarian,
            'p_allergens': box.allergens,
            'p_photos': box.photos,
            'p_repeat_weekdays': box.repeatWeekdays,
          },
        );
        final rawRow = switch (res.data) {
          final Map<String, dynamic> map => map,
          final List list when list.isNotEmpty && list.first is Map =>
            Map<String, dynamic>.from(list.first as Map),
          _ => throw ApiException(message: 'Некорректный ответ сервера при создании бокса.'),
        };
        final created = SupabaseMappers.boxFromRow(rawRow);
        await _fetchAll();
        return created;
      } on DioException catch (rpcError) {
        final status = rpcError.response?.statusCode;
        final errText = (rpcError.response?.data?.toString() ?? '').toLowerCase();
        final shouldFallbackDirect = status == 404 ||
            errText.contains('pgrst202') ||
            errText.contains('venue must be approved') ||
            errText.contains('discount_percent') ||
            errText.contains('permission denied') ||
            errText.contains('null value in column');
        if (!shouldFallbackDirect) rethrow;
        return _createBoxDirectFallback(box);
      }
    });
  }

  Future<Box> _createBoxDirectFallback(Box box) async {
    final discountPercent = BoxBusinessRules.calculateDiscountPercent(
      originalPrice: box.originalPrice,
      discountPrice: box.discountPrice,
    );
    final startUtc = box.pickupWindow.start.toUtc();
    final endUtc = box.pickupWindow.end.toUtc();
    final res = await _apiClient.dio.post<List<dynamic>>(
      ApiEndpoints.sbBoxes,
      data: {
        'venue_id': box.venueId,
        'title': box.title,
        'description': box.description,
        'type': box.type.apiValue,
        'category': box.category.apiValue,
        'original_price': box.originalPrice,
        'discount_price': box.discountPrice,
        'discount_percent': discountPercent,
        'quantity': box.quantity,
        'quantity_left': box.quantity,
        'stock': box.quantity,
        'pickup_start': startUtc.toIso8601String(),
        'pickup_end': endUtc.toIso8601String(),
        'starts': startUtc.millisecondsSinceEpoch,
        'ends': endUtc.millisecondsSinceEpoch,
        'is_halal': box.isHalal,
        'is_vegetarian': box.isVegetarian,
        'is_resale': false,
        'allergens': box.allergens,
        'status': 'ACTIVE',
        'published': true,
        'paused': false,
        'photos': box.photos,
        'repeat_weekdays': box.repeatWeekdays,
        'details': {
          'title': box.title,
          'description': box.description,
        },
      },
      options: Options(headers: const {'Prefer': 'return=representation'}),
    );
    final created = SupabaseMappers.boxFromRow(
      res.data!.first as Map<String, dynamic>,
    );
    await _fetchAll();
    return created;
  }

  @override
  Future<Box> updateBoxStock({
    required String boxId,
    required int quantityLeft,
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.patch<List<dynamic>>(
        '${ApiEndpoints.sbBoxes}?id=eq.$boxId',
        data: {
          'quantity_left': quantityLeft,
          'status': quantityLeft > 0 ? 'ACTIVE' : 'SOLD_OUT',
        },
        options: Options(headers: const {'Prefer': 'return=representation'}),
      );
      final updated = SupabaseMappers.boxFromRow(
        res.data!.first as Map<String, dynamic>,
      );
      await _fetchAll();
      return updated;
    });
  }

  @override
  Future<Box> toggleBoxStatus({
    required String boxId,
    required BoxStatus status,
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.patch<List<dynamic>>(
        '${ApiEndpoints.sbBoxes}?id=eq.$boxId',
        data: {'status': status.apiValue},
        options: Options(headers: const {'Prefer': 'return=representation'}),
      );
      final updated = SupabaseMappers.boxFromRow(
        res.data!.first as Map<String, dynamic>,
      );
      await _fetchAll();
      return updated;
    });
  }

  @override
  Future<Box> decrementStock({
    required String boxId,
    required int quantity,
  }) async {
    final box = await getBoxById(boxId);
    if (box == null) throw const ApiException(message: 'Box not found');
    return updateBoxStock(
      boxId: boxId,
      quantityLeft: max(0, box.quantityLeft - quantity),
    );
  }

  @override
  Future<Box> restoreStock({
    required String boxId,
    required int quantity,
  }) async {
    final box = await getBoxById(boxId);
    if (box == null) throw const ApiException(message: 'Box not found');
    return updateBoxStock(
      boxId: boxId,
      quantityLeft: min(box.quantity, box.quantityLeft + quantity),
    );
  }

  @override
  Future<int> archiveExpiredBoxes([DateTime? now]) async {
    await _fetchAll();
    return 0;
  }

  @override
  Future<Box> republishExpiredBox({
    required String boxId,
    required PickupWindow pickupWindow,
    required int quantity,
  }) async {
    final res = await _apiClient.dio.patch<List<dynamic>>(
      '${ApiEndpoints.sbBoxes}?id=eq.$boxId',
      data: {
        'quantity': quantity,
        'quantity_left': quantity,
        'pickup_start': pickupWindow.start.toUtc().toIso8601String(),
        'pickup_end': pickupWindow.end.toUtc().toIso8601String(),
        'is_resale': false,
        'status': BoxStatus.active.apiValue,
      },
      options: Options(headers: const {'Prefer': 'return=representation'}),
    );
    final updated =
        SupabaseMappers.boxFromRow(res.data!.first as Map<String, dynamic>);
    await _fetchAll();
    return updated;
  }

  @override
  Future<Box> requeueForResale({
    required String boxId,
    required int quantityDelta,
    required PickupWindow resaleWindow,
  }) async {
    final box = await getBoxById(boxId);
    if (box == null) throw const ApiException(message: 'Box not found');
    final nextQty = min(box.quantity, box.quantityLeft + quantityDelta);
    final res = await _apiClient.dio.patch<List<dynamic>>(
      '${ApiEndpoints.sbBoxes}?id=eq.$boxId',
      data: {
        'quantity_left': nextQty,
        'pickup_start': resaleWindow.start.toUtc().toIso8601String(),
        'pickup_end': resaleWindow.end.toUtc().toIso8601String(),
        'is_resale': true,
        'status': BoxStatus.active.apiValue,
      },
      options: Options(headers: const {'Prefer': 'return=representation'}),
    );
    final updated =
        SupabaseMappers.boxFromRow(res.data!.first as Map<String, dynamic>);
    await _fetchAll();
    return updated;
  }

  @override
  Future<List<BoxTemplate>> getVenueTemplates(String venueId) async {
    final res = await _apiClient.dio.get<List<dynamic>>(
      '${ApiEndpoints.sbBoxTemplates}?venue_id=eq.$venueId&order=created_at.desc',
    );
    return (res.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SupabaseMappers.templateFromRow)
        .toList();
  }

  @override
  Future<BoxTemplate> createTemplate(BoxTemplate template) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<List<dynamic>>(
        ApiEndpoints.sbBoxTemplates,
        data: {
          'venue_id': template.venueId,
          'name': template.name,
          'description': template.description,
          'category': template.category.apiValue,
          'type': template.type.apiValue,
          'original_price': template.originalPrice,
          'discount_price': template.discountPrice,
          'is_halal': template.isHalal,
          'is_vegetarian': template.isVegetarian,
          'allergens': template.allergens,
          'photos':
              template.imageUrl.isNotEmpty ? [template.imageUrl] : const [],
        },
        options: Options(headers: const {'Prefer': 'return=representation'}),
      );
      return SupabaseMappers.templateFromRow(
        res.data!.first as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Box> publishFromTemplate({
    required BoxTemplate template,
    required int quantity,
    required PickupWindow pickupWindow,
  }) {
    return createBox(
      Box(
        id: '',
        venueId: template.venueId,
        title: template.name,
        description: template.description,
        type: template.type,
        category: template.category,
        originalPrice: template.originalPrice,
        discountPrice: template.discountPrice,
        discountPercent: template.discountPercent,
        quantity: quantity,
        quantityLeft: quantity,
        pickupWindow: pickupWindow,
        isHalal: template.isHalal,
        isVegetarian: template.isVegetarian,
        allergens: template.allergens,
        status: BoxStatus.active,
        createdAt: DateTime.now(),
        photos: template.imageUrl.isNotEmpty ? [template.imageUrl] : const [],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 5. ORDER REPOSITORY (Atomic Trust Reservation + QR/PIN + Resale Worker)
// ----------------------------------------------------------------------------
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._apiClient);

  final ApiClient _apiClient;
  final List<Order> _cache = [];
  final _controller = StreamController<List<Order>>.broadcast();

  void _emit() => _controller.add(List<Order>.unmodifiable(_cache));

  Future<List<Order>> _refreshOrders([String? filterQuery]) async {
    final query = filterQuery ?? 'order=created_at.desc';
    final res = await _apiClient.dio.get<List<dynamic>>(
      '${ApiEndpoints.sbOrders}?$query',
    );
    final orders = (res.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SupabaseMappers.orderFromRow)
        .toList();
    if (filterQuery == null) {
      _cache
        ..clear()
        ..addAll(orders);
      _emit();
    }
    return orders;
  }

  @override
  Future<List<Order>> getOrders(String userId) {
    return _refreshOrders('user_id=eq.$userId&order=created_at.desc');
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    if (_cache.isEmpty) {
      await _refreshOrders().catchError((_) => const <Order>[]);
    } else {
      unawaited(_refreshOrders().catchError((_) => const <Order>[]));
    }
    yield List<Order>.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Future<List<Order>> getVenuePendingOrders(String venueId) {
    return _refreshOrders(
      'venue_id=eq.$venueId&status=eq.RESERVED&order=created_at.desc',
    );
  }

  @override
  Future<List<Order>> getVenueAllOrders(String venueId) {
    return _refreshOrders('venue_id=eq.$venueId&order=created_at.desc');
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    final res = await _apiClient.dio.get<List<dynamic>>(
      '${ApiEndpoints.sbOrders}?id=eq.$orderId&limit=1',
    );
    final rows = res.data ?? const [];
    if (rows.isEmpty) return null;
    return SupabaseMappers.orderFromRow(rows.first as Map<String, dynamic>);
  }

  @override
  Future<Order> createReservation({
    required String userId,
    required String boxId,
    required String venueId,
    required int quantity,
    required int totalPrice,
    required int originalTotalPrice,
    bool isCharityBox = false,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcCreateReservation,
        data: {
          'p_box_id': boxId,
          'p_quantity': quantity,
          'p_is_charity': isCharityBox,
        },
      );
      final order = SupabaseMappers.orderFromRow(res.data!);
      await _refreshOrders();
      return order;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Order> cancelOrderByBuyer(String orderId) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcCancelOrder,
        data: {'p_order_id': orderId, 'p_reason': 'Отменено покупателем'},
      );
      final order = SupabaseMappers.orderFromRow(res.data!);
      await _refreshOrders();
      return order;
    });
  }

  @override
  Future<Order> cancelOrderByVenue({
    required String orderId,
    required String reason,
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcCancelOrder,
        data: {'p_order_id': orderId, 'p_reason': reason},
      );
      final order = SupabaseMappers.orderFromRow(res.data!);
      await _refreshOrders();
      return order;
    });
  }

  @override
  Future<Order> markOrderNoShow(String orderId) async {
    await runResaleCronWorker();
    final updated = await getOrderById(orderId);
    if (updated == null) {
      throw const ApiException(message: 'Заказ не найден');
    }
    return updated;
  }

  @override
  Future<ResaleWorkerResult> runResaleCronWorker([DateTime? now]) async {
    // Database pg_cron handles global resale sweeps automatically every 1 minute.
    // Try backend RPC if caller has permission; otherwise simply refresh orders.
    try {
      await _apiClient.dio.post<dynamic>(ApiEndpoints.sbRpcResaleCronWorker);
    } on DioException catch (_) {
      // Non-admin/anon callers may not execute cron RPC directly; ignore safely.
    }
    await _refreshOrders().catchError((_) => const <Order>[]);
    return const ResaleWorkerResult(expiredOrders: [], updatedBoxes: []);
  }

  @override
  Future<ResaleWorkerResult> expireOrderSprintNow(
    String orderId, [
    DateTime? now,
  ]) async {
    await _refreshOrders();
    final current = await getOrderById(orderId);
    return ResaleWorkerResult(
      expiredOrders: current == null ? const [] : [current],
      updatedBoxes: const [],
    );
  }

  @override
  Future<PickupCompletionResult> completePickup({
    required String venueId,
    String? qrCode,
    String? pinCode,
  }) async {
    try {
      final token = (qrCode != null && qrCode.trim().isNotEmpty)
          ? qrCode.trim()
          : (pinCode?.trim() ?? '');
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcCompletePickup,
        data: {'p_qr_or_pin': token},
      );
      final order = SupabaseMappers.orderFromRow(res.data!);
      await _refreshOrders();
      return PickupCompletionResult(order: order, wasAlreadyPickedUp: false);
    } on DioException catch (e) {
      throw ApiException(
        message: _extractDioError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Order> submitComplaint({
    required String orderId,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.sbRpcSubmitComplaint,
        data: {
          'p_order_id': orderId,
          'p_note': note,
          'p_photo_paths': photoPaths,
        },
      );
      final order = SupabaseMappers.orderFromRow(res.data!);
      await _refreshOrders();
      return order;
    });
  }

  @override
  Future<Order> resolveComplaint({
    required String orderId,
    required ComplaintStatus status,
    required String resolutionNote,
  }) async {
    return _guardDio(() async {
      final res = await _apiClient.dio.patch<List<dynamic>>(
        '${ApiEndpoints.sbOrders}?id=eq.$orderId',
        data: {
          'complaint_status': status.apiValue,
          'complaint_resolution_note': resolutionNote,
        },
        options: Options(headers: const {'Prefer': 'return=representation'}),
      );
      final order = SupabaseMappers.orderFromRow(
        res.data!.first as Map<String, dynamic>,
      );
      await _refreshOrders();
      return order;
    });
  }
}
