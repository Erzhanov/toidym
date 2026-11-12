import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/core/config/app_config.dart';
import 'package:toidym/core/network/api_client.dart';
import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/data/repositories/mock_audit_log_repository.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/data/repositories/mock_box_repository.dart';
import 'package:toidym/data/repositories/mock_order_repository.dart';
import 'package:toidym/data/repositories/mock_venue_repository.dart';
import 'package:toidym/data/repositories/osm_map_provider.dart';
import 'package:toidym/data/repositories/supabase_repositories.dart';
import 'package:toidym/domain/repositories/audit_log_repository.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/repositories/box_repository.dart';
import 'package:toidym/domain/repositories/map_provider.dart';
import 'package:toidym/domain/repositories/order_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/app_notification.dart';
import 'package:toidym/shared/models/audit_log.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/models/venue.dart';

// ---------------------------------------------------------------------------
// Инфраструктура и хранилища (переопределяются в main.dart при запуске)
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final hiveStorageProvider = Provider<HiveStorage>((ref) {
  throw UnimplementedError('hiveStorageProvider must be overridden');
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  throw UnimplementedError('secureTokenStorageProvider must be overridden');
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(ref.watch(sharedPreferencesProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final baseUrl = AppConfig.effectiveBaseUrl;
  final anonKey = AppConfig.supabaseAnonKey;

  Future<String?> refreshSessionToken(String refreshToken) async {
    if (!AppConfig.isBackendConfigured || refreshToken.trim().isEmpty) {
      return null;
    }
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (anonKey.isNotEmpty) 'apikey': anonKey,
          },
        ),
      );
      final res = await refreshDio.post<Map<String, dynamic>>(
        '${ApiEndpoints.sbAuthToken}?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data ?? const {};
      final newAccess = data['access_token'] as String? ?? '';
      final newRefresh = data['refresh_token'] as String? ?? refreshToken;
      final userMap = data['user'] as Map<String, dynamic>?;
      final uid =
          (userMap?['id'] as String?) ??
          (await tokenStorage.getSessionUserId()) ??
          '';
      if (newAccess.isNotEmpty && uid.isNotEmpty) {
        await tokenStorage.saveSession(
          accessToken: newAccess,
          refreshToken: newRefresh,
          userId: uid,
        );
        return newAccess;
      }
    } catch (_) {
      // Invalid or expired refresh token — caller falls back to unauthenticated.
    }
    return null;
  }

  return ApiClient(
    tokenStorage: tokenStorage,
    baseUrl: baseUrl,
    supabaseAnonKey: anonKey,
    localeProvider: () => prefs.getLanguage().code,
    onRefreshToken: refreshSessionToken,
  );
});

// ---------------------------------------------------------------------------
// Репозитории (Clean Architecture: UI работает только с domain-интерфейсами)
// По умолчанию подключает Supabase/Edge Functions (в тестах переопределяется на моки).
// ---------------------------------------------------------------------------

/// Флаг выбора удалённого Supabase-бэкенда (переопределяется в виджет-тестах).
final useBackendProvider = Provider<bool>((ref) {
  return AppConfig.isBackendConfigured;
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  if (ref.watch(useBackendProvider)) {
    return SupabaseAuditLogRepository(ref.watch(apiClientProvider));
  }
  return MockAuditLogRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useBackendProvider)) {
    return SupabaseAuthRepository(
      ref.watch(apiClientProvider),
      ref.watch(appPreferencesProvider),
      ref.watch(secureTokenStorageProvider),
    );
  }
  return MockAuthRepository(
    ref.watch(appPreferencesProvider),
    ref.watch(secureTokenStorageProvider),
  );
});

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  if (ref.watch(useBackendProvider)) {
    return SupabaseVenueRepository(ref.watch(apiClientProvider));
  }
  return MockVenueRepository(ref.watch(authRepositoryProvider));
});

final boxRepositoryProvider = Provider<BoxRepository>((ref) {
  if (ref.watch(useBackendProvider)) {
    return SupabaseBoxRepository(
      ref.watch(apiClientProvider),
      ref.watch(hiveStorageProvider),
      ref.watch(venueRepositoryProvider),
    );
  }
  return MockBoxRepository(
    ref.watch(hiveStorageProvider),
    ref.watch(venueRepositoryProvider),
  );
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (ref.watch(useBackendProvider)) {
    return SupabaseOrderRepository(ref.watch(apiClientProvider));
  }
  return MockOrderRepository(
    ref.watch(boxRepositoryProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(venueRepositoryProvider),
  );
});

final mapProvider = Provider<MapProvider>((ref) {
  return const OsmMapProvider();
});

// ---------------------------------------------------------------------------
// Глобальное состояние приложения (язык, онбординг, район, пользователь, режим)
// ---------------------------------------------------------------------------

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(AppPreferences prefs, this._authRepo)
      : super(Locale(prefs.getLanguage().code));

  final AuthRepository _authRepo;

  Future<void> setLanguage(AppLanguage language) async {
    state = Locale(language.code);
    await _authRepo.updateLanguage(language);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(
    ref.watch(appPreferencesProvider),
    ref.watch(authRepositoryProvider),
  );
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._prefs) : super(_prefs.isOnboardingCompleted);

  final AppPreferences _prefs;

  Future<void> complete() async {
    state = true;
    await _prefs.setOnboardingCompleted(true);
  }

  Future<void> reset() async {
    state = false;
    await _prefs.setOnboardingCompleted(false);
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(appPreferencesProvider));
});

class DistrictNotifier extends StateNotifier<AstanaDistrict> {
  DistrictNotifier(this._prefs) : super(_prefs.getSelectedDistrict());

  final AppPreferences _prefs;

  Future<void> selectDistrict(AstanaDistrict district) async {
    state = district;
    await _prefs.setSelectedDistrict(district);
  }
}

final selectedDistrictProvider =
    StateNotifierProvider<DistrictNotifier, AstanaDistrict>((ref) {
  return DistrictNotifier(ref.watch(appPreferencesProvider));
});

class AppModeNotifier extends StateNotifier<AppMode> {
  AppModeNotifier(this._prefs) : super(_prefs.getActiveMode());

  final AppPreferences _prefs;

  Future<void> setMode(AppMode mode) async {
    state = mode;
    await _prefs.setActiveMode(mode);
  }
}

final activeAppModeProvider =
    StateNotifierProvider<AppModeNotifier, AppMode>((ref) {
  return AppModeNotifier(ref.watch(appPreferencesProvider));
});

class DietaryPreferencesNotifier
    extends StateNotifier<Set<DietaryPreference>> {
  DietaryPreferencesNotifier(this._prefs, this._authRepo)
      : super(_prefs.getDietaryPreferences());

  final AppPreferences _prefs;
  final AuthRepository _authRepo;

  Future<void> toggle(DietaryPreference pref) async {
    final next = Set<DietaryPreference>.from(state);
    if (!next.remove(pref)) {
      next.add(pref);
    }
    await setAll(next);
  }

  Future<void> setAll(Set<DietaryPreference> prefs) async {
    state = Set<DietaryPreference>.unmodifiable(prefs);
    await _prefs.setDietaryPreferences(prefs);
    if (_authRepo.currentUser != null) {
      await _authRepo.updateDietaryPreferences(prefs);
    }
  }
}

final dietaryPreferencesProvider = StateNotifierProvider<
    DietaryPreferencesNotifier, Set<DietaryPreference>>((ref) {
  return DietaryPreferencesNotifier(
    ref.watch(appPreferencesProvider),
    ref.watch(authRepositoryProvider),
  );
});

final currentUserStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(currentUserStreamProvider).valueOrNull ??
      ref.watch(authRepositoryProvider).currentUser;
});

final allUsersStreamProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(authRepositoryProvider).watchAllUsers();
});

final allUsersProvider = Provider<List<User>>((ref) {
  return ref.watch(allUsersStreamProvider).valueOrNull ??
      ref.watch(authRepositoryProvider).getAllUsersSnapshot();
});

final auditLogsStreamProvider = StreamProvider<List<AuditLogEntry>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchAuditLogs();
});

final auditLogsProvider = Provider<List<AuditLogEntry>>((ref) {
  return ref.watch(auditLogsStreamProvider).valueOrNull ??
      ref.watch(auditLogRepositoryProvider).getAuditLogsSnapshot();
});

final favoriteAlertsProvider = StateProvider<bool>((ref) {
  return ref.watch(appPreferencesProvider).favoriteAlertsEnabled;
});

// ---------------------------------------------------------------------------
// Избранное (Hive)
// ---------------------------------------------------------------------------

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._storage) : super(_storage.getFavoriteBoxIds());

  final HiveStorage _storage;

  Future<void> toggle(String boxId) async {
    state = await _storage.toggleFavoriteBoxId(boxId);
  }

  bool isFavorite(String boxId) => state.contains(boxId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(hiveStorageProvider));
});

// ---------------------------------------------------------------------------
// Фильтры, сортировка, GPS, боксы, шаблоны, заведения и заказы
// ---------------------------------------------------------------------------

final boxFilterChipProvider = StateProvider<BoxFilterChip>(
  (ref) => BoxFilterChip.all,
);

final boxSortOptionProvider = StateProvider<BoxSortOption>(
  (ref) => BoxSortOption.nearest,
);

final userCoordinatesProvider = StateProvider<({double lat, double lng})?>(
  (ref) => null,
);

final boxSearchQueryProvider = StateProvider<String>((ref) => '');

final filterStrictlyByDistrictProvider = StateProvider<bool>((ref) => false);

final venuesStreamProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).watchVenues();
});

final venuesProvider = FutureProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).getVenues();
});

final venuesMapProvider = Provider<Map<String, Venue>>((ref) {
  final venues = ref.watch(venuesStreamProvider).valueOrNull ??
      ref.watch(venuesProvider).valueOrNull ??
      const [];
  return {for (final v in venues) v.id: v};
});

/// Идентификатор активного заведения для режима «Заведение».
/// Проверяет `managedVenueId`, затем `ownerId` в списке заведений и в backend-режиме
/// никогда не подставляет offline-ID (`venue_1`), если есть реальные заведения в базе.
final managedVenueIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  final useBackend = ref.watch(useBackendProvider);
  final venues = ref.watch(venuesStreamProvider).valueOrNull ??
      ref.watch(venuesProvider).valueOrNull ??
      const <Venue>[];
  final venuesMap = {for (final v in venues) v.id: v};

  final explicitId = user?.managedVenueId?.trim();
  if (explicitId != null && explicitId.isNotEmpty) {
    if (!useBackend || venuesMap.isEmpty || venuesMap.containsKey(explicitId)) {
      return explicitId;
    }
  }

  if (user != null) {
    for (final v in venues) {
      if (v.ownerId == user.id) {
        return v.id;
      }
    }
  }

  if (!useBackend) {
    return SeedData.demoManagedVenueId;
  }

  for (final v in venues) {
    if (v.status == VenueStatus.approved && v.ownerId != null) {
      return v.id;
    }
  }
  for (final v in venues) {
    if (v.status == VenueStatus.approved) {
      return v.id;
    }
  }
  if (venues.isNotEmpty) {
    return venues.first.id;
  }
  return explicitId ?? SeedData.demoManagedVenueId;
});

final allBoxesStreamProvider = StreamProvider<List<Box>>((ref) {
  return ref.watch(boxRepositoryProvider).watchBoxes();
});

final boxesFeedProvider = FutureProvider<List<Box>>((ref) async {
  // Подписка на потоки боксов и заведений для мгновенного обновления ленты и модерации.
  ref.watch(allBoxesStreamProvider);
  ref.watch(venuesStreamProvider);
  final filter = ref.watch(boxFilterChipProvider);
  final query = ref.watch(boxSearchQueryProvider);
  final strictDistrict = ref.watch(filterStrictlyByDistrictProvider);
  final district = ref.watch(selectedDistrictProvider);
  final dietary = ref.watch(dietaryPreferencesProvider);
  final sortOption = ref.watch(boxSortOptionProvider);
  final coords = ref.watch(userCoordinatesProvider);

  return ref.watch(boxRepositoryProvider).getBoxes(
        district: strictDistrict ? district : null,
        filter: filter,
        query: query,
        dietaryPreferences: dietary,
        sortOption: sortOption,
        userLat: coords?.lat,
        userLng: coords?.lng,
      );
});

final venueTemplatesProvider = FutureProvider<List<BoxTemplate>>((ref) async {
  ref.watch(allBoxesStreamProvider);
  final venueId = ref.watch(managedVenueIdProvider);
  return ref.watch(boxRepositoryProvider).getVenueTemplates(venueId);
});

final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).watchOrders();
});

final allPlatformOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersStreamProvider).valueOrNull ?? const [];
});

final adminPendingVenuesCountProvider = Provider<int>((ref) {
  final venues = ref.watch(venuesStreamProvider).valueOrNull ?? const [];
  return venues
      .where(
        (v) =>
            v.status == VenueStatus.pending ||
            v.halalCertStatus == HalalCertStatus.pending,
      )
      .length;
});

final adminOpenComplaintsCountProvider = Provider<int>((ref) {
  final orders = ref.watch(allPlatformOrdersProvider);
  return orders
      .where((o) => o.complaintSubmitted && o.complaintStatus.isOpen)
      .length;
});

final buyerOrdersProvider = Provider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final allOrders = ref.watch(ordersStreamProvider).valueOrNull ?? const [];
  return allOrders
      .where((o) => o.userId == user.id)
      .toList(growable: false);
});

final activeBuyerOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(buyerOrdersProvider);
  return orders.where((o) => o.status.isActive).length;
});

final venuePendingOrdersProvider = Provider<List<Order>>((ref) {
  final venueId = ref.watch(managedVenueIdProvider);
  final allOrders = ref.watch(ordersStreamProvider).valueOrNull ?? const [];
  return allOrders
      .where(
        (o) => o.venueId == venueId && o.status.isActive && !o.isCharityBox,
      )
      .toList(growable: false);
});

final venuePendingOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(venuePendingOrdersProvider).length;
});

// ---------------------------------------------------------------------------
// Уведомления
// ---------------------------------------------------------------------------

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier([this._apiClient])
      : super(
          _apiClient != null ? const [] : SeedData.createNotifications(),
        ) {
    if (_apiClient != null) {
      unawaited(refreshFromBackend());
    }
  }

  final ApiClient? _apiClient;

  Future<void> refreshFromBackend() async {
    final client = _apiClient;
    if (client == null) return;
    try {
      final res = await client.dio.get<List<dynamic>>(
        '${ApiEndpoints.sbNotifications}?order=created_at.desc&limit=50',
      );
      final rows = res.data ?? const [];
      state = rows.whereType<Map<String, dynamic>>().map((r) {
        return AppNotification(
          id: r['id'] as String? ?? '',
          titleRu: r['title_ru'] as String? ?? '',
          titleKk: r['title_kk'] as String? ?? '',
          bodyRu: r['body_ru'] as String? ?? '',
          bodyKk: r['body_kk'] as String? ?? '',
          createdAt:
              DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal() ??
                  DateTime.now(),
          isRead: r['is_read'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {}
  }

  void markAllRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
    final client = _apiClient;
    if (client != null) {
      unawaited(_markAllReadRemote(client));
    }
  }

  Future<void> _markAllReadRemote(ApiClient client) async {
    try {
      await client.dio.patch<dynamic>(
        '${ApiEndpoints.sbNotifications}?is_read=eq.false',
        data: const {'is_read': true},
      );
    } catch (_) {}
  }

  void addStrikeNotification(String orderNumber) {
    final item = AppNotification(
      id: 'notif_strike_${DateTime.now().millisecondsSinceEpoch}',
      titleRu: 'Заказ $orderNumber аннулирован (No-Show)',
      titleKk: '$orderNumber тапсырысы жойылды (No-Show)',
      bodyRu: 'Заказ аннулирован, вам начислено 1 предупреждение (Strike)',
      bodyKk: 'Тапсырыс жойылды және сізге 1 ескерту (Strike) берілді',
      createdAt: DateTime.now(),
    );
    state = [item, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier(
    ref.watch(useBackendProvider) ? ref.watch(apiClientProvider) : null,
  );
});

/// 1-минутный CRON-воркер автоперепродажи (Resale Worker).
class ResaleCronController extends StateNotifier<ResaleWorkerResult?> {
  ResaleCronController(
    this._orderRepository,
    this._notifications,
    this._readCurrentUser,
  ) : super(null) {
    _timer = Timer.periodic(
      const Duration(minutes: BusinessRulesConfig.resaleCronIntervalMinutes),
      (_) => unawaited(runCronTick()),
    );
  }

  final OrderRepository _orderRepository;
  final NotificationsNotifier _notifications;
  final User? Function() _readCurrentUser;
  Timer? _timer;

  Future<ResaleWorkerResult> runCronTick([DateTime? now]) async {
    try {
      final result = await _orderRepository.runResaleCronWorker(now);
      _handleResult(result);
      return result;
    } catch (_) {
      return const ResaleWorkerResult(expiredOrders: [], updatedBoxes: []);
    }
  }

  Future<ResaleWorkerResult> expireOrderSprint(
    String orderId, [
    DateTime? now,
  ]) async {
    final result = await _orderRepository.expireOrderSprintNow(orderId, now);
    _handleResult(result);
    return result;
  }

  void _handleResult(ResaleWorkerResult result) {
    if (!result.hasChanges) return;
    final currentUserId = _readCurrentUser()?.id;
    for (final order in result.expiredOrders) {
      if (currentUserId == null || order.userId == currentUserId) {
        _notifications.addStrikeNotification(order.orderNumber);
      }
    }
    state = result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final resaleCronProvider =
    StateNotifierProvider<ResaleCronController, ResaleWorkerResult?>((ref) {
  return ResaleCronController(
    ref.watch(orderRepositoryProvider),
    ref.read(notificationsProvider.notifier),
    () => ref.read(currentUserProvider),
  );
});
