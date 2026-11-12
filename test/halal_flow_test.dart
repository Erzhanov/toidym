import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/data/repositories/mock_venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/enums.dart';

void main() {
  test('Halal cert photo submission and Admin approval updates isHalal and box rules', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final auth = MockAuthRepository(
      AppPreferences(sp),
      SecureTokenStorage.inMemory(),
    );
    final venueRepo = MockVenueRepository(auth);
    final venues = await venueRepo.getVenues();
    final target = venues.firstWhere((v) => !v.hasVerifiedHalalBadge);

    final refNow = DateTime(2026, 11, 12, 12, 0);
    final window = BoxBusinessRules.calculateSprintPickupWindow(
      target,
      now: refNow,
    );

    const samplePhoto =
        'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==';

    // 1. Before Halal verification: regular boxes are allowed; Halal boxes are blocked.
    final regularBefore = BoxBusinessRules.validateNewBox(
      venue: target,
      title: 'Обычный бокс',
      description: 'Свежая выпечка',
      originalPrice: 2000,
      discountPrice: 900,
      quantity: 3,
      pickupWindow: window,
      markAsHalal: false,
      now: refNow,
    );
    expect(regularBefore, isEmpty);

    final halalBefore = BoxBusinessRules.validateNewBox(
      venue: target,
      title: 'Халал бокс',
      description: 'Свежая выпечка',
      originalPrice: 2000,
      discountPrice: 900,
      quantity: 3,
      pickupWindow: window,
      markAsHalal: true,
      now: refNow,
    );
    expect(halalBefore, contains(BusinessRuleViolation.halalCertNotVerified));

    // 2. Partner uploads photo -> status becomes pending.
    final pendingVenue = await venueRepo.updateHalalCertStatus(
      venueId: target.id,
      halalCertStatus: HalalCertStatus.pending,
      halalCertPhoto: samplePhoto,
    );
    expect(pendingVenue.halalCertStatus, HalalCertStatus.pending);
    expect(pendingVenue.resolvedHalalCertPhoto, samplePhoto);
    expect(pendingVenue.hasVerifiedHalalBadge, isFalse);

    // 3. Admin approves -> halalCertStatus == verified AND isHalal == true.
    final verifiedVenue = await venueRepo.updateHalalCertStatus(
      venueId: target.id,
      halalCertStatus: HalalCertStatus.verified,
      halalCertPhoto: pendingVenue.resolvedHalalCertPhoto,
    );
    expect(verifiedVenue.halalCertStatus, HalalCertStatus.verified);
    expect(verifiedVenue.isHalal, isTrue);
    expect(verifiedVenue.hasVerifiedHalalBadge, isTrue);
    expect(verifiedVenue.resolvedHalalCertPhoto, samplePhoto);

    // 4. Verified store can now publish Halal boxes.
    final halalAfter = BoxBusinessRules.validateNewBox(
      venue: verifiedVenue,
      title: 'Халал бокс',
      description: 'Свежая выпечка',
      originalPrice: 2000,
      discountPrice: 900,
      quantity: 3,
      pickupWindow: window,
      markAsHalal: true,
      now: refNow,
    );
    expect(halalAfter, isEmpty);

    // 5. Rejecting revokes badge.
    final rejectedVenue = await venueRepo.updateHalalCertStatus(
      venueId: target.id,
      halalCertStatus: HalalCertStatus.rejected,
      halalCertPhoto: verifiedVenue.resolvedHalalCertPhoto,
    );
    expect(rejectedVenue.halalCertStatus, HalalCertStatus.rejected);
    expect(rejectedVenue.isHalal, isFalse);
    expect(rejectedVenue.hasVerifiedHalalBadge, isFalse);
  });
}
