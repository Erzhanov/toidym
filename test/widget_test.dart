import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toidym/main.dart';
import 'package:toidym/models.dart';

import 'reservation_test.dart' show MemoryPreferences;

void main() {
  testWidgets('Buyer reserves a box and the merchant hands it over', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore(MemoryPreferences());
    await tester.pumpWidget(ToidymApp(store: store));
    await tester.pumpAndSettle();

    Future<void> tap(String text) async {
      final target = find.text(text);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tap('Русский');
    expect(find.text('Начать'), findsOneWidget);
    await tap('Қазақша');
    await tap('Бастау');
    await tap('Есіл');
    expect(store.signedIn, isFalse);
    await tap('Кешкі нан боксы');
    await tap('Брондау · 1 490 ₸');

    await tester.enterText(find.byKey(const ValueKey('phone')), '7000000000');
    await tap('Демо кодты алу');
    await tester.enterText(find.byKey(const ValueKey('demo-code')), '4821');
    await tap('Растау');
    expect(find.text('Сол жерде төлеу'), findsOneWidget);
    await tap('Боксты 20:00–21:00 аралығында аламын');
    await tap('Броньды растау');

    final order = store.active.single;
    expect(find.text(order.code), findsOneWidget);
    expect(store.box(order.box.id)!.stock, demoBoxes.first.stock - 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tap('Профиль');
    await tap('Кәсіпорын режимі');
    await tap('Наубайхана демосын ашу');
    await tap('Беру');
    await tester.enterText(find.byType(TextField), order.code);
    await tester.pumpAndSettle();
    await tap('Тапсырысты беру');
    await tap('Растау');

    expect(store.active, isEmpty);
    expect(store.collected.single.code, order.code);
    await tap('Сатып алушы');
    await tap('Тапсырыстар');
    await tap('Өткен');
    await tap('Тапсырысты ашу');
    expect(find.text('Ас болсын!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
