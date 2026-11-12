import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/models/user.dart';
import 'package:toidym/shared/models/venue.dart';

/// Сотрудник заведения (владелец / кассир).
class VenueStaffMember {
  const VenueStaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
}

/// Результат одобрения или создания партнёра с временным паролем.
class PartnerProvisionResult {
  const PartnerProvisionResult({
    required this.venue,
    required this.partnerUser,
    required this.temporaryPassword,
  });

  final Venue venue;
  final User partnerUser;
  final String temporaryPassword;
}

/// Интерфейс репозитория заведений, заявок партнёров и отзывов.
abstract interface class VenueRepository {
  Future<List<Venue>> getVenues();

  Stream<List<Venue>> watchVenues();

  Future<Venue?> getVenueById(String venueId);

  Future<Venue?> getManagedVenue(String venueId);

  /// `POST /api/v1/venue/apply` — открытая заявка «Стать партнёром».
  Future<Venue> submitPartnerLead({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  });

  Future<Venue> submitOnboarding(Venue venue);

  Future<Venue> updateVenueSettings(Venue venue);

  /// `POST /api/v1/admin/venues/:id/approve` — одобряет заявку и создаёт PARTNER-аккаунт.
  Future<PartnerProvisionResult> approvePartnerLead({
    required String venueId,
    required String email,
  });

  /// Ручное добавление партнёра администратором (автогенерация PARTNER + временного пароля).
  Future<PartnerProvisionResult> createPartnerByAdmin({
    required String name,
    required String phone,
    required String address,
    required String email,
    required AstanaDistrict district,
    required VenueCategory category,
  });

  Future<Venue> banVenue({
    required String venueId,
    required String reason,
  });

  Future<Venue> unbanVenue(String venueId);

  Future<Venue> setDemoVenueStatus({
    required String venueId,
    required VenueStatus status,
    List<String> rejectionFields = const [],
    String? rejectionComment,
  });

  Future<Venue> updateHalalCertStatus({
    required String venueId,
    required HalalCertStatus halalCertStatus,
    String? halalCertNumber,
    String? halalCertPhoto,
  });

  Future<List<Review>> getVenueReviews(String venueId);

  Future<Review> addReview(Review review);

  Future<List<VenueStaffMember>> getStaff(String venueId);

  Future<VenueStaffMember> addCashier({
    required String venueId,
    required String name,
    required String phone,
  });
}
