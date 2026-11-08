import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

const ink = Color(0xff2B2350);
const muted = Color(0xff5A527A);
const cream = Color(0xffFFF5DF);
const yellow = Color(0xffFFC94D);
const pale = Color(0xffFFE8A8);
const lavender = Color(0xffEFECF5);
const green = Color(0xff276349);

class Scope extends InheritedNotifier<AppStore> {
  const Scope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

extension Copy on BuildContext {
  AppStore get store => Scope.of(this);
  String tr(String ru, String kk) =>
      Localizations.localeOf(this).languageCode == 'kk' ? kk : ru;
  String boxTitle(FoodBox b) => tr(b.ru, b.kk);
  String districtName(int district) =>
      [tr('Есиль', 'Есіл'), tr('Сарыарка', 'Сарыарқа'), 'Алматы'][district];

  String categoryName(Category c) => switch (c) {
    Category.bakery => tr('Выпечка', 'Нан-тоқаш'),
    Category.hot => tr('Горячее', 'Ыстық тағам'),
    Category.coffee => tr('Кофе', 'Кофе'),
  };

  String statusName(OrderStatus status) => switch (status) {
    OrderStatus.reserved => tr('Ожидает выдачи', 'Алып кетуге дайын'),
    OrderStatus.collected => tr('Получен', 'Алынды'),
    OrderStatus.cancelled => tr('Отменён', 'Күші жойылды'),
    OrderStatus.expired => tr('Истёк', 'Мерзімі өтті'),
  };

  String pickupLabel(FoodBox box) {
    final start = box.pickupStart;
    if (start == null) return box.window;
    final astana = start.toUtc().add(const Duration(hours: 5));
    return '${MaterialLocalizations.of(this).formatShortDate(astana)} · ${box.window}';
  }
}

String money(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer ₸';
}

TextStyle heading([double size = 27]) => TextStyle(
  color: ink,
  fontSize: size,
  fontWeight: FontWeight.w900,
  height: 1.10,
  letterSpacing: size >= 25 ? -0.65 : -0.15,
);

class _WebPageTransitions extends CupertinoPageTransitionsBuilder {
  const _WebPageTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);
}

ThemeData appTheme() {
  final base = ThemeData(
    fontFamily: 'Nunito',
    platform: kIsWeb ? TargetPlatform.iOS : null,
    splashFactory: kIsWeb ? NoSplash.splashFactory : null,
    pageTransitionsTheme: kIsWeb
        ? const PageTransitionsTheme(
            builders: {TargetPlatform.iOS: _WebPageTransitions()},
          )
        : null,
    bottomSheetTheme: kIsWeb
        ? const BottomSheetThemeData(
            backgroundColor: cream,
            modalBackgroundColor: cream,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          )
        : null,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ink,
      primary: ink,
      secondary: yellow,
      surface: cream,
    ),
    scaffoldBackgroundColor: cream,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: ink,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: yellow,
        foregroundColor: ink,
        minimumSize: const Size(0, 51),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(0, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: ink, width: 2),
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(21),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = pale, this.textColor = ink});
  final String label;
  final Color color, textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.width = 62});
  final double width;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/logo.svg',
    width: width,
    semanticsLabel: 'toıdym',
  );
}

Widget art(
  String name, {
  BoxFit fit = BoxFit.contain,
  double? height,
  Alignment alignment = Alignment.center,
}) => Image.asset(
  'assets/$name.webp',
  height: height,
  fit: fit,
  alignment: alignment,
  excludeFromSemantics: true,
);

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(20),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ListView(
    padding: padding,
    keyboardDismissBehavior: kIsWeb
        ? ScrollViewKeyboardDismissBehavior.onDrag
        : null,
    children: children,
  );
}

Widget fullButton(String label, VoidCallback? action) => SizedBox(
  width: double.infinity,
  child: FilledButton(onPressed: action, child: Text(label)),
);

class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
    child: child,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
    child: Column(
      children: [
        art('bread', height: 115),
        Text(title, textAlign: TextAlign.center, style: heading(22)),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class TabsBar extends StatelessWidget {
  const TabsBar({
    super.key,
    required this.index,
    required this.items,
    required this.onChange,
  });
  final int index;
  final List<(IconData, String, int)> items;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final height = kIsWeb ? 55.0 : 51.0;
    final animated = kIsWeb && !MediaQuery.disableAnimationsOf(context);
    return BottomAction(
      child: RepaintBoundary(
        child: Material(
          color: ink,
          borderRadius: BorderRadius.circular(34),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedAlign(
                    alignment: Alignment(
                      items.length > 1 ? 2 * index / (items.length - 1) - 1 : 0,
                      0,
                    ),
                    duration: animated
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 1 / items.length,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: ShapeDecoration(
                          color: yellow,
                          shape: StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, (icon, label, count)) in items.indexed)
                        Expanded(
                          child: Semantics(
                            selected: i == index,
                            button: true,
                            label: label,
                            child: InkWell(
                              onTap: () => onChange(i),
                              borderRadius: BorderRadius.circular(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Badge(
                                    isLabelVisible: count > 0,
                                    label: Text('$count'),
                                    child: Icon(
                                      icon,
                                      size: kIsWeb ? 21 : 20,
                                      color: i == index ? ink : cream,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 11 : 10,
                                          fontWeight: FontWeight.w800,
                                          color: i == index ? ink : cream,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      kIsWeb && MediaQuery.disableAnimationsOf(context)
          ? PageRouteBuilder<T>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => page,
            )
          : MaterialPageRoute<T>(builder: (_) => page),
    );

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Widget unavailablePage(BuildContext context) => Scaffold(
  appBar: AppBar(),
  body: Center(
    child: Text(context.tr('Запись недоступна', 'Бұл жазба қолжетімсіз')),
  ),
);

String pilotMessage(BuildContext context, String code) => switch (code) {
  'invalid_code' => context.tr(
    'Код неверный или истёк',
    'Код қате немесе мерзімі өтті',
  ),
  'demo_phone' => context.tr(
    'Введите тестовый номер +7 700 000 00 XX',
    '+7 700 000 00 XX сынақ нөмірін енгізіңіз',
  ),
  'sold_out' || 'stock_changed' => context.tr(
    'Остаток изменился. Проверьте наличие.',
    'Қалдық өзгерді. Қолжетімді санын тексеріңіз.',
  ),
  'pickup_missing' => context.tr(
    'Активный заказ с этим кодом не найден',
    'Бұл кодпен белсенді тапсырыс табылмады',
  ),
  'pickup_early' => context.tr(
    'Время выдачи ещё не началось',
    'Алып кету уақыты әлі басталмады',
  ),
  'invalid_pickup' => context.tr(
    'Проверьте дату и время выдачи',
    'Алып кету күні мен уақытын тексеріңіз',
  ),
  'order_closed' => context.tr('Заказ уже закрыт', 'Тапсырыс жабылған'),
  'forbidden' || 'session_expired' || 'sign_in' => context.tr(
    'Проверьте доступ и войдите снова',
    'Құқығыңызды тексеріп, қайта кіріңіз',
  ),
  'rate_limit' => context.tr(
    'Слишком много попыток. Повторите позже.',
    'Әрекет тым көп. Кейін қайталап көріңіз.',
  ),
  'network' || 'sms_unavailable' => context.tr(
    'Сервис временно недоступен. Повторите позже.',
    'Қызмет уақытша қолжетімсіз. Кейін қайталап көріңіз.',
  ),
  'staff_conflict' => context.tr(
    'Номер уже связан с другой ролью',
    'Бұл нөмір басқа рөлге тіркелген',
  ),
  'listing_paused' => context.tr(
    'Объявление приостановлено администратором',
    'Жарияланымды әкімші тоқтатқан',
  ),
  _ => context.tr(
    'Не удалось выполнить действие. Проверьте данные.',
    'Әрекет орындалмады. Деректерді тексеріңіз.',
  ),
};

Future<bool> pilotAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on PilotError catch (error) {
    if (context.mounted) toast(context, pilotMessage(context, error.code));
    return false;
  }
}

Rect? shareOrigin(BuildContext context) {
  final object = context.findRenderObject();
  return object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : null;
}

Future<void> routeTo(BuildContext context, FoodBox box) async {
  final url = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${box.lat},${box.lng}',
  });
  if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    toast(
      context,
      context.tr('Не удалось открыть карту', 'Картаны ашу мүмкін болмады'),
    );
  }
}
