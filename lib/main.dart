import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/router/app_router.dart';
import 'package:toidym/app/theme/app_theme.dart';
import 'package:toidym/core/l10n/app_localizations.dart';
import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/storage/secure_token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hiveStorage = await HiveStorage.init();
  final tokenStorage = SecureTokenStorage();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hiveStorageProvider.overrideWithValue(hiveStorage),
        secureTokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const ToidymApp(),
    ),
  );
}

/// Корневой виджет приложения toıdym.
class ToidymApp extends ConsumerStatefulWidget {
  const ToidymApp({super.key});

  @override
  ConsumerState<ToidymApp> createState() => _ToidymAppState();
}

class _ToidymAppState extends ConsumerState<ToidymApp> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref.read(authRepositoryProvider).restoreSession(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);
    // Активирует 1-минутный CRON-воркер автоперепродажи на всё время работы приложения
    ref.watch(resaleCronProvider);

    return MaterialApp.router(
      title: 'toıdym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
