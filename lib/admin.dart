import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'orders.dart';
import 'pilot_store.dart';
import 'ui.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.store});
  final PilotStore store;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> data = widget.store.adminSnapshot();
  int tab = 0;
  bool working = false;

  void reload() => setState(() => data = widget.store.adminSnapshot());

  Future<void> change(Future<void> Function() action) async {
    if (working || !mounted) return;
    setState(() => working = true);
    await pilotAction(context, action);
    if (!mounted) return;
    setState(() => working = false);
    reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.store.admin) return unavailablePage(context);
    final tabs = [
      context.tr('Заведения', 'Мекемелер'),
      context.tr('Заказы и жалобы', 'Тапсырыстар мен шағымдар'),
      context.tr('Объявления', 'Жарияланымдар'),
      context.tr('Журнал', 'Журнал'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Админ-панель', 'Админ панель')),
        actions: [
          IconButton(
            tooltip: context.tr('Обновить', 'Жаңарту'),
            onPressed: working ? null : reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PageBody(
              children: [
                Text(
                  pilotMessage(
                    context,
                    (snapshot.error is PilotError)
                        ? (snapshot.error! as PilotError).code
                        : 'network',
                  ),
                ),
                fullButton(context.tr('Повторить', 'Қайталау'), reload),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data!;
          final metrics = report['metrics'] as Map<String, dynamic>;
          final key = ['venues', 'orders', 'listings', 'audit'][tab];
          final rows = (report[key] as List).cast<Map<String, dynamic>>();
          return PageBody(
            children: [
              Panel(
                color: pale,
                child: Column(
                  children: [
                    for (final status in OrderStatus.values)
                      SummaryLine(
                        context.statusName(status),
                        '${metrics[status.name] ?? 0}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final (i, name) in tabs.indexed)
                    ChoiceChip(
                      label: Text(name),
                      selected: tab == i,
                      onSelected: (_) => setState(() => tab = i),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                Text(context.tr('Пока записей нет', 'Әзірге жазба жоқ')),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: switch (tab) {
                    0 => venueCard(row),
                    1 => orderCard(PickupOrder.fromJson(row)),
                    2 => listingCard(row),
                    _ => Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['action']} · ${row['target']}',
                            style: heading(16),
                          ),
                          Text('${row['occurred']} · ${row['actor']}'),
                          if (row['note'] != '') Text(row['note'] as String),
                        ],
                      ),
                    ),
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget venueCard(Map<String, dynamic> venue) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(venue['name'] as String, style: heading(19)),
        Text('${venue['company']} · ${venue['address']}'),
        Text(venue['owner'] as String),
        SummaryLine(
          context.tr('Активные объявления', 'Белсенді жарияланымдар'),
          '${venue['live_listings']}',
        ),
        SummaryLine(
          context.tr('Боксов выдано за 7 дней', '7 күнде берілген бокстар'),
          '${venue['week_collected']}',
        ),
        Tag(switch (venue['status']) {
          'approved' => context.tr('Одобрено', 'Мақұлданды'),
          'rejected' => context.tr('На доработку', 'Түзетуге қайтарылды'),
          _ => context.tr('На проверке', 'Тексеруде'),
        }),
        if (venue['review_note'] != '') Text(venue['review_note'] as String),
        if (venue['status'] == 'review')
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: working
                    ? null
                    : () => change(
                        () => widget.store.adminAction(
                          'venues/${venue['id']}',
                          {'status': 'approved', 'note': ''},
                        ),
                      ),
                child: Text(context.tr('Одобрить', 'Мақұлдау')),
              ),
              TextButton(
                onPressed: working
                    ? null
                    : () async {
                        final note = await askNote(
                          context,
                          context.tr('Причина возврата', 'Қайтару себебі'),
                        );
                        if (note != null) {
                          await change(
                            () => widget.store.adminAction(
                              'venues/${venue['id']}',
                              {'status': 'rejected', 'note': note},
                            ),
                          );
                        }
                      },
                child: Text(context.tr('Вернуть', 'Түзетуге қайтару')),
              ),
            ],
          ),
      ],
    ),
  );

  Widget orderCard(PickupOrder order) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(order.id, style: heading(18)),
        Text('${order.box.shop} · ${context.boxTitle(order.box)}'),
        SummaryLine(context.statusName(order.status), money(order.total)),
        if (order.issue.isNotEmpty) ...[
          Text(order.issue),
          if (order.resolution.isNotEmpty) Text(order.resolution),
          if (order.resolution.isEmpty)
            TextButton(
              onPressed: working
                  ? null
                  : () async {
                      final note = await askNote(
                        context,
                        context.tr('Решение по жалобе', 'Шағым бойынша шешім'),
                        maxLength: 500,
                      );
                      if (note != null) {
                        await change(
                          () => widget.store.adminAction('issues/${order.id}', {
                            'note': note,
                          }),
                        );
                      }
                    },
              child: Text(context.tr('Закрыть жалобу', 'Шағымды жабу')),
            ),
        ],
        if (order.status == OrderStatus.reserved)
          TextButton(
            onPressed: working
                ? null
                : () async {
                    if (await confirmAction(
                      context,
                      context.tr('Отменить заказ?', 'Тапсырысты жою керек пе?'),
                      order.id,
                    )) {
                      await change(() => widget.store.cancelBooking(order));
                    }
                  },
            child: Text(context.tr('Отменить заказ', 'Тапсырысты жою')),
          ),
      ],
    ),
  );

  Widget listingCard(Map<String, dynamic> row) {
    final box = FoodBox.fromJson(row);
    final paused = row['paused'] == true;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.boxTitle(box), style: heading(18)),
          Text('${box.shop} · ${context.pickupLabel(box)}'),
          if (paused) Tag(context.tr('Приостановлено', 'Тоқтатылды')),
          TextButton(
            onPressed: working
                ? null
                : () async {
                    final note = paused
                        ? ''
                        : await askNote(
                            context,
                            context.tr('Причина остановки', 'Тоқтату себебі'),
                          );
                    if (note != null) {
                      await change(
                        () => widget.store.adminAction('listings/${box.id}', {
                          'paused': !paused,
                          'note': note,
                        }),
                      );
                    }
                  },
            child: Text(
              paused
                  ? context.tr('Разрешить публикацию', 'Жариялауға рұқсат беру')
                  : context.tr('Приостановить', 'Тоқтату'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> askNote(
  BuildContext context,
  String title, {
  int maxLength = 250,
}) => showDialog<String>(
  context: context,
  builder: (context) => _NoteDialog(title: title, maxLength: maxLength),
);

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title, required this.maxLength});
  final String title;
  final int maxLength;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  String note = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      autofocus: true,
      maxLines: 3,
      maxLength: widget.maxLength,
      onChanged: (text) => setState(() => note = text.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Назад', 'Артқа')),
      ),
      FilledButton(
        onPressed: note.isEmpty ? null : () => Navigator.pop(context, note),
        child: Text(context.tr('Сохранить', 'Сақтау')),
      ),
    ],
  );
}

class StaffPage extends StatefulWidget {
  const StaffPage({super.key, required this.store});
  final PilotStore store;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final phone = TextEditingController();
  bool working = false;

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> change(String number, bool add) async {
    if (working) return;
    setState(() => working = true);
    final ok = await pilotAction(
      context,
      () => widget.store.changeStaff(number, add: add),
    );
    if (!mounted) return;
    if (ok && add) phone.clear();
    setState(() => working = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    if (store.venueStatus != 'approved' || store.cashier) {
      return unavailablePage(context);
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Сотрудники', 'Қызметкерлер'))),
      body: PageBody(
        children: [
          Text(
            context.tr(
              'Добавьте номер кассира. Сотрудник войдёт по этому номеру и увидит заказы филиала.',
              'Кассирдің нөмірін қосыңыз. Қызметкер сол нөмірмен кіріп, филиал тапсырыстарын көреді.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            enabled: !working,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              prefixText: '+7 ',
              labelText: context.tr('Номер кассира', 'Кассир нөмірі'),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          fullButton(
            context.tr('Добавить кассира', 'Кассир қосу'),
            working || phone.text.length != 10
                ? null
                : () => change('+7${phone.text}', true),
          ),
          const SizedBox(height: 14),
          for (final number in store.staff)
            ListTile(
              title: Text(number),
              subtitle: Text(context.tr('Кассир', 'Кассир')),
              trailing: IconButton(
                tooltip: context.tr(
                  'Убрать доступ',
                  'Қолжетімділікті алып тастау',
                ),
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: working ? null : () => change(number, false),
              ),
            ),
        ],
      ),
    );
  }
}
