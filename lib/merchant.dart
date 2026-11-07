import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'browse.dart';
import 'models.dart';
import 'orders.dart';
import 'ui.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key, required this.onExit});
  final VoidCallback onExit;

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int tab = 0;
  bool demo = false;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final shop = demo ? 'Таңғы нан' : store.venue;
    final ready = demo || store.venueStatus == 'approved';
    final boxes = store.boxes
        .where((b) => b.merchant && b.shop == shop)
        .toList();
    final orders = store.orders
        .where((o) => o.box.merchant && o.box.shop == shop)
        .toList();
    final waiting = orders
        .where((o) => o.status == OrderStatus.reserved)
        .toList();
    final completed = orders
        .where((o) => o.status == OrderStatus.collected)
        .toList();

    if (!ready) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Для заведений', 'Кәсіпорындарға')),
          leading: IconButton(
            onPressed: widget.onExit,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PageBody(
          children: [
            art('bread', height: 145),
            Text(
              context.tr(
                'Продавайте остатки дня',
                'Күн соңында қалған асты сатыңыз',
              ),
              style: heading(31),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(
                'Публикуйте боксы и выдавайте их по коду.',
                'Бокстарды жариялап, кодпен беріңіз.',
              ),
            ),
            const SizedBox(height: 18),
            if (store.venueStatus == 'review') ...[
              Panel(
                color: pale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(context.tr('На проверке', 'Тексеріліп жатыр')),
                    const SizedBox(height: 8),
                    Text(store.venue, style: heading(21)),
                    const SizedBox(height: 5),
                    Text(
                      context.tr(
                        'Демо-заявка хранится на этом устройстве.',
                        'Демо өтінім осы құрылғыда сақталады.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              fullButton(
                context.tr('Одобрить в демо', 'Демода мақұлдау'),
                () => store
                  ..venueStatus = 'approved'
                  ..save(),
              ),
            ] else
              fullButton(
                context.tr('Стать партнёром', 'Серіктес болу'),
                () => openPage(context, const VenueApplication()),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => setState(() => demo = true),
              child: Text(
                context.tr('Открыть демо пекарни', 'Наубайхана демосын ашу'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          DarkHeader(
            title: switch (tab) {
              1 => context.tr('Выдача', 'Беру'),
              2 => context.tr('Итоги', 'Қорытынды'),
              _ => shop,
            },
            action: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: yellow),
              onPressed: widget.onExit,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(context.tr('Покупатель', 'Сатып алушы')),
            ),
          ),
          Expanded(
            child: switch (tab) {
              1 => PickupPage(shop: shop, waiting: waiting),
              2 => MerchantStats(orders: completed),
              _ => PageBody(
                children: [
                  Panel(
                    color: pale,
                    child: Column(
                      children: [
                        SummaryLine(
                          context.tr('Выдано боксов', 'Берілген бокстар'),
                          '${completed.fold(0, (total, order) => total + order.quantity)}',
                          strong: true,
                        ),
                        SummaryLine(
                          context.tr('Ждут выдачи', 'Алып кетуді күтуде'),
                          '${waiting.length}',
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  fullButton(
                    context.tr('+ Новый бокс', '+ Жаңа бокс'),
                    () => openPage(
                      context,
                      NewBoxPage(
                        shop: shop,
                        address: demo
                            ? demoBoxes.first.address
                            : store.venueAddress,
                        district: demo ? 0 : store.venueDistrict,
                        demo: demo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('Боксы сегодня', 'Бүгінгі бокстар'),
                    style: heading(24),
                  ),
                  const SizedBox(height: 10),
                  if (boxes.isEmpty)
                    EmptyState(
                      title: context.tr('Пока нет боксов', 'Әзірге бокс жоқ'),
                      message: context.tr(
                        'Добавьте первый бокс, чтобы он появился в каталоге.',
                        'Каталогта көрінуі үшін алғашқы боксты қосыңыз.',
                      ),
                    ),
                  for (final box in boxes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        child: Column(
                          children: [
                            BoxRow(box: box, favorites: false),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(context.tr('В продаже', 'Сатылымда')),
                              value: box.published,
                              onChanged: (value) => store.upsertBox(
                                box.copyWith(published: value),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.tr('Осталось', 'Қалды'),
                                    style: heading(16),
                                  ),
                                ),
                                Quantity(
                                  value: box.stock,
                                  min: 0,
                                  max: 99,
                                  onChanged: (value) => store.upsertBox(
                                    box.copyWith(stock: value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: TabsBar(
        index: tab,
        onChange: (value) => setState(() => tab = value),
        items: [
          (Icons.inventory_2_outlined, context.tr('Боксы', 'Бокстар'), 0),
          (Icons.qr_code_scanner, context.tr('Выдача', 'Беру'), waiting.length),
          (Icons.bar_chart, context.tr('Итоги', 'Қорытынды'), 0),
        ],
      ),
    );
  }
}

class VenueApplication extends StatefulWidget {
  const VenueApplication({super.key});

  @override
  State<VenueApplication> createState() => _VenueApplicationState();
}

class _VenueApplicationState extends State<VenueApplication> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final address = TextEditingController();
  final company = TextEditingController();
  int district = 0;
  bool agreed = false;

  @override
  void dispose() {
    title.dispose();
    address.dispose();
    company.dispose();
    super.dispose();
  }

  Widget field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: TextFormField(
      controller: controller,
      maxLength: 65,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.tr('Обязательное поле', 'Міндетті өріс');
        }
        if (controller == title && value.trim() == 'Таңғы нан') {
          return context.tr(
            'Это имя демо-пекарни',
            'Бұл демо наубайхананың атауы',
          );
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Заявка заведения', 'Кәсіпорын өтінімі')),
    ),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          Text(
            context.tr('1 · Заведение', '1 · Кәсіпорын'),
            style: heading(22),
          ),
          field(title, context.tr('Название', 'Атауы')),
          const SizedBox(height: 18),
          Text(
            context.tr('2 · Адрес в Астане', '2 · Астанадағы мекенжай'),
            style: heading(22),
          ),
          field(
            address,
            context.tr('Улица и номер дома', 'Көше мен үй нөмірі'),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < districtPoints.length; i++)
                ChoiceChip(
                  label: Text(context.districtName(i)),
                  selected: district == i,
                  onSelected: (_) => setState(() => district = i),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('3 · Юридические данные', '3 · Заңды деректер'),
            style: heading(22),
          ),
          field(
            company,
            context.tr(
              'Название компании (тестовое)',
              'Компания атауы (сынақ)',
            ),
          ),
          const SizedBox(height: 18),
          Text(context.tr('4 · Условия', '4 · Шарттар'), style: heading(22)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: agreed,
            title: Text(
              context.tr(
                'Свежие продукты, самовывоз и скидка от 50%.',
                'Балғын өнім, өзіңіз алып кету және кемінде 50% жеңілдік.',
              ),
            ),
            onChanged: (value) => setState(() => agreed = value ?? false),
          ),
          const SizedBox(height: 10),
          fullButton(
            context.tr('Сохранить демо-заявку', 'Демо өтінімді сақтау'),
            agreed
                ? () {
                    if (!form.currentState!.validate()) return;
                    context.store
                      ..venue = title.text.trim()
                      ..venueAddress = address.text.trim()
                      ..venueDistrict = district
                      ..venueStatus = 'review'
                      ..save();
                    Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    ),
  );
}

class NewBoxPage extends StatefulWidget {
  const NewBoxPage({
    super.key,
    required this.shop,
    required this.address,
    required this.district,
    required this.demo,
  });
  final String shop, address;
  final int district;
  final bool demo;

  @override
  State<NewBoxPage> createState() => _NewBoxPageState();
}

class _NewBoxPageState extends State<NewBoxPage> {
  final form = GlobalKey<FormState>();
  final titleRu = TextEditingController();
  final titleKk = TextEditingController();
  final contents = TextEditingController();
  final price = TextEditingController();
  final original = TextEditingController();
  Category category = Category.bakery;
  TimeOfDay start = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 21, minute: 0);
  int quantity = 1;

  @override
  void dispose() {
    for (final controller in [titleRu, titleKk, contents, price, original]) {
      controller.dispose();
    }
    super.dispose();
  }

  String time(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  int minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> preview() async {
    if (!form.currentState!.validate()) return;
    final originalPrice = int.parse(original.text);
    final newPrice = int.parse(price.text);
    if (newPrice * 2 > originalPrice) {
      toast(
        context,
        context.tr(
          'Скидка должна быть не меньше 50%.',
          'Жеңілдік кемінде 50% болуы керек.',
        ),
      );
      return;
    }
    if (minutes(end) - minutes(start) < 30) {
      toast(
        context,
        context.tr(
          'Окно выдачи должно длиться от 30 минут.',
          'Алып кету аралығы кемінде 30 минут болуы керек.',
        ),
      );
      return;
    }
    final (lat, lng) = widget.demo
        ? (demoBoxes.first.lat, demoBoxes.first.lng)
        : districtPoints[widget.district];
    final box = FoodBox(
      id: 'venue-${DateTime.now().microsecondsSinceEpoch}',
      shop: widget.shop,
      ru: titleRu.text.trim(),
      kk: titleKk.text.trim(),
      category: category,
      price: newPrice,
      original: originalPrice,
      stock: quantity,
      window: '${time(start)}–${time(end)}',
      address: widget.address,
      district: widget.district,
      lat: lat,
      lng: lng,
      image: switch (category) {
        Category.bakery => 'bread',
        Category.hot => 'bowl',
        Category.coffee => 'pastry',
      },
      description: contents.text.trim(),
      merchant: true,
    );
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('Предпросмотр', 'Алдын ала қарау'),
                style: heading(23),
              ),
              const SizedBox(height: 12),
              BoxRow(box: box, favorites: false),
              const SizedBox(height: 12),
              fullButton(
                context.tr('Опубликовать', 'Жариялау'),
                () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      context.store.upsertBox(box);
      toast(context, context.tr('Бокс опубликован', 'Бокс жарияланды'));
      Navigator.pop(context);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      maxLength: numeric ? 7 : 120,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) =>
          (value == null ||
              value.trim().isEmpty ||
              (numeric && (int.tryParse(value) ?? 0) <= 0))
          ? context.tr('Проверьте поле', 'Өрісті тексеріңіз')
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Новый бокс', 'Жаңа бокс'), style: heading(24)),
    ),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          field(titleKk, 'Атауы (Қазақша)'),
          field(titleRu, 'Название (Русский)'),
          field(
            contents,
            context.tr('Что может быть внутри', 'Ішінде не болуы мүмкін'),
          ),
          DropdownButtonFormField<Category>(
            initialValue: category,
            decoration: InputDecoration(
              labelText: context.tr('Категория', 'Санат'),
            ),
            items: [
              for (final item in Category.values)
                DropdownMenuItem(
                  value: item,
                  child: Text(context.categoryName(item)),
                ),
            ],
            onChanged: (value) => setState(() => category = value!),
          ),
          const SizedBox(height: 12),
          field(
            original,
            context.tr('Обычная цена, ₸', 'Бастапқы баға, ₸'),
            numeric: true,
          ),
          field(
            price,
            context.tr('Цена toıdym, ₸', 'toıdym бағасы, ₸'),
            numeric: true,
          ),
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('В продаже', 'Сатылымда'),
                        style: heading(16),
                      ),
                    ),
                    Quantity(
                      value: quantity,
                      min: 1,
                      max: 99,
                      onChanged: (value) => setState(() => quantity = value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.tr('Начало выдачи', 'Алып кету басталады'),
                  ),
                  trailing: Text(time(start), style: heading(16)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start,
                    );
                    if (picked != null && mounted) {
                      setState(() => start = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.tr('Конец выдачи', 'Алып кету аяқталады'),
                  ),
                  trailing: Text(time(end), style: heading(16)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: end,
                    );
                    if (picked != null && mounted) setState(() => end = picked);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          fullButton(context.tr('Предпросмотр', 'Алдын ала қарау'), preview),
        ],
      ),
    ),
  );
}

class PickupPage extends StatefulWidget {
  const PickupPage({super.key, required this.shop, required this.waiting});
  final String shop;
  final List<PickupOrder> waiting;

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> pickup() async {
    final order = widget.waiting.where((o) => o.code == code.text).firstOrNull;
    if (order == null) {
      toast(
        context,
        context.tr(
          'Нет активного заказа с таким кодом.',
          'Мұндай коды бар белсенді тапсырыс жоқ.',
        ),
      );
      return;
    }
    final confirmed = await confirmAction(
      context,
      context.tr('Выдать ${order.id}?', '${order.id} тапсырысы берілсін бе?'),
      context.tr(
        'Оплата на месте · ${money(order.total)}',
        'Сол жерде төлеу · ${money(order.total)}',
      ),
    );
    if (!confirmed || !mounted) return;
    if (context.store.collect(order.code, widget.shop) != null) {
      setState(code.clear);
      toast(
        context,
        context.tr('Бокс выдан. Ас болсын!', 'Бокс берілді. Ас болсын!'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraAvailable =
        kIsWeb ||
        [
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);
    return PageBody(
      children: [
        if (cameraAvailable) ...[
          Panel(
            color: ink,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 58, color: yellow),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    final value = await openPage<String>(
                      context,
                      const ScannerPage(),
                    );
                    if (value != null && mounted) {
                      setState(() => code.text = value);
                      await pickup();
                    }
                  },
                  child: Text(
                    context.tr('Сканировать QR', 'QR кодты сканерлеу'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
        ],
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: context.tr('Код выдачи', 'Алып кету коды'),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (code.text.length == 4) pickup();
          },
        ),
        const SizedBox(height: 10),
        fullButton(
          context.tr('Выдать заказ', 'Тапсырысты беру'),
          code.text.length == 4 ? pickup : null,
        ),
        const SizedBox(height: 18),
        Text(
          context.tr(
            'Ожидают выдачи · ${widget.waiting.length}',
            'Алып кетуді күтуде · ${widget.waiting.length}',
          ),
          style: heading(22),
        ),
        const SizedBox(height: 10),
        if (widget.waiting.isEmpty)
          EmptyState(
            title: context.tr('Все заказы выданы', 'Барлық тапсырыс берілді'),
            message: context.tr(
              'Новые брони появятся здесь.',
              'Жаңа броньдар осы жерде көрінеді.',
            ),
          ),
        for (final order in widget.waiting)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.boxTitle(order.box), style: heading(17)),
                  Text('${order.id} · ${order.box.window}'),
                  SummaryLine(
                    context.tr('К оплате на месте', 'Сол жерде төленеді'),
                    money(order.total),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (await confirmAction(
                            context,
                            context.tr(
                              'Отменить заказ?',
                              'Тапсырыс жойылсын ба?',
                            ),
                            context.tr(
                              'Бронь будет отменена.',
                              'Бронь жойылады.',
                            ),
                          ) &&
                          context.mounted) {
                        context.store.cancel(order);
                      }
                    },
                    child: Text(context.tr('Отменить заказ', 'Тапсырысты жою')),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool found = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Сканировать QR', 'QR кодты сканерлеу')),
    ),
    body: MobileScanner(
      errorBuilder: (context, error) => EmptyState(
        title: context.tr('Камера недоступна', 'Камера қолжетімсіз'),
        message: context.tr(
          'Введите код вручную на экране выдачи.',
          'Алып кету кодын қолмен енгізіңіз.',
        ),
      ),
      onDetect: (capture) {
        if (found) return;
        for (final barcode in capture.barcodes) {
          final code = RegExp(
            r'^toidym:([0-9]{4})$',
          ).firstMatch(barcode.rawValue ?? '')?.group(1);
          if (code != null) {
            found = true;
            Navigator.pop(context, code);
            break;
          }
        }
      },
    ),
  );
}

class MerchantStats extends StatefulWidget {
  const MerchantStats({super.key, required this.orders});
  final List<PickupOrder> orders;

  @override
  State<MerchantStats> createState() => _MerchantStatsState();
}

class _MerchantStatsState extends State<MerchantStats> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    final day = DateTime.utc(now.year, now.month, now.day);
    final start = switch (period) {
      1 => day.subtract(Duration(days: now.weekday - 1)),
      2 => DateTime.utc(now.year, now.month),
      _ => day,
    }.subtract(const Duration(hours: 5));
    final orders = widget.orders
        .where((order) => !(order.collectedAt ?? order.created).isBefore(start))
        .toList();
    final count = orders.fold(0, (sum, order) => sum + order.quantity);
    final sales = orders.fold(0, (sum, order) => sum + order.total);
    final reviews = orders.where((o) => o.rating > 0).toList();
    return PageBody(
      children: [
        Wrap(
          spacing: 7,
          children: [
            for (final (index, (ru, kk)) in [
              ('День', 'Күн'),
              ('Неделя', 'Апта'),
              ('Месяц', 'Ай'),
            ].indexed)
              ChoiceChip(
                label: Text(context.tr(ru, kk)),
                selected: index == period,
                onSelected: (_) => setState(() => period = index),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Panel(
          color: pale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Выручка по выданным боксам',
                  'Берілген бокстардан түскен табыс',
                ),
              ),
              const SizedBox(height: 7),
              Text(money(sales), style: heading(36)),
              const SizedBox(height: 10),
              SummaryLine(
                context.tr('Боксов выдано', 'Берілген бокстар'),
                '$count',
                strong: true,
              ),
              SummaryLine(
                context.tr('Средняя оценка', 'Орташа баға'),
                reviews.isEmpty
                    ? '—'
                    : (reviews.fold(0, (sum, o) => sum + o.rating) /
                              reviews.length)
                          .toStringAsFixed(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
