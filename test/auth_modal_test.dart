import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/core/l10n/app_localizations.dart';
import 'package:toidym/core/storage/app_preferences.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/data/repositories/mock_auth_repository.dart';
import 'package:toidym/features/auth/presentation/auth_modal_screen.dart';

void main() {
  testWidgets(
    'AuthModalScreen in backend mode starts with empty fields, Email label, and shows error banner',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final hiveStorage = HiveStorage.inMemory();
      final tokenStorage = SecureTokenStorage.inMemory();
      final mockAuth = MockAuthRepository(AppPreferences(prefs), tokenStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            useBackendProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
            hiveStorageProvider.overrideWithValue(hiveStorage),
            secureTokenStorageProvider.overrideWithValue(tokenStorage),
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            locale: Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: AuthModalScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In production backend mode, demo email/password must not be prefilled and demo chips are hidden.
      expect(find.text(SeedData.demoUserEmail), findsNothing);
      expect(find.text('Быстрый вход (демо-роли)'), findsNothing);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Забыли пароль?'), findsOneWidget);

      // Switch to registration tab and submit with empty name -> dedicated error banner shows localized message.
      await tester.tap(find.text('Регистрация').first);
      await tester.pumpAndSettle();

      expect(find.text('+7 (701) '), findsNothing);

      final submitBtn = find.widgetWithText(ElevatedButton, 'Регистрация');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Введите ваше имя'), findsOneWidget);
    },
  );
}
