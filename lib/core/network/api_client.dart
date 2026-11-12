import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';

/// Карта REST API эндпойнтов бэкенда toıdym.
abstract final class ApiEndpoints {
  static const String authRegister = '/api/v1/auth/register';
  static const String authVerifyEmail = '/api/v1/auth/verify-email';
  static const String authLogin = '/api/v1/auth/login';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String venueApply = '/api/v1/venue/apply';
  static const String venueTemplates = '/api/v1/venue/templates';
  static const String venueBoxesFromTemplate = '/api/v1/venue/boxes/from-template';
  static const String cronResaleWorker = '/api/v1/cron/resale-worker';
  static String orderExpireSprint(String orderId) =>
      '/api/v1/orders/$orderId/expire-sprint';
  static String adminApproveVenue(String venueId) =>
      '/api/v1/admin/venues/$venueId/approve';

  // Supabase Auth, PostgREST & Edge Functions endpoints
  static const String sbAuthSignup = '/auth/v1/signup';
  static const String sbAuthToken = '/auth/v1/token';
  static const String sbAuthUser = '/auth/v1/user';
  static const String sbAuthRecover = '/auth/v1/recover';
  static const String sbAuthLogout = '/auth/v1/logout';
  static const String sbProfiles = '/rest/v1/profiles';
  static const String sbVenues = '/rest/v1/venues';
  static const String sbVenueStaff = '/rest/v1/venue_staff';
  static const String sbBoxTemplates = '/rest/v1/box_templates';
  static const String sbBoxes = '/rest/v1/boxes';
  static const String sbOrders = '/rest/v1/orders';
  static const String sbReviews = '/rest/v1/reviews';
  static const String sbNotifications = '/rest/v1/notifications';
  static const String sbAuditLogs = '/rest/v1/audit_logs';
  static const String sbPartnerApplications = '/rest/v1/partner_applications';
  static const String sbRpcPublishSprintBox = '/rest/v1/rpc/publish_sprint_box';
  static const String sbRpcCreateReservation =
      '/rest/v1/rpc/create_trust_reservation';
  static const String sbRpcCompletePickup =
      '/rest/v1/rpc/complete_order_pickup';
  static const String sbRpcCancelOrder = '/rest/v1/rpc/cancel_order_atomic';
  static const String sbRpcSubmitHalalCert = '/rest/v1/rpc/submit_halal_cert';
  static const String sbRpcModerateHalalCert =
      '/rest/v1/rpc/moderate_halal_cert_admin';
  static const String sbRpcSubmitComplaint =
      '/rest/v1/rpc/submit_order_complaint';
  static const String sbRpcSubmitReview = '/rest/v1/rpc/submit_review_atomic';
  static const String sbRpcResaleCronWorker =
      '/rest/v1/rpc/api_run_resale_cron_worker';
  static const String sbRpcApprovePartnerLead =
      '/rest/v1/rpc/approve_partner_lead_admin';
  static const String sbRpcCreatePartnerStaff =
      '/rest/v1/rpc/create_partner_staff_admin';
  static const String sbFnApprovePartnerLead =
      '/functions/v1/approve-partner-lead';
  static const String sbFnCreatePartner = '/functions/v1/create-partner';
  static const String sbFnResaleWorker = '/functions/v1/resale-worker';
}

/// Типизированное исключение сетевого клиента.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP-клиент Dio с автоматическим прикреплением JWT и обновлением при 401.
///
/// В MVP используется мок-слой, поэтому реальные сетевые запросы не отправляются.
class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    String baseUrl = 'https://api.toidym.kz',
    String supabaseAnonKey = '',
    String Function()? localeProvider,
    Future<String?> Function(String refreshToken)? onRefreshToken,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (supabaseAnonKey.isNotEmpty) 'apikey': supabaseAnonKey,
            },
          ),
        ) {
    dio.interceptors.addAll([
      _AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        supabaseAnonKey: supabaseAnonKey,
        onRefreshToken: onRefreshToken,
      ),
      _LocaleInterceptor(localeProvider: localeProvider),
      if (kDebugMode) _DebugLogInterceptor(),
    ]);
  }

  final Dio dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.supabaseAnonKey = '',
    this.onRefreshToken,
  });

  final Dio dio;
  final SecureTokenStorage tokenStorage;
  final String supabaseAnonKey;
  final Future<String?> Function(String refreshToken)? onRefreshToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (supabaseAnonKey.isNotEmpty) {
      options.headers['apikey'] = supabaseAnonKey;
    }
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else if (supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.startsWith('sb_')) {
      options.headers['Authorization'] = 'Bearer $supabaseAnonKey';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['_retried'] == true;
    if (statusCode == 401 && !alreadyRetried && onRefreshToken != null) {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final newAccess = await onRefreshToken!(refreshToken);
        if (newAccess != null && newAccess.isNotEmpty) {
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          requestOptions.extra['_retried'] = true;
          try {
            final response = await dio.fetch<dynamic>(requestOptions);
            handler.resolve(response);
            return;
          } catch (_) {
            // Fall through to standard error handling.
          }
        }
      }
    }
    handler.next(err);
  }
}

class _LocaleInterceptor extends Interceptor {
  _LocaleInterceptor({this.localeProvider});

  final String Function()? localeProvider;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Accept-Language'] = localeProvider?.call() ?? 'ru';
    handler.next(options);
  }
}

class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] -> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] !! ${err.type}: ${err.message}');
    handler.next(err);
  }
}
