import 'package:toidym/core/network/api_client.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/repositories/box_repository.dart';
import 'package:toidym/domain/repositories/order_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/models/venue.dart';

/// Заготовки Dio-реализаций доменных репозиториев для подключения реального API.
class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._apiClient);

  // ignore: unused_field
  final ApiClient _apiClient;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> watchCurrentUser() => const Stream.empty();

  @override
  List<User> getAllUsersSnapshot() => const [];

  @override
  Stream<List<User>> watchAllUsers() => const Stream.empty();

  @override
  Future<void> restoreSession() async {}

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.authRegister, data: ...);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User> verifyEmail(String email) {
    // TODO backend: _apiClient.dio.get(ApiEndpoints.authVerifyEmail);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<AuthSessionResult> login({
    required String identifier,
    required String password,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.authLogin, data: ...);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<void> requestPasswordReset(String email) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User> changeTemporaryPassword(String newPassword) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<void> logout() {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<({User user, String temporaryPassword})> provisionPartnerAccount({
    required String venueId,
    required String venueName,
    required String phone,
    required String email,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User> switchRole(UserRole role) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> updateLanguage(AppLanguage language) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> updateDietaryPreferences(Set<DietaryPreference> preferences) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> recordSavedBoxes({
    required int boxesCount,
    required int savedMoneyTenge,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> addStrike(String userId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> removeStrike(String userId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<User?> unbanUser(String userId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }
}

class DioBoxRepository implements BoxRepository {
  DioBoxRepository(this._apiClient);

  // ignore: unused_field
  final ApiClient _apiClient;

  @override
  Future<List<Box>> getBoxes({
    AstanaDistrict? district,
    BoxFilterChip filter = BoxFilterChip.all,
    String query = '',
    Set<DietaryPreference> dietaryPreferences = const {},
    BoxSortOption sortOption = BoxSortOption.nearest,
    double? userLat,
    double? userLng,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Stream<List<Box>> watchBoxes() => const Stream.empty();

  @override
  Future<Box?> getBoxById(String boxId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<List<Box>> getVenueBoxes(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> createBox(Box box) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> updateBoxStock({required String boxId, required int quantityLeft}) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> toggleBoxStatus({required String boxId, required BoxStatus status}) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> decrementStock({required String boxId, required int quantity}) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> restoreStock({required String boxId, required int quantity}) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<int> archiveExpiredBoxes([DateTime? now]) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> republishExpiredBox({
    required String boxId,
    required PickupWindow pickupWindow,
    required int quantity,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> requeueForResale({
    required String boxId,
    required int quantityDelta,
    required PickupWindow resaleWindow,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.cronResaleWorker);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<List<BoxTemplate>> getVenueTemplates(String venueId) {
    // TODO backend: _apiClient.dio.get(ApiEndpoints.venueTemplates);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<BoxTemplate> createTemplate(BoxTemplate template) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Box> publishFromTemplate({
    required BoxTemplate template,
    required int quantity,
    required PickupWindow pickupWindow,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.venueBoxesFromTemplate);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  void simulateNextFetchError() {}
}

class DioVenueRepository implements VenueRepository {
  DioVenueRepository(this._apiClient);

  // ignore: unused_field
  final ApiClient _apiClient;

  @override
  Future<List<Venue>> getVenues() {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Stream<List<Venue>> watchVenues() => const Stream.empty();

  @override
  Future<Venue?> getVenueById(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue?> getManagedVenue(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> submitPartnerLead({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.venueApply);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> submitOnboarding(Venue venue) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> updateVenueSettings(Venue venue) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<PartnerProvisionResult> approvePartnerLead({
    required String venueId,
    required String email,
  }) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.adminApproveVenue(venueId));
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<PartnerProvisionResult> createPartnerByAdmin({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> banVenue({required String venueId, required String reason}) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> unbanVenue(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> setDemoVenueStatus({
    required String venueId,
    required VenueStatus status,
    List<String> rejectionFields = const [],
    String? rejectionComment,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Venue> updateHalalCertStatus({
    required String venueId,
    required HalalCertStatus halalCertStatus,
    String? halalCertNumber,
    String? halalCertPhoto,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<List<Review>> getVenueReviews(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Review> addReview(Review review) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<List<VenueStaffMember>> getStaff(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<VenueStaffMember> addCashier({
    required String venueId,
    required String name,
    required String phone,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }
}

class DioOrderRepository implements OrderRepository {
  DioOrderRepository(this._apiClient);

  // ignore: unused_field
  final ApiClient _apiClient;

  @override
  Future<List<Order>> getOrders(String userId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Stream<List<Order>> watchOrders() => const Stream.empty();

  @override
  Future<List<Order>> getVenuePendingOrders(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<List<Order>> getVenueAllOrders(String venueId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order?> getOrderById(String orderId) {
    throw UnimplementedError('Real API is not connected in MVP');
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
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order> cancelOrderByBuyer(String orderId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order> cancelOrderByVenue({
    required String orderId,
    required String reason,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order> markOrderNoShow(String orderId) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<ResaleWorkerResult> runResaleCronWorker([DateTime? now]) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.cronResaleWorker);
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<ResaleWorkerResult> expireOrderSprintNow(
    String orderId, [
    DateTime? now,
  ]) {
    // TODO backend: _apiClient.dio.post(ApiEndpoints.orderExpireSprint(orderId));
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<PickupCompletionResult> completePickup({
    required String venueId,
    String? qrCode,
    String? pinCode,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order> submitComplaint({
    required String orderId,
    required String note,
    List<String> photoPaths = const [],
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }

  @override
  Future<Order> resolveComplaint({
    required String orderId,
    required ComplaintStatus status,
    required String resolutionNote,
  }) {
    throw UnimplementedError('Real API is not connected in MVP');
  }
}
