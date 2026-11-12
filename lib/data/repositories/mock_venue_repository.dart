import 'dart:async';

import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/review.dart';
import 'package:toidym/shared/models/venue.dart';

/// Мок-репозиторий заведений, лид-заявок, автосоздания PARTNER и отзывов.
class MockVenueRepository implements VenueRepository {
  MockVenueRepository(this._authRepository)
      : _venues = SeedData.createVenues().toList(),
        _reviews = SeedData.createReviews().toList(),
        _staffByVenue = {
          SeedData.demoManagedVenueId: [
            const VenueStaffMember(
              id: 'staff_1',
              name: 'Айгерим (Владелец)',
              phone: '+7 (701) 200-30-40',
              role: UserRole.partner,
            ),
            const VenueStaffMember(
              id: 'staff_2',
              name: 'Алибек (Кассир)',
              phone: '+7 (701) 555-32-10',
              role: UserRole.cashier,
            ),
          ],
        };

  final AuthRepository _authRepository;
  final List<Venue> _venues;
  final List<Review> _reviews;
  final Map<String, List<VenueStaffMember>> _staffByVenue;
  final _venuesController = StreamController<List<Venue>>.broadcast();

  void _emitVenues() {
    _venuesController.add(List<Venue>.unmodifiable(_venues));
  }

  @override
  Future<List<Venue>> getVenues() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Venue>.unmodifiable(_venues);
  }

  @override
  Stream<List<Venue>> watchVenues() async* {
    yield List<Venue>.unmodifiable(_venues);
    yield* _venuesController.stream;
  }

  @override
  Future<Venue?> getVenueById(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final venue in _venues) {
      if (venue.id == venueId) return venue;
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
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final venue = Venue(
      id: 'venue_lead_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: category,
      district: district,
      address: address.trim(),
      lat: district.centerLat,
      lng: district.centerLng,
      rating: 5.0,
      reviewsCount: 0,
      isHalal: false,
      halalCertStatus: HalalCertStatus.none,
      workHours: const WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 22 * 60),
      phone: phone.trim(),
      photo:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      status: VenueStatus.pending,
      rejectionComment: email.trim().isNotEmpty ? 'Email: ${email.trim()}' : null,
    );
    _venues.insert(0, venue);
    _emitVenues();
    return venue;
  }

  @override
  Future<Venue> submitOnboarding(Venue venue) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final idx = _venues.indexWhere((v) => v.id == venue.id);
    final pendingVenue = venue.copyWith(status: VenueStatus.pending);
    if (idx == -1) {
      _venues.add(pendingVenue);
    } else {
      _venues[idx] = pendingVenue;
    }
    _emitVenues();
    return pendingVenue;
  }

  @override
  Future<Venue> updateVenueSettings(Venue venue) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _venues.indexWhere((v) => v.id == venue.id);
    if (idx == -1) {
      _venues.add(venue);
    } else {
      _venues[idx] = venue;
    }
    _emitVenues();
    return venue;
  }

  @override
  Future<PartnerProvisionResult> approvePartnerLead({
    required String venueId,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _venues.indexWhere((v) => v.id == venueId);
    if (idx == -1) throw StateError('Venue not found: $venueId');

    final approved = _venues[idx].copyWith(
      status: VenueStatus.approved,
      rejectionFields: const [],
      rejectionComment: null,
    );
    _venues[idx] = approved;
    _emitVenues();

    final provisioned = await _authRepository.provisionPartnerAccount(
      venueId: approved.id,
      venueName: approved.name,
      phone: approved.phone,
      email: email,
    );

    return PartnerProvisionResult(
      venue: approved,
      partnerUser: provisioned.user,
      temporaryPassword: provisioned.temporaryPassword,
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final id = 'venue_${DateTime.now().millisecondsSinceEpoch}';
    final venue = Venue(
      id: id,
      name: name.trim(),
      category: category,
      district: district,
      address: address.trim(),
      lat: district.centerLat,
      lng: district.centerLng,
      rating: 5.0,
      reviewsCount: 0,
      isHalal: false,
      halalCertStatus: HalalCertStatus.none,
      workHours: const WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 22 * 60),
      phone: phone.trim(),
      photo:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      status: VenueStatus.approved,
    );
    _venues.insert(0, venue);
    _emitVenues();

    final provisioned = await _authRepository.provisionPartnerAccount(
      venueId: venue.id,
      venueName: venue.name,
      phone: venue.phone,
      email: email,
    );
    return PartnerProvisionResult(
      venue: venue,
      partnerUser: provisioned.user,
      temporaryPassword: provisioned.temporaryPassword,
    );
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
    return setDemoVenueStatus(
      venueId: venueId,
      status: VenueStatus.approved,
    );
  }

  @override
  Future<Venue> setDemoVenueStatus({
    required String venueId,
    required VenueStatus status,
    List<String> rejectionFields = const [],
    String? rejectionComment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _venues.indexWhere((v) => v.id == venueId);
    if (idx == -1) throw StateError('Venue not found: $venueId');
    final keepComment =
        status == VenueStatus.rejected || status == VenueStatus.banned;
    final updated = _venues[idx].copyWith(
      status: status,
      rejectionFields: status == VenueStatus.rejected ? rejectionFields : const [],
      rejectionComment: keepComment ? rejectionComment : null,
    );
    _venues[idx] = updated;
    _emitVenues();
    return updated;
  }

  @override
  Future<Venue> updateHalalCertStatus({
    required String venueId,
    required HalalCertStatus halalCertStatus,
    String? halalCertNumber,
    String? halalCertPhoto,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _venues.indexWhere((v) => v.id == venueId);
    if (idx == -1) throw StateError('Venue not found: $venueId');
    final current = _venues[idx];
    final nextIsHalal = switch (halalCertStatus) {
      HalalCertStatus.verified => true,
      HalalCertStatus.rejected || HalalCertStatus.none => false,
      HalalCertStatus.pending => current.isHalal,
    };
    final updated = current.copyWith(
      isHalal: nextIsHalal,
      halalCertStatus: halalCertStatus,
      halalCertNumber: halalCertNumber ?? current.halalCertNumber,
      halalCertPhoto: halalCertPhoto ?? current.halalCertPhoto,
    );
    _venues[idx] = updated;
    _emitVenues();
    return updated;
  }

  @override
  Future<List<Review>> getVenueReviews(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _reviews
        .where((r) => r.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<Review> addReview(Review review) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _reviews.insert(0, review);

    final idx = _venues.indexWhere((v) => v.id == review.venueId);
    if (idx != -1) {
      final venue = _venues[idx];
      final totalScore = venue.rating * venue.reviewsCount + review.rating;
      final newCount = venue.reviewsCount + 1;
      _venues[idx] = venue.copyWith(
        reviewsCount: newCount,
        rating: double.parse((totalScore / newCount).toStringAsFixed(1)),
      );
      _emitVenues();
    }
    return review;
  }

  @override
  Future<List<VenueStaffMember>> getStaff(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<VenueStaffMember>.unmodifiable(
      _staffByVenue[venueId] ?? const [],
    );
  }

  @override
  Future<VenueStaffMember> addCashier({
    required String venueId,
    required String name,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final member = VenueStaffMember(
      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      role: UserRole.cashier,
    );
    final list = _staffByVenue.putIfAbsent(venueId, () => []);
    list.add(member);
    return member;
  }
}
