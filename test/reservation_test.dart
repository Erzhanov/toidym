import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/models.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Reservation, cancellation and pickup preserve inventory across reloads',
    () async {
      final preferences = MemoryPreferences();
      final store = AppStore(preferences);
      final box = demoBoxes.first;
      expect(store.reserve(box.id, 1), isNull);
      store.phone = '+7 7000000000';

      expect(store.reserve(box.id, box.stock + 1), isNull);
      final reserved = store.reserve(box.id, 2)!;
      expect(store.box(box.id)!.stock, box.stock - 2);
      expect(store.collect(reserved.code, 'Other venue'), isNull);

      store.cancel(reserved);
      store.cancel(reserved);
      expect(store.box(box.id)!.stock, box.stock);

      final next = store.reserve(box.id, 1)!;
      expect(store.collect(next.code, box.shop)!.status, OrderStatus.collected);
      expect(store.collect(next.code, box.shop), isNull);
      expect(store.collected.single.savings, box.original - box.price);

      await Future<void>.delayed(Duration.zero);
      final reopened = AppStore(preferences);
      await reopened.load();
      expect(reopened.box(box.id)!.stock, box.stock - 1);
      expect(reopened.collected.single.id, next.id);
      expect(reopened.collected.single.collectedAt, isNotNull);
      expect(reopened.order(reserved.id)!.status, OrderStatus.cancelled);

      reopened.phone = '+7 7000000001';
      expect(reopened.buyerOrders, isEmpty);
    },
  );
}
