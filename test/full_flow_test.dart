import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/main.dart';
import 'package:toidym/shared/widgets/empty_state.dart';
import 'package:toidym/shared/widgets/error_state.dart';
import 'package:toidym/shared/widgets/qumbek_mascot.dart';

Future<ProviderScope> _buildTestApp({
  bool onboardingDone = false,
  String? preAuthenticatedUserId,
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboardingDone) 'toidym_onboarding_done': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final hiveStorage = HiveStorage.inMemory();
  final tokenStorage = SecureTokenStorage.inMemory();

  if (preAuthenticatedUserId != null) {
    await tokenStorage.saveSession(
      accessToken: 'jwt_access_$preAuthenticatedUserId',
      refreshToken: 'jwt_refresh_$preAuthenticatedUserId',
      userId: preAuthenticatedUserId,
    );
  }

  return ProviderScope(
    overrides: [
      useBackendProvider.overrideWithValue(false),
      sharedPreferencesProvider.overrideWithValue(prefs),
      hiveStorageProvider.overrideWithValue(hiveStorage),
      secureTokenStorageProvider.overrideWithValue(tokenStorage),
    ],
    child: const ToidymApp(),
  );
}

Future<void> _pumpUntilSettledShort(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pump();
}

void main() {
  testWidgets(
    'Full E2E buyer path: guest -> auth -> offline warning -> RESERVED -> QR -> pickup -> Ас болсын!',
    (tester) async {
      await tester.pumpWidget(await _buildTestApp());
      await tester.pumpAndSettle();

      // 1. Онбординг и переход в каталог гостя
      expect(find.text('Спасай еду —\nэкономь до 70%'), findsOneWidget);
      await tester.tap(find.text('Пропустить'));
      await _pumpUntilSettledShort(tester);

      // 2. Главная: блок «Забрать сейчас» и список боксов
      expect(find.text('Забрать сейчас'), findsWidgets);
      expect(find.text('Tary Bakery'), findsWidgets);

      // 3. Карточка бокса (гость) — скроллим к карточке в вертикальной ленте
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -320),
      );
      await tester.pump();
      expect(find.text('Вечерний бокс свежей выпечки'), findsWidgets);
      await tester.ensureVisible(
        find.text('Вечерний бокс свежей выпечки').last,
      );
      await tester.pump();
      await tester.tap(find.text('Вечерний бокс свежей выпечки').last);
      await _pumpUntilSettledShort(tester);
      await tester.scrollUntilVisible(
        find.text('Что обычно внутри'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Что обычно внутри'), findsOneWidget);

      // 4. «Забронировать» открывает Email+Пароль авторизацию для гостя
      await tester.tap(find.textContaining('Забронировать за'));
      await _pumpUntilSettledShort(tester);
      expect(find.text('Вход в toıdym'), findsOneWidget);

      final loginBtn = find.widgetWithText(ElevatedButton, 'Войти').first;
      await tester.ensureVisible(loginBtn);
      await tester.pump();
      await tester.tap(loginBtn);
      await _pumpUntilSettledShort(tester);

      // 5. Предупреждающая шторка офлайн-брони (Trust Booking + 3 Strikes)
      expect(find.text('Оплата при получении (Trust Booking)'), findsOneWidget);
      final acceptWarnBtn = find.text('Понимаю, забронировать');
      await tester.ensureVisible(acceptWarnBtn);
      await tester.pump();
      await tester.tap(acceptWarnBtn);
      await _pumpUntilSettledShort(tester);

      // 6. Экран подтверждения офлайн-брони (/checkout/:boxId)
      expect(find.text('Подтверждение брони'), findsOneWidget);
      expect(find.text('Оплата при получении'), findsOneWidget);

      final confirmReserveBtn = find.textContaining('Забронировать за');
      await tester.ensureVisible(confirmReserveBtn);
      await tester.pump();
      await tester.tap(confirmReserveBtn);
      await _pumpUntilSettledShort(tester);

      // 7. Активный заказ с QR и PIN
      expect(find.text('Покажите QR или назовите код на кассе'), findsOneWidget);

      // Выдача заказа со стороны заведения -> автопереход к «Ас болсын!»
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Navigator).first),
      );
      final ordersNow =
          container.read(ordersStreamProvider).valueOrNull ?? const [];
      final activeOrder = ordersNow.firstWhere((o) => o.status.isActive);
      final pickupFuture = container.read(orderRepositoryProvider).completePickup(
            venueId: activeOrder.venueId,
            qrCode: activeOrder.qrCode,
          );
      await _pumpUntilSettledShort(tester);
      await pickupFuture;
      await _pumpUntilSettledShort(tester);

      // 8. Экран «Ас болсын!»
      expect(find.text('Ас болсын!'), findsOneWidget);
      expect(find.byType(ConfettiWidget), findsOneWidget);
      expect(find.byType(QumbekMascot), findsOneWidget);
      expect(find.textContaining('14 из 15 боксов'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Готово'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Готово'));
      await _pumpUntilSettledShort(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'Partner flow: templates & discount rule; Cashier Custom Numpad wrong & valid PIN',
    (tester) async {
      await tester.pumpWidget(
        await _buildTestApp(
          onboardingDone: true,
          preAuthenticatedUserId: SeedData.demoPartnerId,
        ),
      );
      await _pumpUntilSettledShort(tester);

      // Переключаемся в кабинет магазина через Профиль
      await tester.tap(find.text('Профиль'));
      await _pumpUntilSettledShort(tester);
      await tester.scrollUntilVisible(
        find.text('Режим заведения'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Режим заведения'));
      await tester.pump();
      await tester.tap(find.text('Режим заведения'));
      await _pumpUntilSettledShort(tester);

      // Вкладки Бүгінгі и Мұрағат (Архив)
      expect(find.text('Tary Bakery'), findsOneWidget);
      expect(find.textContaining('Бүгінгі'), findsOneWidget);
      expect(find.textContaining('Мұрағат'), findsOneWidget);

      // Переход в «Новый бокс» — карусель шаблонов и валидация скидки <50%
      await tester.tap(find.text('Новый бокс'));
      await _pumpUntilSettledShort(tester);
      expect(find.text('Менің шаблондарым (в 1 клик)'), findsOneWidget);

      final discountPriceField = find.widgetWithText(
        TextField,
        'Цена в toıdym (₸)',
      );
      await tester.scrollUntilVisible(
        discountPriceField,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(discountPriceField);
      await tester.pump();
      await tester.enterText(discountPriceField, '1800');
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Скидка меньше 50% — публикация невозможна'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Скидка меньше 50% — публикация невозможна'),
        findsOneWidget,
      );

      // Выход из партнёрского режима и вход под Кассиром
      await tester.tap(find.byType(BackButton));
      await _pumpUntilSettledShort(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await _pumpUntilSettledShort(tester);
      final settingsScroll = find
          .descendant(
            of: find.byKey(const ValueKey('venue_settings_list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Выйти'),
        250,
        scrollable: settingsScroll,
      );
      await tester.ensureVisible(find.text('Выйти'));
      await tester.pump();
      await tester.tap(find.text('Выйти'));
      await _pumpUntilSettledShort(tester);

      await tester.tap(find.text('Войти').first);
      await _pumpUntilSettledShort(tester);
      await tester.scrollUntilVisible(
        find.text('Кассир'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Кассир'));
      await _pumpUntilSettledShort(tester);

      // Кассир видит только экран «Выдача заказов» с Custom Numpad без нижней панели
      expect(find.text('Выдача заказов'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Введите 4-значный PIN заказа'), findsOneWidget);

      // Вводим неверный PIN 9999 на Custom Numpad -> красная ошибка
      final digit9 = find.byKey(const ValueKey('numpad_digit_9'));
      await tester.scrollUntilVisible(
        digit9,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(digit9);
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.tap(digit9);
        await tester.pump();
      }
      await _pumpUntilSettledShort(tester);
      await tester.ensureVisible(
        find.text('Неверный PIN-код или заказ не найден'),
      );
      expect(find.text('Неверный PIN-код или заказ не найден'), findsOneWidget);
    },
  );

  testWidgets('Home shows ErrorState with retry and EmptyState with Qumbek', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildTestApp(onboardingDone: true));
    await _pumpUntilSettledShort(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(boxRepositoryProvider).simulateNextFetchError();
    container.invalidate(boxesFeedProvider);
    await _pumpUntilSettledShort(tester);

    expect(find.byType(ErrorState), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await _pumpUntilSettledShort(tester);
    expect(find.text('Tary Bakery'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'несуществующий_999');
    await _pumpUntilSettledShort(tester);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(QumbekMascot), findsOneWidget);
  });

  testWidgets('Profile dietary settings, 3 Strikes badge, Qyzyl Kitap & Orders tabs work', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _buildTestApp(
        onboardingDone: true,
        preAuthenticatedUserId: SeedData.demoUserId,
      ),
    );
    await _pumpUntilSettledShort(tester);

    await tester.tap(find.text('Профиль'));
    await _pumpUntilSettledShort(tester);
    expect(find.text('Нарушений: 0 из 3'), findsOneWidget);
    expect(find.text('Мои фильтры питания'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pump();
    await tester.ensureVisible(find.text('Қызыл кітап'));
    await tester.pump();
    await tester.tap(find.text('Қызыл кітап'));
    await _pumpUntilSettledShort(tester);

    expect(find.text('Ирбис'), findsOneWidget);
    expect(find.text('Сайгак'), findsOneWidget);
    expect(find.text('Тюлень'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await _pumpUntilSettledShort(tester);
    await tester.tap(find.text('Заказы'));
    await _pumpUntilSettledShort(tester);
    expect(find.textContaining('Активные'), findsOneWidget);
    expect(find.textContaining('Прошедшие'), findsOneWidget);
  });

  testWidgets(
    'Admin panel: 0% KPI, forced password on lead approve, box moderation, Strikes & AuditLogs',
    (tester) async {
      await tester.pumpWidget(await _buildTestApp());
      await tester.pumpAndSettle();

      // Вход под Администратором через модалку авторизации
      await tester.tap(find.text('Пропустить'));
      await _pumpUntilSettledShort(tester);
      await tester.tap(find.text('Войти'));
      await _pumpUntilSettledShort(tester);
      await tester.scrollUntilVisible(
        find.text('Администратор'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Администратор'));
      await _pumpUntilSettledShort(tester);

      // 1. Сводка администратора (без комиссии)
      expect(find.text('Админ-панель · Сводка'), findsOneWidget);
      expect(find.text('Без комиссии (0%)'), findsOneWidget);
      expect(find.text('Оборот (GMV)'), findsOneWidget);

      // 2. Модерация магазинов, одобрение лида с выдачей временного пароля
      await tester.tap(find.text('Магазины').last);
      await _pumpUntilSettledShort(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'На проверке'));
      await tester.pump();
      expect(find.text('Baursak Lab'), findsOneWidget);

      await tester.ensureVisible(find.text('Одобрить магазин').first);
      await tester.pump();
      await tester.tap(find.text('Одобрить магазин').first);
      await _pumpUntilSettledShort(tester);

      // Закрываем диалог с временным паролем
      expect(find.textContaining('Временный пароль:'), findsOneWidget);
      await tester.tap(find.text('Готово'));
      await _pumpUntilSettledShort(tester);

      // 3. Каталог боксов и скрытие
      await tester.tap(find.text('Боксы').last);
      await _pumpUntilSettledShort(tester);
      expect(find.text('Вечерний бокс свежей выпечки'), findsOneWidget);

      await tester.tap(find.text('Снять с публикации').first);
      await _pumpUntilSettledShort(tester);
      expect(find.text('Вернуть в продажу'), findsOneWidget);

      // 4. Жалобы, Strikes и AuditLogs
      await tester.tap(find.text('Жалобы').last);
      await _pumpUntilSettledShort(tester);
      expect(
        find.text('В боксе не оказалось гарнира, только манты.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Закрыть с ответом'));
      await _pumpUntilSettledShort(tester);
      await tester.tap(find.text('Сохранить'));
      await _pumpUntilSettledShort(tester);

      await tester.tap(find.textContaining('Strikes и Баны'));
      await _pumpUntilSettledShort(tester);
      expect(find.text('Снять бан'), findsOneWidget);
      await tester.tap(find.text('Снять бан'));
      await _pumpUntilSettledShort(tester);

      await tester.tap(find.textContaining('Аудит (AuditLogs)'));
      await _pumpUntilSettledShort(tester);
      expect(find.textContaining('UNBAN_USER'), findsWidgets);
      expect(find.textContaining('HIDE_BOX'), findsWidgets);
    },
  );

  testWidgets(
    '15-min Sprint timeout triggers Resale Worker, shows ErrorState and promotes box to top with Resale badge',
    (tester) async {
      await tester.pumpWidget(
        await _buildTestApp(
          onboardingDone: true,
          preAuthenticatedUserId: SeedData.demoUserId,
        ),
      );
      await _pumpUntilSettledShort(tester);

      // Переход в активный заказ #1234 -> живой 15-мин спринт-таймер
      await tester.tap(find.text('Заказы'));
      await _pumpUntilSettledShort(tester);
      await tester.tap(find.text('Открыть QR'));
      await _pumpUntilSettledShort(tester);

      expect(find.textContaining('15-мин Спринт:'), findsOneWidget);

      // Истечение 15-минутного спринта (00:00 -> Resale Worker)
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Navigator).first),
      );
      final ordersNow =
          container.read(ordersStreamProvider).valueOrNull ?? const [];
      final activeOrder = ordersNow.firstWhere((o) => o.status.isActive);
      final expireFuture = container
          .read(resaleCronProvider.notifier)
          .expireOrderSprint(activeOrder.id, DateTime.now());
      await _pumpUntilSettledShort(tester);
      await expireFuture;
      await _pumpUntilSettledShort(tester);

      // На месте открывается ErrorState с сообщением о перепродаже
      expect(
        find.text(
          'Извините, вы не успели. Заказ выставлен на перепродажу другим пользователям',
        ),
        findsOneWidget,
      );

      // Возвращаемся в каталог и проверяем бокс +1 на перепродаже с бейджем «Срочно»
      await tester.tap(find.text('Повторить'));
      await _pumpUntilSettledShort(tester);
      expect(find.text('Срочно'), findsWidgets);
    },
  );
}
