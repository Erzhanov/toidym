import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'nearby_map.dart' deferred as map;
import 'orders.dart';
import 'ui.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onMerchant});
  final VoidCallback onMerchant;

  Future<void> start(BuildContext context) async {
    final district = await chooseDistrict(context);
    if (district == null || !context.mounted) return;
    context.store
      ..district = district
      ..onboarded = true
      ..save();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: (constraints.maxHeight * 0.48)
                      .clamp(245, 430)
                      .toDouble(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        child: art(
                          'welcome',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Brand(width: 114),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Tag('АСТАНА · ДЕМО'),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          'Спасай еду —\nэкономь до 70%',
                          'Дәмді асты сақта,\n70%-ға дейін үнемде',
                        ),
                        style: heading(38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          'Забирайте свежие боксы из кафе и пекарен рядом с домом.',
                          'Жақын маңдағы кафе мен наубайханалардан балғын ас бокстарын алып кетіңіз.',
                        ),
                        style: const TextStyle(color: muted, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      const LanguageChoice(),
                      const SizedBox(height: 14),
                      fullButton(
                        context.tr('Начать', 'Бастау'),
                        () => start(context),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: onMerchant,
                          child: Text(
                            context.tr(
                              'Я представляю заведение',
                              'Мен кәсіпорын атынан келдім',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LanguageChoice extends StatelessWidget {
  const LanguageChoice({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final (label, kazakh) in [('Қазақша', true), ('Русский', false)])
        ChoiceChip(
          label: Text(label),
          selected: context.store.kazakh == kazakh,
          selectedColor: pale,
          backgroundColor: Colors.white,
          onSelected: (_) => context.store
            ..kazakh = kazakh
            ..save(),
        ),
    ],
  );
}

Future<int?> chooseDistrict(BuildContext context) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  sheetAnimationStyle: kIsWeb && MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
          child: Text(
            context.tr('Астана · выберите район', 'Астана · ауданды таңдаңыз'),
            style: heading(24),
          ),
        ),
        for (var i = 0; i < districtPoints.length; i++)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(context.districtName(i)),
            trailing: context.store.district == i
                ? const Icon(Icons.check)
                : null,
            onTap: () => Navigator.pop(context, i),
          ),
        const SizedBox(height: 14),
      ],
    ),
  ),
);

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key, required this.showMap, required this.onToggle});
  final bool showMap;
  final VoidCallback onToggle;
  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final search = TextEditingController();
  int filter = 0;
  bool showIntro = true;
  Future<void>? _mapLoad;

  @override
  void initState() {
    super.initState();
    if (widget.showMap) _mapLoad = map.loadLibrary();
  }

  @override
  void didUpdateWidget(BrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showMap) _mapLoad ??= map.loadLibrary();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final available = store.boxes
        .where(
          (b) => b.published && b.stock > 0 && b.district == store.district,
        )
        .toList();
    final query = search.text.trim().toLowerCase();
    final boxes = available.where((box) {
      final match = switch (filter) {
        1 => box.category == Category.bakery,
        2 => box.category == Category.hot,
        3 => box.halal,
        4 => box.category == Category.coffee,
        _ => true,
      };
      return match &&
          '${box.shop} ${box.ru} ${box.kk}'.toLowerCase().contains(query);
    }).toList();
    final urgent = boxes.where((b) => b.stock <= 3).toList();
    final count = available.fold(0, (total, b) => total + b.stock);
    final filters = [
      context.tr('Все', 'Бәрі'),
      context.tr('Выпечка', 'Нан-тоқаш'),
      context.tr('Горячее', 'Ыстық тағам'),
      context.tr('Халал', 'Халал'),
      context.tr('Кофе', 'Кофе'),
    ];

    final catalogHeader = <Widget>[
      if (store.connected && !store.online)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: store.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              context.tr(
                'Обновить каталог с сервера',
                'Каталогты серверден жаңарту',
              ),
            ),
          ),
        ),
      if (showIntro && query.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 7),
          child: Panel(
            color: pale,
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: Colors.white,
                    child: SizedBox(width: 47, height: 47, child: art('bread')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'Спасай еду до −70%',
                          'Дәмді асқа −70%-ға дейін',
                        ),
                        style: heading(16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          '$count боксов рядом ждут спасения',
                          'Жақын жерде $count бокс бар',
                        ),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Закрыть', 'Жабу'),
                  onPressed: () => setState(() => showIntro = false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        ),
      browseControls(context, filters),
      if (boxes.isEmpty)
        EmptyState(
          title: context.tr('Пока ничего не нашли', 'Әзірге ештеңе табылмады'),
          message: context.tr(
            'Попробуйте другой запрос или фильтр.',
            'Басқа сөзді немесе сүзгіні қолданып көріңіз.',
          ),
          action: FilledButton(
            onPressed: () => setState(() {
              filter = 0;
              search.clear();
            }),
            child: Text(context.tr('Сбросить фильтры', 'Сүзгіні тазарту')),
          ),
        ),
      if (urgent.isNotEmpty && query.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Text(
            context.tr('Скоро закончатся', 'Аз қалды'),
            style: heading(23),
          ),
        ),
        SizedBox(
          height: 205,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: urgent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                SizedBox(width: 205, child: CompactBox(box: urgent[i])),
          ),
        ),
      ],
      if (boxes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 21, 20, 12),
          child: Text(
            context.tr('Доступные боксы', 'Қолжетімді бокстар'),
            style: heading(23),
          ),
        ),
    ];

    return Column(
      children: [
        Material(
          color: ink,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(29),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Brand(width: kIsWeb ? 72 : 62),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: cream,
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                          ),
                          onPressed: () async {
                            final value = await chooseDistrict(context);
                            if (value != null && context.mounted) {
                              store
                                ..district = value
                                ..save();
                            }
                          },
                          icon: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: yellow,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Астана · ${context.districtName(store.district)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 16),
                            ],
                          ),
                        ),
                      ),
                      if (store.signedIn)
                        IconButton.filledTonal(
                          tooltip: context.tr('Уведомления', 'Хабарламалар'),
                          onPressed: () =>
                              openPage(context, const NoticesPage()),
                          icon: const Icon(Icons.notifications_none),
                        )
                      else
                        FilledButton(
                          onPressed: () =>
                              openPage(context, const SignInPage()),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 43),
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                          ),
                          child: Text(context.tr('Войти', 'Кіру')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      contentPadding: kIsWeb
                          ? const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            )
                          : null,
                      border: kIsWeb
                          ? const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(28),
                              ),
                              borderSide: BorderSide.none,
                            )
                          : null,
                      enabledBorder: kIsWeb
                          ? const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(28),
                              ),
                              borderSide: BorderSide.none,
                            )
                          : null,
                      focusedBorder: kIsWeb
                          ? const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(28),
                              ),
                              borderSide: BorderSide(color: yellow, width: 2),
                            )
                          : null,
                      hintText: context.tr(
                        'Заведения и боксы',
                        'Кафелер мен бокстар',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.tr(
                                'Очистить поиск',
                                'Іздеуді тазарту',
                              ),
                              onPressed: () => setState(search.clear),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: widget.showMap ? 1 : 0,
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 15, 0, 8),
                keyboardDismissBehavior: kIsWeb
                    ? ScrollViewKeyboardDismissBehavior.onDrag
                    : null,
                itemCount: catalogHeader.length + boxes.length,
                itemBuilder: (context, index) {
                  if (index < catalogHeader.length) return catalogHeader[index];
                  final box = boxes[index - catalogHeader.length];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
                    child: BoxRow(
                      box: box,
                      onTap: () => openPage(context, BoxDetail(id: box.id)),
                    ),
                  );
                },
              ),
              if (_mapLoad != null)
                TickerMode(
                  enabled: widget.showMap,
                  child: Column(
                    children: [
                      browseControls(context, filters),
                      Expanded(
                        child: FutureBuilder<void>(
                          future: _mapLoad,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: TextButton(
                                  onPressed: () => setState(
                                    () => _mapLoad = map.loadLibrary(),
                                  ),
                                  child: Text(
                                    context.tr(
                                      'Загрузить карту снова',
                                      'Картаны қайта жүктеу',
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: context.tr(
                                    'Загрузка карты',
                                    'Карта жүктелуде',
                                  ),
                                ),
                              );
                            }
                            return map.NearbyMap(
                              key: ValueKey(store.district),
                              boxes: boxes,
                              district: store.district,
                              selectedCard: (box) => BoxRow(
                                box: box,
                                onTap: () =>
                                    openPage(context, BoxDetail(id: box.id)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget browseControls(BuildContext context, List<String> filters) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 9, 20, 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Боксы рядом', 'Жақын бокстар'),
                style: heading(25),
              ),
            ),
            if (kIsWeb)
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: widget.showMap,
                backgroundColor: Colors.white,
                thumbColor: ink,
                padding: const EdgeInsets.all(3),
                onValueChanged: (value) {
                  if (value != null && value != widget.showMap) {
                    widget.onToggle();
                  }
                },
                children: {
                  for (final (showMap, label) in [
                    (false, context.tr('Список', 'Тізім')),
                    (true, context.tr('Карта', 'Карта')),
                  ])
                    showMap: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: widget.showMap == showMap ? cream : ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                },
              )
            else
              OutlinedButton.icon(
                onPressed: widget.onToggle,
                icon: Icon(
                  widget.showMap ? Icons.list : Icons.map_outlined,
                  size: 17,
                ),
                label: Text(
                  widget.showMap ? context.tr('Список', 'Тізім') : 'Карта',
                ),
              ),
          ],
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: [
            for (final (index, label) in filters.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: index == filter ? cream : ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  showCheckmark: false,
                  selected: index == filter,
                  selectedColor: ink,
                  backgroundColor: pale,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() => filter = index),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.shop});
  final String shop;

  @override
  Widget build(BuildContext context) {
    final favorite = context.store.favorites.contains(shop);
    return IconButton(
      tooltip: favorite
          ? context.tr('Убрать из избранного', 'Таңдаулыдан алып тастау')
          : context.tr('В избранное', 'Таңдаулыға қосу'),
      isSelected: favorite,
      selectedIcon: const Icon(Icons.favorite, color: Color(0xffB24858)),
      icon: const Icon(Icons.favorite_border),
      onPressed: () => context.store.favorite(shop),
    );
  }
}

class CompactBox extends StatelessWidget {
  const CompactBox({super.key, required this.box});
  final FoodBox box;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openPage(context, BoxDetail(id: box.id)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColoredBox(
                  color: pale,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: art(box.image),
                      ),
                      Positioned(
                        left: 6,
                        bottom: 5,
                        child: Tag(
                          context.tr(
                            'осталось ${box.stock}',
                            '${box.stock} қалды',
                          ),
                          color: yellow,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: FavoriteButton(shop: box.shop),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              box.shop,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: heading(15),
            ),
            Text(
              '${context.pickupLabel(box)}${box.distance.isEmpty ? '' : ' · ${box.distance} км'}',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Prices(box: box),
          ],
        ),
      ),
    ),
  );
}

class Prices extends StatelessWidget {
  const Prices({super.key, required this.box});
  final FoodBox box;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(money(box.price), style: heading(18)),
      Text(
        money(box.original),
        style: const TextStyle(
          fontSize: 11,
          color: muted,
          decoration: TextDecoration.lineThrough,
        ),
      ),
    ],
  );
}

class BoxRow extends StatelessWidget {
  const BoxRow({
    super.key,
    required this.box,
    this.onTap,
    this.favorites = true,
  });
  final FoodBox box;
  final VoidCallback? onTap;
  final bool favorites;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: pale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  art(box.image),
                  if (box.halal)
                    const Positioned(
                      left: 4,
                      bottom: 4,
                      child: Tag('Халал', color: ink, textColor: cream),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(box.shop, style: heading(15)),
                  Text(
                    context.boxTitle(box),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: muted),
                  ),
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 11, color: muted),
                    child: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${context.pickupLabel(box)}${box.distance.isEmpty ? '' : ' · ${box.distance} км'}',
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: muted,
                            ),
                            Text(box.rating),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Prices(box: box),
                  if (favorites)
                    Text(
                      context.tr('осталось ${box.stock}', '${box.stock} қалды'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (favorites) FavoriteButton(shop: box.shop),
          ],
        ),
      ),
    ),
  );
}

class BoxDetail extends StatelessWidget {
  const BoxDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final box = context.store.box(id);
    if (box == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('О боксе', 'Бокс туралы'), style: heading(22)),
        actions: [
          IconButton(
            tooltip: context.tr('Поделиться', 'Бөлісу'),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text:
                    '${context.boxTitle(box)} · ${box.shop}\n${money(box.price)} · ${box.window}\nАстана, ${box.address}',
                sharePositionOrigin: shareOrigin(context),
              ),
            ),
            icon: const Icon(Icons.ios_share),
          ),
          FavoriteButton(shop: box.shop),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: fullButton(
          box.stock == 0 || !box.published
              ? context.tr('Бокс закончился', 'Бокс таусылды')
              : context.tr(
                  'Забронировать · ${money(box.price)}',
                  'Брондау · ${money(box.price)}',
                ),
          box.stock == 0 || !box.published
              ? null
              : () async {
                  final store = context.store;
                  if (!store.signedIn &&
                      await openPage<bool>(context, const SignInPage()) !=
                          true) {
                    return;
                  }
                  if (!context.mounted) return;
                  final order = await openPage<PickupOrder>(
                    context,
                    CheckoutPage(id: id),
                  );
                  if (order != null && context.mounted) {
                    await openPage(context, OrderDetail(id: order.id));
                  }
                },
        ),
      ),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        children: [
          Panel(
            color: pale,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 205,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: art(box.image),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Tag('−${box.discount}%', color: yellow),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => openPage(context, VenuePage(box: box)),
              icon: const Icon(Icons.storefront_outlined, size: 17),
              label: Text('${box.shop}  ·  ★ ${box.rating}'),
            ),
          ),
          const SizedBox(height: 5),
          Text(context.boxTitle(box), style: heading(32)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              Tag(context.tr('осталось ${box.stock}', '${box.stock} қалды')),
              if (box.halal) const Tag('Халал', color: lavender),
              Tag(context.categoryName(box.category), color: lavender),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'Самовывоз · ${context.pickupLabel(box)}',
                    'Алып кету · ${context.pickupLabel(box)}',
                  ),
                  style: heading(19),
                ),
                const SizedBox(height: 6),
                Text('Астана, ${box.address} · ${box.distance} км'),
                TextButton.icon(
                  onPressed: () => routeTo(context, box),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(context.tr('Маршрут', 'Бағыт')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Что обычно внутри', 'Ішінде не болуы мүмкін'),
                  style: heading(19),
                ),
                const SizedBox(height: 8),
                Text(
                  box.description.isNotEmpty
                      ? box.description
                      : switch (box.category) {
                          Category.bakery => context.tr(
                            'Свежий хлеб, булочки или другая выпечка.',
                            'Балғын нан, тоқаш немесе басқа бәліштер.',
                          ),
                          Category.hot => context.tr(
                            'Готовое горячее блюдо или гарнир.',
                            'Дайын ыстық тағам немесе гарнир.',
                          ),
                          Category.coffee => context.tr(
                            'Напиток и выпечка из меню заведения.',
                            'Кафе мәзіріндегі сусын мен бәліш.',
                          ),
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Состав зависит от остатков дня. При аллергии уточните состав перед получением.',
                    'Құрамы күн соңында қалған тағамға байланысты. Аллергияңыз болса, аларда құрамын нақтылаңыз.',
                  ),
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Уведомления', 'Хабарламалар'))),
    body: PageBody(
      children: [
        if (context.store.active.isEmpty)
          EmptyState(
            title: context.tr('Пока тихо', 'Әзірге хабарлама жоқ'),
            message: context.tr(
              'Здесь появятся напоминания о ваших бронях.',
              'Бронь туралы еске салулар осы жерде көрінеді.',
            ),
          ),
        for (final order in context.store.active)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(order.box.shop),
            subtitle: Text(
              '${context.tr('Заберите бокс', 'Боксты алып кетіңіз')} · ${order.box.window}',
            ),
            onTap: () => openPage(context, OrderDetail(id: order.id)),
          ),
      ],
    ),
  );
}

class VenuePage extends StatelessWidget {
  const VenuePage({super.key, required this.box});
  final FoodBox box;

  @override
  Widget build(BuildContext context) {
    final listings = context.store.boxes.where(
      (item) => item.shop == box.shop && item.published && item.stock > 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(box.shop),
        actions: [FavoriteButton(shop: box.shop)],
      ),
      body: PageBody(
        children: [
          Panel(
            color: pale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(box.shop, style: heading(26)),
                const SizedBox(height: 7),
                Text('★ ${box.rating} · Астана, ${box.address}'),
                TextButton.icon(
                  onPressed: () => routeTo(context, box),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(context.tr('Маршрут', 'Бағыт')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('Боксы заведения', 'Кәсіпорын бокстары'),
            style: heading(22),
          ),
          const SizedBox(height: 8),
          if (listings.isEmpty)
            Text(
              context.tr(
                'Сейчас нет доступных боксов',
                'Қазір қолжетімді бокс жоқ',
              ),
            ),
          for (final listing in listings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BoxRow(
                box: listing,
                favorites: false,
                onTap: () => openPage(context, BoxDetail(id: listing.id)),
              ),
            ),
        ],
      ),
    );
  }
}
