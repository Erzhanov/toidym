import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'browse.dart';
import 'admin.dart';
import 'pilot_store.dart';
import 'models.dart';
import 'ui.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final form = GlobalKey<FormState>();
  final phone = TextEditingController();
  final code = TextEditingController();
  bool verifying = false;
  bool submitting = false;

  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (submitting || !form.currentState!.validate()) return;
    final store = context.store;
    final number = '+7${phone.text.trim()}';
    setState(() => submitting = true);
    final ok = await pilotAction(
      context,
      () => verifying
          ? store.verifyCode(number, code.text)
          : store.requestCode(number),
    );
    if (!mounted) return;
    setState(() => submitting = false);
    if (!ok) return;
    if (verifying) {
      Navigator.pop(context, true);
    } else {
      setState(() => verifying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Вход', 'Кіру'), style: heading(22)),
      ),
      body: Form(
        key: form,
        child: PageBody(
          children: [
            const Icon(Icons.phone_iphone, size: 50, color: ink),
            const SizedBox(height: 20),
            Text(
              verifying
                  ? context.tr('Введите код', 'Кодты енгізіңіз')
                  : context.tr(
                      'Вход по номеру телефона',
                      'Телефон нөмірімен кіру',
                    ),
              style: heading(28),
            ),
            const SizedBox(height: 12),
            if (verifying)
              Panel(
                color: pale,
                child: Text(
                  store.demoAuth
                      ? context.tr(
                          'Демо-код: 4821. SMS не отправляется.',
                          'Демо код: 4821. SMS жіберілмейді.',
                        )
                      : context.tr(
                          'Введите код из SMS.',
                          'SMS арқылы келген кодты енгізіңіз.',
                        ),
                ),
              )
            else
              Text(
                store.connected && store.demoAuth
                    ? context.tr(
                        'Тестовые номера +7 700 000 00 XX',
                        'Сынақ нөмірлері +7 700 000 00 XX',
                      )
                    : context.tr(
                        'Войдите, чтобы сохранять брони.',
                        'Броньдарыңызды сақтау үшін кіріңіз.',
                      ),
                style: const TextStyle(color: muted),
              ),
            const SizedBox(height: 16),
            if (!verifying)
              TextFormField(
                key: const ValueKey('phone'),
                controller: phone,
                enabled: !submitting,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  prefixText: '+7 ',
                  labelText: context.tr('Номер телефона', 'Телефон нөмірі'),
                ),
                onFieldSubmitted: (_) => submit(),
                validator: (value) => value?.length == 10
                    ? null
                    : context.tr('Введите 10 цифр', '10 цифр енгізіңіз'),
              )
            else
              TextFormField(
                key: const ValueKey('demo-code'),
                controller: code,
                enabled: !submitting,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(store.demoAuth ? 4 : 10),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('Код подтверждения', 'Растау коды'),
                ),
                onFieldSubmitted: (_) => submit(),
                validator: (value) => (value?.length ?? 0) >= 4
                    ? null
                    : context.tr('Введите код', 'Кодты енгізіңіз'),
              ),
            const SizedBox(height: 16),
            fullButton(
              verifying
                  ? context.tr('Подтвердить', 'Растау')
                  : store.demoAuth
                  ? context.tr('Получить демо-код', 'Демо кодты алу')
                  : context.tr('Получить SMS', 'SMS код алу'),
              submitting ? null : submit,
            ),
            if (verifying)
              TextButton(
                onPressed: submitting
                    ? null
                    : () => setState(() {
                        code.clear();
                        verifying = false;
                      }),
                child: Text(context.tr('Изменить номер', 'Нөмірді өзгерту')),
              ),
          ],
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.id});
  final String id;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int quantity = 1;
  bool accepted = false;
  bool submitting = false;
  String? requestId;
  bool retrying = false;

  Future<void> confirm(FoodBox box) async {
    final store = context.store;
    final id = requestId ??=
        'r-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 31)}';
    setState(() => submitting = true);
    try {
      final order = await store.book(box.id, quantity, id);
      if (!mounted) return;
      if (order != null) {
        Navigator.pop(context, order);
      } else {
        toast(context, pilotMessage(context, 'sold_out'));
      }
    } on PilotError catch (error) {
      if (mounted) {
        setState(() => retrying = error.code == 'network');
        toast(context, pilotMessage(context, error.code));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = context.store.box(widget.id);
    if (box == null) return unavailablePage(context);
    final available = box.published && box.stock >= quantity;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('Оформление', 'Бронь жасау'),
          style: heading(24),
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: fullButton(
          context.tr('Подтвердить бронь', 'Броньды растау'),
          accepted && (available || retrying) && !submitting
              ? () => confirm(box)
              : null,
        ),
      ),
      body: PageBody(
        children: [
          BoxRow(box: box, favorites: false),
          const SizedBox(height: 12),
          Panel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Количество', 'Саны'),
                    style: heading(18),
                  ),
                ),
                Quantity(
                  value: quantity,
                  min: 1,
                  max: box.stock,
                  onChanged: (n) {
                    if (submitting || retrying) return;
                    setState(() {
                      quantity = n;
                      requestId = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            color: pale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Оплата на месте', 'Сол жерде төлеу'),
                        style: heading(18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          'Оплатите бокс в заведении при получении.',
                          'Боксты алған кезде төлемді сол жерде жасаңыз.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                SummaryLine(
                  context.tr('Обычная цена', 'Бастапқы баға'),
                  money(box.original * quantity),
                ),
                SummaryLine(
                  context.tr('Вы экономите', 'Үнеміңіз'),
                  money((box.original - box.price) * quantity),
                  color: green,
                ),
                const Divider(),
                SummaryLine(
                  context.tr('К оплате на месте', 'Сол жерде төленеді'),
                  money(box.price * quantity),
                  strong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: accepted,
            onChanged: (value) => setState(() => accepted = value ?? false),
            title: Text(
              context.tr(
                'Заберу бокс в ${context.pickupLabel(box)}',
                'Боксты ${context.pickupLabel(box)} аралығында аламын',
              ),
            ),
            subtitle: Text(
              context.tr(
                'Если планы изменятся, отмените бронь в заказах.',
                'Жоспарыңыз өзгерсе, броньды тапсырыстар бөлімінен жойыңыз.',
              ),
            ),
          ),
          if (!available)
            Text(
              context.tr(
                'Запас изменился. Проверьте количество.',
                'Қор өзгерді. Санын тексеріңіз.',
              ),
            ),
        ],
      ),
    );
  }
}

class Quantity extends StatelessWidget {
  const Quantity({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const ShapeDecoration(color: pale, shape: StadiumBorder()),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.tr('Уменьшить', 'Азайту'),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 19),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          tooltip: context.tr('Увеличить', 'Көбейту'),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 19),
        ),
      ],
    ),
  );
}

class SummaryLine extends StatelessWidget {
  const SummaryLine(
    this.label,
    this.value, {
    super.key,
    this.color = ink,
    this.strong = false,
  });
  final String label, value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: muted,
              fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: strong ? 17 : 14,
          ),
        ),
      ],
    ),
  );
}

class DarkHeader extends StatelessWidget {
  const DarkHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Material(
    color: ink,
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(27)),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 11, 13, 15),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: heading(26).copyWith(color: cream)),
            ),
            ?action,
          ],
        ),
      ),
    ),
  );
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool history = false;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final orders = history
        ? store.buyerOrders
              .where((o) => o.status != OrderStatus.reserved)
              .toList()
        : store.active;
    return Column(
      children: [
        DarkHeader(title: context.tr('Мои заказы', 'Тапсырыстарым')),
        Expanded(
          child: PageBody(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    selected: !history,
                    label: Text(
                      context.tr(
                        'Активные · ${store.active.length}',
                        'Белсенді · ${store.active.length}',
                      ),
                    ),
                    onSelected: (_) => setState(() => history = false),
                  ),
                  ChoiceChip(
                    selected: history,
                    label: Text(context.tr('Прошедшие', 'Өткен')),
                    onSelected: (_) => setState(() => history = true),
                  ),
                ],
              ),
              if (orders.isEmpty)
                EmptyState(
                  title: context.tr(
                    'Здесь будут ваши заказы',
                    'Тапсырыстарыңыз осы жерде көрінеді',
                  ),
                  message: context.tr(
                    'Найдите подходящий бокс рядом.',
                    'Жақын жерден өзіңізге ұнайтын бокс табыңыз.',
                  ),
                  action: fullButton(
                    context.tr('Смотреть боксы', 'Бокстарды көру'),
                    widget.onBrowse,
                  ),
                ),
              for (final order in orders)
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tag(
                          context.statusName(order.status),
                          color: order.status == OrderStatus.collected
                              ? const Color(0xffDFECD8)
                              : pale,
                        ),
                        const SizedBox(height: 8),
                        BoxRow(
                          box: order.box,
                          favorites: false,
                          onTap: () =>
                              openPage(context, OrderDetail(id: order.id)),
                        ),
                        SummaryLine(
                          context.tr('Количество', 'Саны'),
                          '${order.quantity}',
                        ),
                        SummaryLine(
                          context.tr('Сумма', 'Сома'),
                          money(order.total),
                        ),
                        fullButton(
                          context.tr('Открыть заказ', 'Тапсырысты ашу'),
                          () => openPage(context, OrderDetail(id: order.id)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class OrderDetail extends StatefulWidget {
  const OrderDetail({super.key, required this.id});
  final String id;
  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.store.order(widget.id);
    if (order == null) return unavailablePage(context);
    final box = order.box;
    if (order.status == OrderStatus.collected) return Celebration(order: order);
    final reserved = order.status == OrderStatus.reserved;
    final minutes = order.pickupStarts.difference(DateTime.now()).inMinutes;
    final pickupDate = order.pickupStarts.add(const Duration(hours: 5));
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatShortDate(pickupDate);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('Получение заказа', 'Тапсырысты алу'),
          style: heading(23),
        ),
      ),
      body: PageBody(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tag(context.statusName(order.status), color: yellow),
              Text(
                order.id,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (reserved) ...[
            Panel(
              child: Column(
                children: [
                  Semantics(
                    label: context.tr(
                      'QR-код для выдачи',
                      'Алып кетуге арналған QR код',
                    ),
                    child: QrImageView(
                      data: 'toidym:${order.code}',
                      size: 158,
                      padding: const EdgeInsets.all(5),
                    ),
                  ),
                  Text(
                    order.code,
                    style: heading(39).copyWith(letterSpacing: 4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'Покажите QR или назовите код на кассе.',
                      'Кассада QR кодты көрсетіңіз немесе кодты айтыңыз.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              color: pale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$formattedDate · ${box.window}', style: heading(19)),
                  if (minutes > 0 && minutes <= 180)
                    Text(
                      context.tr(
                        'До выдачи $minutes мин',
                        'Алып кетуге $minutes мин қалды',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(box.shop, style: heading(20)),
                const SizedBox(height: 5),
                Text(context.boxTitle(box)),
                Text('Астана, ${box.address}'),
                SummaryLine(
                  context.tr('Количество', 'Саны'),
                  '${order.quantity}',
                ),
                if (reserved)
                  SummaryLine(
                    context.tr('Оплата на месте', 'Сол жерде төлеу'),
                    money(order.total),
                  ),
                TextButton.icon(
                  onPressed: () => routeTo(context, box),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(context.tr('Маршрут', 'Бағыт')),
                ),
              ],
            ),
          ),
          if (reserved)
            TextButton(
              onPressed: () async {
                if (await confirmAction(
                      context,
                      context.tr('Отменить бронь?', 'Броньды жою керек пе?'),
                      context.tr(
                        'Бокс снова появится в списке доступных.',
                        'Бокс қайтадан қолжетімді тізімге шығады.',
                      ),
                    ) &&
                    context.mounted) {
                  await pilotAction(
                    context,
                    () => context.store.cancelBooking(order),
                  );
                }
              },
              child: Text(context.tr('Отменить бронь', 'Броньды жою')),
            ),
          TextButton(
            onPressed: () => openPage(context, IssuePage(id: order.id)),
            child: Text(
              context.tr('Проблема с заказом', 'Тапсырысқа қатысты мәселе'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String description,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Назад', 'Артқа')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Подтвердить', 'Растау')),
          ),
        ],
      ),
    ) ??
    false;

class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.order});
  final PickupOrder order;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration> {
  static const options = [
    ('Вкусно', 'Дәмді'),
    ('Много еды', 'Тағам мол'),
    ('Свежее', 'Балғын'),
    ('Вежливо', 'Сыпайы'),
  ];

  @override
  Widget build(BuildContext context) {
    final order = context.store.order(widget.order.id);
    if (order == null) return unavailablePage(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Бокс получен', 'Бокс алынды'))),
      bottomNavigationBar: BottomAction(
        child: fullButton(
          context.tr('Готово', 'Дайын'),
          () => Navigator.pop(context),
        ),
      ),
      body: PageBody(
        children: [
          art('bread', height: 157),
          const SizedBox(height: 8),
          Text('Ас болсын!', style: heading(42), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Вы спасли вкусную еду и сэкономили ${money(order.savings)}.',
              'Дәмді асты сақтап, ${money(order.savings)} үнемдедіңіз.',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Как вам бокс?', 'Бокс ұнады ма?'),
                  style: heading(20),
                ),
                Wrap(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: context.tr('Оценка $i из 5', 'Баға 5-тен $i'),
                        onPressed: () => pilotAction(
                          context,
                          () => context.store.saveReview(
                            order.copyWith(rating: i),
                          ),
                        ),
                        icon: Icon(
                          i <= order.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: ink,
                        ),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final (index, (ru, kk)) in options.indexed)
                      FilterChip(
                        selected: order.feedback.contains('$index'),
                        label: Text(context.tr(ru, kk)),
                        onSelected: (selected) => pilotAction(
                          context,
                          () => context.store.saveReview(
                            order.copyWith(
                              feedback: selected
                                  ? [...order.feedback, '$index']
                                  : order.feedback
                                        .where((f) => f != '$index')
                                        .toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: context.tr(
                  'Ас болсын! С toıdym я сэкономил(а) ${money(order.savings)}.',
                  'Ас болсын! toıdym арқылы ${money(order.savings)} үнемдедім.',
                ),
                sharePositionOrigin: shareOrigin(context),
              ),
            ),
            label: Text(context.tr('Поделиться', 'Бөлісу')),
          ),
          TextButton(
            onPressed: () => openPage(context, IssuePage(id: order.id)),
            child: Text(
              context.tr('Проблема с заказом', 'Тапсырысқа қатысты мәселе'),
            ),
          ),
        ],
      ),
    );
  }
}

class IssuePage extends StatefulWidget {
  const IssuePage({super.key, required this.id});
  final String id;

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.store.order(widget.id);
    if (order == null) return unavailablePage(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('Проблема с заказом', 'Тапсырысқа қатысты мәселе'),
        ),
      ),
      body: PageBody(
        children: [
          BoxRow(box: order.box, favorites: false),
          const SizedBox(height: 12),
          Panel(
            color: pale,
            child: Text(
              context.store.connected
                  ? context.tr(
                      'Обращение увидит администратор.',
                      'Шағымды әкімші қарайды.',
                    )
                  : context.tr(
                      'Демо: обращение сохраняется на этом устройстве.',
                      'Демо: шағым осы құрылғыда сақталады.',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (order.issue.isNotEmpty) ...[
            Panel(child: Text(order.issue)),
            if (order.resolution.isNotEmpty)
              Panel(color: pale, child: Text(order.resolution)),
          ] else ...[
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('Что случилось?', 'Не болды?'),
              ),
            ),
            const SizedBox(height: 10),
            fullButton(
              context.tr('Сохранить обращение', 'Шағымды сақтау'),
              controller.text.trim().isEmpty
                  ? null
                  : () => pilotAction(
                      context,
                      () => context.store.submitIssue(
                        order,
                        controller.text.trim(),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onMerchant});
  final VoidCallback onMerchant;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final rescued = store.collected.fold(
      0,
      (sum, order) => sum + order.quantity,
    );
    final savings = store.collected.fold(
      0,
      (sum, order) => sum + order.savings,
    );
    return Column(
      children: [
        DarkHeader(title: context.tr('Профиль', 'Профиль')),
        Expanded(
          child: PageBody(
            children: [
              if (!store.signedIn)
                Panel(
                  color: pale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'Войдите и спасайте',
                          'Кіріп, тағамды сақтаңыз',
                        ),
                        style: heading(23),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          'История заказов, избранные места и ваша экономия.',
                          'Тапсырыстар тарихы, таңдаулы орындар және үнеміңіз.',
                        ),
                      ),
                      const SizedBox(height: 10),
                      fullButton(
                        context.tr('Войти', 'Кіру'),
                        () => openPage(context, const SignInPage()),
                      ),
                    ],
                  ),
                )
              else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: ink,
                    foregroundColor: yellow,
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(store.phone, style: heading(20)),
                ),
                Panel(
                  color: pale,
                  child: Column(
                    children: [
                      SummaryLine(
                        context.tr('Спасено боксов', 'Сақталған бокстар'),
                        '$rescued',
                        strong: true,
                      ),
                      SummaryLine(
                        context.tr('Сэкономлено', 'Үнемделді'),
                        money(savings),
                        strong: true,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Panel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(
                    context.tr('Избранные заведения', 'Таңдаулы орындар'),
                  ),
                  trailing: Text('${store.favorites.length}'),
                  onTap: () => openPage(context, const FavoritesPage()),
                ),
              ),
              const SizedBox(height: 10),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Язык приложения', 'Қолданба тілі'),
                      style: heading(19),
                    ),
                    const LanguageChoice(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        'Астана · ${context.districtName(store.district)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final district = await chooseDistrict(context);
                        if (district != null && context.mounted) {
                          store
                            ..district = district
                            ..save();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Panel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(
                    context.tr('Режим заведения', 'Кәсіпорын режимі'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onMerchant,
                ),
              ),
              if (store is PilotStore && store.admin)
                Panel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(context.tr('Админ-панель', 'Админ панель')),
                    onTap: () => openPage(context, AdminPage(store: store)),
                  ),
                ),
              if (store.signedIn)
                TextButton(
                  onPressed: store.signOut,
                  child: Text(context.tr('Выйти', 'Шығу')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Избранное', 'Таңдаулылар'))),
      body: PageBody(
        children: [
          if (store.favorites.isEmpty)
            EmptyState(
              title: context.tr('Пока ничего нет', 'Әзірге бос'),
              message: context.tr(
                'Нажмите на сердечко рядом с боксом.',
                'Бокстың жанындағы жүрекшені басыңыз.',
              ),
            ),
          for (final shop in store.favorites) ...[
            Row(
              children: [
                Expanded(child: Text(shop, style: heading(19))),
                FavoriteButton(shop: shop),
              ],
            ),
            for (final box in store.boxes.where(
              (b) => b.shop == shop && b.published && b.stock > 0,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BoxRow(
                  box: box,
                  favorites: false,
                  onTap: () => openPage(context, BoxDetail(id: box.id)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
