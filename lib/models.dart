import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Category { bakery, hot, coffee }

enum OrderStatus { reserved, collected, cancelled }

class FoodBox {
  const FoodBox({
    required this.id,
    required this.shop,
    required this.ru,
    required this.kk,
    required this.category,
    required this.price,
    required this.original,
    required this.stock,
    required this.window,
    required this.address,
    required this.district,
    required this.lat,
    required this.lng,
    required this.image,
    this.rating = '4.8',
    this.distance = '0.6',
    this.halal = false,
    this.published = true,
    this.description = '',
    this.merchant = false,
  });

  final String id,
      shop,
      ru,
      kk,
      window,
      address,
      image,
      rating,
      distance,
      description;
  final Category category;
  final int price, original, stock, district;
  final double lat, lng;
  final bool halal, published, merchant;

  int get discount => ((original - price) * 100 / original).round();

  FoodBox copyWith({int? stock, bool? published}) => FoodBox(
    id: id,
    shop: shop,
    ru: ru,
    kk: kk,
    category: category,
    price: price,
    original: original,
    stock: stock ?? this.stock,
    window: window,
    address: address,
    district: district,
    lat: lat,
    lng: lng,
    image: image,
    rating: rating,
    distance: distance,
    halal: halal,
    published: published ?? this.published,
    description: description,
    merchant: merchant,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop': shop,
    'ru': ru,
    'kk': kk,
    'category': category.name,
    'price': price,
    'original': original,
    'stock': stock,
    'window': window,
    'address': address,
    'district': district,
    'lat': lat,
    'lng': lng,
    'image': image,
    'rating': rating,
    'distance': distance,
    'halal': halal,
    'published': published,
    'description': description,
    'merchant': merchant,
  };

  factory FoodBox.fromJson(Map<String, dynamic> json) => FoodBox(
    id: json['id'],
    shop: json['shop'],
    ru: json['ru'],
    kk: json['kk'],
    category: Category.values.byName(json['category']),
    price: json['price'],
    original: json['original'],
    stock: json['stock'],
    window: json['window'],
    address: json['address'],
    district: json['district'],
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    image: json['image'],
    rating: json['rating'],
    distance: json['distance'],
    halal: json['halal'],
    published: json['published'],
    description: json['description'] ?? '',
    merchant: json['merchant'] ?? false,
  );
}

class PickupOrder {
  const PickupOrder({
    required this.id,
    required this.code,
    required this.box,
    required this.quantity,
    required this.created,
    required this.owner,
    this.status = OrderStatus.reserved,
    this.collectedAt,
    this.rating = 0,
    this.feedback = const [],
    this.issue = '',
  });

  final String id, code, issue, owner;
  final FoodBox box;
  final int quantity, rating;
  final DateTime created;
  final DateTime? collectedAt;
  final OrderStatus status;
  final List<String> feedback;

  int get total => quantity * box.price;
  int get savings => quantity * (box.original - box.price);

  // All pickup windows are expressed in Astana time (UTC+5).
  DateTime get pickupStarts {
    final local = created.toUtc().add(const Duration(hours: 5));
    final parts = box.window.split('–').first.split(':');
    final today = DateTime.utc(
      local.year,
      local.month,
      local.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ).subtract(const Duration(hours: 5));
    final duration =
        _minutes(box.window.split('–').last) -
        _minutes(box.window.split('–').first);
    return created.isBefore(today.add(Duration(minutes: duration)))
        ? today
        : today.add(const Duration(days: 1));
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  PickupOrder copyWith({
    OrderStatus? status,
    DateTime? collectedAt,
    int? rating,
    List<String>? feedback,
    String? issue,
  }) => PickupOrder(
    id: id,
    code: code,
    box: box,
    quantity: quantity,
    created: created,
    owner: owner,
    collectedAt: collectedAt ?? this.collectedAt,
    status: status ?? this.status,
    rating: rating ?? this.rating,
    feedback: feedback ?? this.feedback,
    issue: issue ?? this.issue,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'box': box.toJson(),
    'quantity': quantity,
    'created': created.toIso8601String(),
    'status': status.name,
    'owner': owner,
    'collectedAt': collectedAt?.toIso8601String(),
    'rating': rating,
    'feedback': feedback,
    'issue': issue,
  };

  factory PickupOrder.fromJson(Map<String, dynamic> json) => PickupOrder(
    id: json['id'],
    code: json['code'],
    box: FoodBox.fromJson(json['box']),
    quantity: json['quantity'],
    created: DateTime.parse(json['created']),
    owner: json['owner'] ?? '',
    collectedAt: DateTime.tryParse(json['collectedAt'] ?? ''),
    status: OrderStatus.values.byName(json['status']),
    rating: json['rating'],
    feedback: List<String>.from(json['feedback'] ?? []),
    issue: json['issue'],
  );
}

class AppStore extends ChangeNotifier {
  AppStore(this._preferences);

  static const _key = 'toidym.demo.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _pending = Future.value();

  final language = ValueNotifier(true);
  bool get kazakh => language.value;
  set kazakh(bool value) => language.value = value;
  bool onboarded = false;
  int district = 0;
  String phone = '';
  String venue = '';
  String venueAddress = '';
  String venueStatus = '';
  int venueDistrict = 0;
  List<FoodBox> boxes = [...demoBoxes];
  List<PickupOrder> orders = [];
  Set<String> favorites = {};

  @override
  void dispose() {
    language.dispose();
    super.dispose();
  }

  bool get signedIn => phone.isNotEmpty;
  List<PickupOrder> get buyerOrders =>
      signedIn ? orders.where((o) => o.owner == phone).toList() : [];
  List<PickupOrder> get active =>
      buyerOrders.where((o) => o.status == OrderStatus.reserved).toList();
  List<PickupOrder> get collected =>
      buyerOrders.where((o) => o.status == OrderStatus.collected).toList();

  Future<void> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    kazakh = json['kazakh'];
    onboarded = json['onboarded'];
    district = json['district'];
    phone = json['phone'];
    venue = json['venue'] ?? '';
    venueAddress = json['venueAddress'] ?? '';
    venueStatus = json['venueStatus'] ?? '';
    venueDistrict = json['venueDistrict'] ?? 0;
    boxes = (json['boxes'] as List).map((b) => FoodBox.fromJson(b)).toList();
    orders = (json['orders'] as List)
        .map((o) => PickupOrder.fromJson(o))
        .toList();
    favorites = Set<String>.from(json['favorites']);
  }

  void save() {
    final json = jsonEncode({
      'kazakh': kazakh,
      'onboarded': onboarded,
      'district': district,
      'phone': phone,
      'venue': venue,
      'venueAddress': venueAddress,
      'venueStatus': venueStatus,
      'venueDistrict': venueDistrict,
      'boxes': boxes.map((box) => box.toJson()).toList(),
      'orders': orders.map((order) => order.toJson()).toList(),
      'favorites': favorites.toList(),
    });
    _pending = _pending
        .then((_) => _preferences.setString(_key, json))
        .catchError(
          (Object error, StackTrace stack) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'toıdym storage',
            ),
          ),
        );
    notifyListeners();
  }

  FoodBox? box(String id) => boxes.where((b) => b.id == id).firstOrNull;
  PickupOrder? order(String id) => orders.where((o) => o.id == id).firstOrNull;

  void favorite(String shop) {
    if (!favorites.remove(shop)) favorites.add(shop);
    save();
  }

  void upsertBox(FoodBox box) {
    final index = boxes.indexWhere((b) => b.id == box.id);
    if (index == -1) {
      boxes.insert(0, box);
    } else {
      boxes[index] = box;
    }
    save();
  }

  PickupOrder? reserve(String boxId, int quantity) {
    final item = box(boxId);
    if (!signedIn ||
        item == null ||
        !item.published ||
        quantity < 1 ||
        quantity > item.stock) {
      return null;
    }
    final takenCodes = orders
        .where((o) => o.status == OrderStatus.reserved)
        .map((o) => o.code)
        .toSet();
    if (takenCodes.length >= 9000) return null;
    final random = Random();
    var number = random.nextInt(9000);
    while (takenCodes.contains('${1000 + number}')) {
      number = (number + 1) % 9000;
    }
    final now = DateTime.now().toUtc();
    final order = PickupOrder(
      id: 'TD-${1001 + orders.length}',
      code: '${1000 + number}',
      box: item,
      quantity: quantity,
      created: now,
      owner: phone,
    );
    orders.insert(0, order);
    upsertBox(item.copyWith(stock: item.stock - quantity));
    return order;
  }

  void cancel(PickupOrder order) {
    if (this.order(order.id)?.status != OrderStatus.reserved) return;
    final index = orders.indexWhere((o) => o.id == order.id);
    orders[index] = orders[index].copyWith(status: OrderStatus.cancelled);
    final item = box(order.box.id);
    if (item == null) {
      save();
    } else {
      upsertBox(item.copyWith(stock: item.stock + order.quantity));
    }
  }

  PickupOrder? collect(String code, String shop) {
    final index = orders.indexWhere(
      (o) =>
          o.code == code &&
          o.status == OrderStatus.reserved &&
          o.box.merchant &&
          o.box.shop == shop,
    );
    if (index == -1) return null;
    orders[index] = orders[index].copyWith(
      status: OrderStatus.collected,
      collectedAt: DateTime.now().toUtc(),
    );
    save();
    return orders[index];
  }

  void updateOrder(PickupOrder order) {
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index == -1) return;
    orders[index] = order;
    save();
  }
}

const demoBoxes = [
  FoodBox(
    id: 'bread',
    shop: 'Таңғы нан',
    ru: 'Вечерний хлебный бокс',
    kk: 'Кешкі нан боксы',
    category: Category.bakery,
    price: 1490,
    original: 4500,
    stock: 4,
    window: '20:00–21:00',
    address: 'Сығанақ, 16',
    district: 0,
    lat: 51.1213,
    lng: 71.4175,
    image: 'bread',
    halal: true,
    merchant: true,
    rating: '4.9',
  ),
  FoodBox(
    id: 'bowl',
    shop: 'Дастарқан дәмі',
    ru: 'Горячий бокс',
    kk: 'Ыстық тағам боксы',
    category: Category.hot,
    price: 2290,
    original: 6100,
    stock: 2,
    window: '19:30–21:00',
    address: 'Достық, 5',
    district: 0,
    lat: 51.1284,
    lng: 71.4254,
    image: 'bowl',
    halal: true,
    rating: '4.8',
    distance: '1.2',
  ),
  FoodBox(
    id: 'coffee',
    shop: 'Coffee Wave',
    ru: 'Кофе и выпечка',
    kk: 'Кофе мен бәліш',
    category: Category.coffee,
    price: 1290,
    original: 3900,
    stock: 3,
    window: '18:30–20:00',
    address: 'Қабанбай батыр, 21',
    district: 0,
    lat: 51.1350,
    lng: 71.4121,
    image: 'pastry',
    rating: '4.7',
    distance: '1.6',
  ),
  FoodBox(
    id: 'sweet',
    shop: 'Таңғы нан',
    ru: 'Сладкая выпечка',
    kk: 'Тәтті бәліштер',
    category: Category.bakery,
    price: 1690,
    original: 4800,
    stock: 6,
    window: '20:00–21:00',
    address: 'Сығанақ, 16',
    district: 0,
    lat: 51.1213,
    lng: 71.4175,
    image: 'pastry',
    merchant: true,
    halal: true,
    rating: '4.9',
  ),
  FoodBox(
    id: 'market',
    shop: 'Дәмді күн',
    ru: 'Обеденный набор',
    kk: 'Түскі ас жиынтығы',
    category: Category.hot,
    price: 1890,
    original: 5200,
    stock: 5,
    window: '19:00–20:00',
    address: 'Жеңіс, 24',
    district: 1,
    lat: 51.1660,
    lng: 71.4162,
    image: 'bowl',
    halal: true,
    distance: '0.8',
  ),
  FoodBox(
    id: 'north',
    shop: 'Bauyrsaq',
    ru: 'Бокс с выпечкой',
    kk: 'Бауырсақ пен бәліш',
    category: Category.bakery,
    price: 1390,
    original: 3900,
    stock: 3,
    window: '18:30–20:00',
    address: 'Абылай хан, 8',
    district: 2,
    lat: 51.1519,
    lng: 71.4775,
    image: 'bread',
    distance: '0.9',
  ),
];

const districtPoints = [(51.128, 71.420), (51.165, 71.418), (51.152, 71.475)];
