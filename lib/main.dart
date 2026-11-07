import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browse.dart';
import 'merchant.dart';
import 'models.dart';
import 'orders.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(SharedPreferencesAsync());
  await store.load();
  runApp(ToidymApp(store: store));
}

class ToidymApp extends StatefulWidget {
  const ToidymApp({super.key, required this.store});
  final AppStore store;

  @override
  State<ToidymApp> createState() => _ToidymAppState();
}

class _ToidymAppState extends State<ToidymApp> {
  final theme = appTheme();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.store.language,
    builder: (context, kazakh, _) => MaterialApp(
      title: 'toıdym',
      debugShowCheckedModeBanner: false,
      locale: Locale(kazakh ? 'kk' : 'ru'),
      supportedLocales: const [Locale('kk'), Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      builder: (context, child) => Scope(
        store: widget.store,
        child: ColoredBox(
          color: lavender,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: child,
            ),
          ),
        ),
      ),
      home: const Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  bool merchant = false;
  void select(int index) => setState(() => tab = index);

  void switchMode() {
    setState(() {
      merchant = !merchant;
      tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    if (merchant) return MerchantShell(onExit: switchMode);
    if (!store.onboarded) return WelcomePage(onMerchant: switchMode);
    return Scaffold(
      body: switch (tab) {
        0 || 1 => BrowsePage(
          showMap: tab == 1,
          onToggle: () => select(tab == 0 ? 1 : 0),
        ),
        2 => OrdersPage(onBrowse: () => select(0)),
        _ => ProfilePage(onMerchant: switchMode),
      },
      bottomNavigationBar: TabsBar(
        index: tab,
        onChange: select,
        items: [
          (Icons.inventory_2_outlined, context.tr('Боксы', 'Бокстар'), 0),
          (Icons.map_outlined, context.tr('Карта', 'Карта'), 0),
          (
            Icons.receipt_long_outlined,
            context.tr('Заказы', 'Тапсырыстар'),
            store.active.length,
          ),
          (Icons.person_outline, context.tr('Профиль', 'Профиль'), 0),
        ],
      ),
    );
  }
}
