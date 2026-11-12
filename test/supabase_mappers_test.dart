import 'package:flutter_test/flutter_test.dart';
import 'package:toidym/core/config/app_config.dart';
import 'package:toidym/core/network/api_client.dart';
import 'package:toidym/data/repositories/supabase_repositories.dart';
import 'package:toidym/shared/models/enums.dart';

void main() {
  group('AppConfig defaults', () {
    test('defaults to live Supabase backend using Lovable Cloud credentials', () {
      expect(AppConfig.useBackend, isTrue);
      expect(AppConfig.isBackendConfigured, isTrue);
      expect(AppConfig.effectiveBaseUrl, AppConfig.supabaseUrl);
      expect(AppConfig.supabaseProjectId, 'kpmknrlltuzmilvtlshg');
      expect(AppConfig.supabaseUrl, startsWith('https://'));
      expect(AppConfig.supabaseAnonKey, startsWith('sb_publishable_'));
    });
  });

  group('SupabaseMappers PostgreSQL row mapping', () {
    test('maps profile row accurately into User with Qyzyl Kitap progress', () {
      final user = SupabaseMappers.userFromRow({
        'id': 'u-123',
        'email': 'buyer@toidym.kz',
        'phone': '+7 701 111 2233',
        'name': 'Айдана',
        'role': 'USER',
        'language': 'kk',
        'is_verified': true,
        'is_first_login': false,
        'dietary_preferences': ['halal_only'],
        'strikes_count': 2,
        'boxes_saved': 16,
        'co2_saved_kg': 20.0,
        'money_saved_kzt': 24000,
      });

      expect(user.id, 'u-123');
      expect(user.role, UserRole.buyer);
      expect(user.language, AppLanguage.kk);
      expect(user.strikesCount, 2);
      expect(user.stats.boxesSaved, 16);
      expect(user.stats.kgSaved, 20.0);
      expect(user.stats.moneySaved, 24000);
      expect(user.qyzylKitap.currentAnimal, QyzylKitapAnimal.irbis);
      expect(user.dietaryPreferences, {DietaryPreference.halalOnly});
    });

    test('maps resale box row with sprint window and discount percent', () {
      final box = SupabaseMappers.boxFromRow({
        'id': 'b-1',
        'venue_id': 'v-1',
        'title': 'Last Minute Плов',
        'description': 'Свежий плов',
        'type': 'surprise',
        'category': 'hot_food',
        'original_price': 4000,
        'discount_price': 1500,
        'discount_percent': 63,
        'quantity': 5,
        'quantity_left': 1,
        'pickup_start': '2026-11-12T14:15:00Z',
        'pickup_end': '2026-11-12T15:00:00Z',
        'is_halal': true,
        'is_vegetarian': false,
        'is_resale': true,
        'allergens': ['Глютен'],
        'status': 'ACTIVE',
        'created_at': '2026-11-12T13:00:00Z',
        'photos': ['https://example.com/1.jpg'],
        'repeat_weekdays': [1, 3, 5],
      });

      expect(box.isResale, isTrue);
      expect(box.status, BoxStatus.active);
      expect(box.quantityLeft, 1);
      expect(box.discountPercent, 63);
      expect(box.pickupWindow.duration.inMinutes, 45);
    });

    test('maps order row including NO_SHOW and complaint metadata', () {
      final order = SupabaseMappers.orderFromRow({
        'id': 'o-1',
        'order_number': '#900111',
        'user_id': 'u-123',
        'box_id': 'b-1',
        'venue_id': 'v-1',
        'quantity': 1,
        'total_price': 1500,
        'original_total_price': 4000,
        'status': 'NO_SHOW',
        'qr_code': 'TOIDYM-123',
        'pin_code': '4512',
        'payment_method': 'on_site',
        'cancellation_reason': 'Автоотмена: время выдачи (15 мин Спринт) истекло',
        'created_at': '2026-11-12T13:30:00Z',
        'is_charity_box': false,
      });

      expect(order.status, OrderStatus.noShow);
      expect(order.pinCode, '4512');
      expect(order.paymentMethod, PaymentMethod.onSite);
    });

    test('maps must_change_password flag and numeric venue district safely', () {
      final partner = SupabaseMappers.userFromRow({
        'id': 'p-1',
        'email': 'partner@toidym.kz',
        'role': 'PARTNER',
        'is_first_login': false,
        'must_change_password': true,
      });
      final venue = SupabaseMappers.venueFromRow({
        'id': 'v-1',
        'name': 'Tary',
        'district': 0,
        'category': 'bakery',
        'status': 'APPROVED',
      });

      expect(partner.role, UserRole.partner);
      expect(partner.isFirstLogin, isTrue);
      expect(venue.district, AstanaDistrict.esil);
    });

    test('maps partner_applications row, is_blocked venue, and clean ApiException message', () {
      final appVenue = SupabaseMappers.venueFromRow({
        'id': 'pa_123',
        'venue_name': 'Qazaq Coffee',
        'address': 'пр. Мангилик Ел, 10',
        'district': 2,
        'phone': '+7 (701) 555-12-34',
        'contact_name': 'owner@coffee.kz',
        'notes': 'category=coffee',
        'status': 'pending',
      });
      final blockedVenue = SupabaseMappers.venueFromRow({
        'id': 'v-blocked',
        'name': 'Blocked Spot',
        'status': 'approved',
        'is_blocked': true,
      });
      const err = ApiException(message: 'Понятная ошибка', statusCode: 400);

      expect(appVenue.name, 'Qazaq Coffee');
      expect(appVenue.district, AstanaDistrict.saryarka);
      expect(appVenue.category, VenueCategory.coffee);
      expect(appVenue.status, VenueStatus.pending);
      expect(appVenue.rejectionComment, 'Email: owner@coffee.kz');
      expect(blockedVenue.status, VenueStatus.banned);
      expect(err.toString(), 'Понятная ошибка');
    });
  });
}
