/// Константы маршрутов и именованных путей GoRouter.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String forcePasswordChange = '/force-password-change';
  static const String partnerApply = '/partner-apply';

  // Вкладки покупателя
  static const String home = '/home';
  static const String map = '/map';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // Детальные маршруты покупателя
  static const String boxDetail = '/box/:boxId';
  static const String checkout = '/checkout/:boxId';
  static const String order = '/order/:orderId';
  static const String success = '/success/:orderId';
  static const String qyzylKitap = '/qyzyl-kitap';

  // Вкладки магазина (заведения)
  static const String venueToday = '/venue/today';
  static const String venuePickup = '/venue/pickup';
  static const String venueStats = '/venue/stats';

  // Отдельные маршруты магазина
  static const String venueNewBox = '/venue/new-box';
  static const String venueSettings = '/venue/settings';

  // Вкладки админ-панели
  static const String adminDashboard = '/admin/dashboard';
  static const String adminVenues = '/admin/venues';
  static const String adminBoxes = '/admin/boxes';
  static const String adminComplaints = '/admin/complaints';

  static String boxDetailPath(String boxId) => '/box/$boxId';
  static String checkoutPath(String boxId) => '/checkout/$boxId';
  static String orderPath(String orderId) => '/order/$orderId';
  static String successPath(String orderId) => '/success/$orderId';
  static String authWithNext(String nextLocation) =>
      '/auth?next=${Uri.encodeComponent(nextLocation)}';
}
