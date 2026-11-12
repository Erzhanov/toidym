import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/core/utils/input_formatters.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/data/repositories/mock_box_repository.dart';
import 'package:toidym/data/repositories/mock_order_repository.dart';
import 'package:toidym/data/repositories/mock_venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/main.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/venue.dart';

void main() {
  group('AppFormatters', () {
    test('formats KZT price with non-breaking spaces', () {
      expect(AppFormatters.formatPrice(2970), '2\u00A0970\u00A0₸');
      expect(AppFormatters.formatPrice(990), '990\u00A0₸');
      expect(AppFormatters.formatPrice(24500), '24\u00A0500\u00A0₸');
    });

    test('formats discount percent with typographic minus', () {
      expect(AppFormatters.formatDiscount(67), '\u221267%');
    });
  });

  group('AuthValidators & KzPhoneMaskFormatter', () {
    test('validates KZ phones, emails and strong password policy', () {
      expect(AuthValidators.isValidKzPhone('+7 (777) 123-45-67'), isTrue);
      expect(AuthValidators.isValidKzPhone('+1 (555) 123-45-67'), isFalse);
      expect(AuthValidators.isValidEmail('aigerim@toidym.kz'), isTrue);
      expect(AuthValidators.isValidEmail('bad-email'), isFalse);
      expect(AuthValidators.isStrongPassword('Pass1234'), isTrue);
      expect(AuthValidators.isStrongPassword('weak'), isFalse);
      expect(AuthValidators.isStrongPassword('nouppercase1'), isFalse);
      expect(AuthValidators.isStrongPassword('NoDigitsHere'), isFalse);
    });
  });

  group('BoxBusinessRules (Section 7 + Offline Booking + Lost Profit)', () {
    final now = DateTime(2026, 11, 10, 14, 0);
    const verifiedHalalVenue = Venue(
      id: 'v1',
      name: 'Test Bakery',
      category: VenueCategory.bakery,
      district: AstanaDistrict.esil,
      address: 'ул. Достык, 1',
      lat: 51.12,
      lng: 71.43,
      rating: 4.9,
      reviewsCount: 10,
      isHalal: true,
      halalCertStatus: HalalCertStatus.verified,
      workHours: WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 22 * 60),
      phone: '+77770000000',
      photo: '',
      status: VenueStatus.approved,
    );

    const unverifiedVenue = Venue(
      id: 'v2',
      name: 'No Halal Venue',
      category: VenueCategory.bakery,
      district: AstanaDistrict.esil,
      address: 'ул. Достык, 2',
      lat: 51.12,
      lng: 71.43,
      rating: 4.7,
      reviewsCount: 10,
      isHalal: false,
      halalCertStatus: HalalCertStatus.none,
      workHours: WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 22 * 60),
      phone: '+77770000000',
      photo: '',
      status: VenueStatus.approved,
    );

    test('uses 0% commission and calculates Lost Profit accurately', () {
      expect(BusinessRulesConfig.platformCommissionRate, 0.0);
      expect(BoxBusinessRules.calculateVenuePayoutPerBox(990), 990);

      final expired = [
        Box(
          id: 'exp_1',
          venueId: 'v1',
          title: 'Expired Box',
          description: 'Bakery',
          type: BoxType.surprise,
          category: BoxCategory.bakery,
          originalPrice: 3000,
          discountPrice: 1200,
          discountPercent: 60,
          quantity: 5,
          quantityLeft: 3,
          pickupWindow: PickupWindow(
            start: now.subtract(const Duration(hours: 3)),
            end: now.subtract(const Duration(hours: 1)),
          ),
          isHalal: true,
          allergens: const [],
          status: BoxStatus.expired,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ];
      // (3000 - 1200) * 3 = 5400
      expect(BoxBusinessRules.calculateLostProfit(expired), 5400);
    });

    test('matches dietary preferences properly', () {
      final box = Box(
        id: 'b_diet',
        venueId: 'v1',
        title: 'Veg Box',
        description: 'Fresh',
        type: BoxType.set,
        category: BoxCategory.bakery,
        originalPrice: 2000,
        discountPrice: 900,
        discountPercent: 55,
        quantity: 3,
        quantityLeft: 3,
        pickupWindow: PickupWindow(
          start: now.add(const Duration(hours: 3)),
          end: now.add(const Duration(hours: 4)),
        ),
        isHalal: true,
        isVegetarian: true,
        allergens: const ['Глютен'],
        status: BoxStatus.active,
        createdAt: now,
      );
      expect(
        BoxBusinessRules.matchesDietaryPreferences(
          box,
          {DietaryPreference.halalOnly, DietaryPreference.vegetarian, DietaryPreference.nutFree},
        ),
        isTrue,
      );
    });

    test('accepts valid box satisfying all rules', () {
      final violations = BoxBusinessRules.validateNewBox(
        title: 'Вечерняя выпечка',
        description: 'Слойки и круассаны',
        originalPrice: 2000,
        discountPrice: 990,
        quantity: 5,
        pickupWindow: PickupWindow(
          start: DateTime(2026, 11, 10, 19, 0),
          end: DateTime(2026, 11, 10, 20, 0),
        ),
        venue: verifiedHalalVenue,
        markAsHalal: true,
        now: now,
      );
      expect(violations, isEmpty);
    });

    test('rejects discount below 50%, short window, late publish, halal without cert, prohibited items', () {
      final violations = BoxBusinessRules.validateNewBox(
        title: 'Сет с вином и сигаретами',
        description: 'Свежее',
        originalPrice: 2000,
        discountPrice: 1200,
        quantity: 2,
        pickupWindow: PickupWindow(
          start: DateTime(2026, 11, 10, 15, 0),
          end: DateTime(2026, 11, 10, 15, 10),
        ),
        venue: unverifiedVenue,
        markAsHalal: true,
        now: now,
      );

      expect(violations, contains(BusinessRuleViolation.discountBelowMinimum));
      expect(violations, contains(BusinessRuleViolation.pickupWindowTooShort));
      expect(violations, contains(BusinessRuleViolation.publishTooLate));
      expect(violations, contains(BusinessRuleViolation.halalCertNotVerified));
      expect(violations, contains(BusinessRuleViolation.prohibitedContent));
    });

    test('computes 15-min Sprint Window (19:00-19:15 for 20:00 close) and 45-min Resale window (19:15-20:00)', () {
      const venueClosingAt20 = Venue(
        id: 'v_20',
        name: 'Sprint Bakery',
        category: VenueCategory.bakery,
        district: AstanaDistrict.esil,
        address: 'ул. Достык, 5',
        lat: 51.12,
        lng: 71.43,
        rating: 4.9,
        reviewsCount: 15,
        isHalal: true,
        halalCertStatus: HalalCertStatus.verified,
        workHours: WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 20 * 60),
        phone: '+77770000001',
        photo: '',
        status: VenueStatus.approved,
      );

      final publishNow = DateTime(2026, 11, 11, 15, 0);
      final sprint = BoxBusinessRules.calculateSprintPickupWindow(
        venueClosingAt20,
        now: publishNow,
      );
      expect(sprint.start, DateTime(2026, 11, 11, 19, 0));
      expect(sprint.end, DateTime(2026, 11, 11, 19, 15));
      expect(sprint.duration.inMinutes, 15);

      final atSprintEnd = DateTime(2026, 11, 11, 19, 15);
      final resale = BoxBusinessRules.calculateResalePickupWindow(
        venue: venueClosingAt20,
        sprintWindow: sprint,
        now: atSprintEnd,
      );
      expect(resale.start, DateTime(2026, 11, 11, 19, 15));
      expect(resale.end, DateTime(2026, 11, 11, 20, 0));
      expect(resale.duration.inMinutes, 45);
    });
  });

  group('Resale Cron Worker atomic transaction', () {
    test('marks expired RESERVED order NO_SHOW, adds +1 Strike, restores box +1 ACTIVE Resale & sorts first', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final auth = MockAuthRepository(
        AppPreferences(sp),
        SecureTokenStorage.inMemory(),
      );
      await auth.login(
        identifier: SeedData.demoUserEmail,
        password: SeedData.demoUserPassword,
      );
      final venues = MockVenueRepository(auth);
      final boxes = MockBoxRepository(HiveStorage.inMemory(), venues);
      final orders = MockOrderRepository(boxes, auth, venues);

      // Заказ #1234 на box_1 (у box_1 спринт длительностью 15 мин в +150..+165 мин от старта)
      final initialBox1 = (await boxes.getBoxById('box_1'))!;
      final qtyBefore = initialBox1.quantityLeft;
      final strikesBefore = auth.currentUser!.strikesCount;

      // CRON срабатывает ровно по окончании 15-мин окна box_1
      final workerResult = await orders.runResaleCronWorker(
        initialBox1.pickupWindow.end.add(const Duration(seconds: 5)),
      );
      expect(workerResult.hasChanges, isTrue);
      expect(workerResult.expiredOrders.first.id, 'order_active_1');
      expect(workerResult.expiredOrders.first.status, OrderStatus.noShow);

      expect(auth.currentUser!.strikesCount, strikesBefore + 1);

      final updatedBox1 = (await boxes.getBoxById('box_1'))!;
      expect(updatedBox1.quantityLeft, qtyBefore + 1);
      expect(updatedBox1.status, BoxStatus.active);
      expect(updatedBox1.isResale, isTrue);

      // Боксы с isResale == true всегда в начале каталога
      final feed = await boxes.getBoxes();
      expect(feed.first.isResale, isTrue);
      expect(feed.any((b) => b.id == 'box_1' && b.isResale), isTrue);
    });
  });

  group('MockAuthRepository security', () {
    test('registers immediately without email verification, stores JWT & enforces 5-attempt rate limit', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final tokenStorage = SecureTokenStorage.inMemory();
      final auth = MockAuthRepository(AppPreferences(sp), tokenStorage);

      final registered = await auth.register(
        name: 'Али',
        phone: '+7 (707) 111-22-33',
        email: 'ali@toidym.kz',
        password: 'Password1',
      );
      expect(registered.isVerified, isTrue);
      expect(await tokenStorage.getAccessToken(), isNotNull);

      await auth.logout();
      expect(await tokenStorage.getAccessToken(), isNull);

      final session = await auth.login(
        identifier: 'ali@toidym.kz',
        password: 'Password1',
      );
      expect(session.user.email, 'ali@toidym.kz');
      expect(await tokenStorage.getAccessToken(), isNotNull);

      await auth.logout();
      expect(await tokenStorage.getAccessToken(), isNull);

      for (var i = 0; i < BusinessRulesConfig.maxLoginAttempts; i++) {
        await expectLater(
          () => auth.login(identifier: 'ali@toidym.kz', password: 'Wrong123'),
          throwsA(isA<AuthException>()),
        );
      }
      await expectLater(
        () => auth.login(identifier: 'ali@toidym.kz', password: 'Password1'),
        throwsA(
          predicate((e) => e is AuthException && e.code == AuthErrorCode.rateLimited),
        ),
      );
    });
  });

  group('SeedData', () {
    test('provides boxes, templates, audit logs & Astana venues', () {
      final venues = SeedData.createVenues();
      final boxes = SeedData.createBoxes();
      final templates = SeedData.createTemplates();
      final auditLogs = SeedData.createAuditLogs();
      final demoUser = SeedData.createDemoUser();

      expect(venues.length, greaterThanOrEqualTo(6));
      expect(boxes.length, greaterThanOrEqualTo(12));
      expect(boxes.any((b) => b.isSoldOut), isTrue);
      expect(templates, isNotEmpty);
      expect(auditLogs, isNotEmpty);
      expect(demoUser.stats.boxesSaved, 13);
      expect(demoUser.qyzylKitap.currentAnimal, QyzylKitapAnimal.qumbek);
      expect(demoUser.qyzylKitap.boxesToNext, 2);
    });
  });

  testWidgets('ToidymApp boots into onboarding, switches language kk/ru, enters Guest home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hiveStorage = HiveStorage.inMemory();
    final tokenStorage = SecureTokenStorage.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useBackendProvider.overrideWithValue(false),
          sharedPreferencesProvider.overrideWithValue(prefs),
          hiveStorageProvider.overrideWithValue(hiveStorage),
          secureTokenStorageProvider.overrideWithValue(tokenStorage),
        ],
        child: const ToidymApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Спасай еду —\nэкономь до 70%'), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);

    await tester.tap(find.text('Қаз'));
    await tester.pumpAndSettle();
    expect(find.text('Тағамды сақта —\n70% дейін үнемде'), findsOneWidget);
    expect(find.text('Келесі'), findsOneWidget);

    await tester.tap(find.text('Өткізіп жіберу'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Шұғыл'), findsWidgets);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -320),
    );
    await tester.pump();
    expect(find.text('Вечерний бокс свежей выпечки'), findsWidgets);
  });
}
