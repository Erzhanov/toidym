import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class PilotStore extends AppStore {
  PilotStore(super.preferences, this.base) {
    boxes = [];
  }

  final Uri base;
  final _client = http.Client();
  Timer? _poll;
  String _token = '';
  String _state = '';
  int _revision = 0;
  bool _disposed = false;
  bool _polling = false;
  bool _online = false;
  bool _demo = false;
  bool _admin = false;
  bool _cashier = false;
  String _note = '';
  List<String> _staff = const [];
  List<FoodBox> _inventory = const [];
  List<PickupOrder> _branch = const [];

  @override
  bool get connected => true;
  @override
  bool get online => _online;
  @override
  bool get demoAuth => _demo;
  @override
  bool get admin => _admin;
  @override
  bool get cashier => _cashier;
  @override
  String get venueReviewNote => _note;
  @override
  List<String> get staff => _staff;
  @override
  List<FoodBox> get inventory => _inventory;
  @override
  List<PickupOrder> get branchOrders => _branch;

  @override
  Future<void> load() async {
    await super.load();
    boxes = [];
    _clearAccount();
    unawaited(_pollState());
    _poll = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_pollState()),
    );
  }

  Future<void> _pollState() async {
    if (_polling) return;
    _polling = true;
    try {
      await refresh();
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _client.close();
    super.dispose();
  }

  void _clearAccount() {
    phone = venue = venueAddress = venueStatus = _note = '';
    _admin = _cashier = false;
    orders = [];
    _inventory = const [];
    _branch = const [];
    _staff = const [];
  }

  Future<Map<String, dynamic>> _call(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final headers = {
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final url = base.resolve('api/$path');
    final http.Response response;
    try {
      response =
          await (body == null
                  ? _client.get(url, headers: headers)
                  : _client.post(url, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const PilotError('network');
    } on http.ClientException {
      throw const PilotError('network');
    }
    final Map<String, dynamic> data;
    try {
      data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw const PilotError('network');
    }
    if (response.statusCode != 200) {
      throw PilotError(data['error'] as String? ?? 'server_error');
    }
    return data;
  }

  @override
  Future<void> refresh() async {
    final revision = ++_revision;
    try {
      final data = await _call('state');
      if (_disposed || revision != _revision) return;
      final snapshot = jsonEncode(data);
      if (snapshot == _state && _online) return;
      _state = snapshot;
      _online = true;
      _demo = data['demo'] == true;
      _admin = data['admin'] == true;
      phone = data['phone'] as String;
      final branch = data['venue'] as Map<String, dynamic>?;
      venue = branch?['name'] as String? ?? '';
      venueAddress = branch?['address'] as String? ?? '';
      venueStatus = branch?['status'] as String? ?? '';
      venueDistrict = branch?['district'] as int? ?? 0;
      _note = branch?['review_note'] as String? ?? '';
      _cashier = branch?['role'] == 'cashier';
      _staff = List<String>.from(data['staff'] as List);
      boxes = _decodeBoxes(data['boxes'] as List);
      _inventory = _decodeBoxes(data['inventory'] as List);
      orders = _decodeOrders(data['orders'] as List);
      _branch = _decodeOrders(data['branchOrders'] as List);
      notifyListeners();
    } on PilotError catch (error) {
      if (_disposed || revision != _revision) return;
      if (error.code == 'session_expired') {
        _token = '';
        _clearAccount();
        notifyListeners();
        await refresh();
      } else if (_online) {
        _online = false;
        notifyListeners();
      }
    }
  }

  List<FoodBox> _decodeBoxes(List<dynamic> rows) =>
      rows.map((row) => FoodBox.fromJson(row as Map<String, dynamic>)).toList();

  List<PickupOrder> _decodeOrders(List<dynamic> rows) => rows
      .map((row) => PickupOrder.fromJson(row as Map<String, dynamic>))
      .toList();

  @override
  Future<void> requestCode(String phone) async {
    final result = await _call('auth/request', {'phone': phone});
    _demo = result['demo'] == true;
  }

  @override
  Future<void> verifyCode(String number, String code) async {
    final result = await _call('auth/verify', {'phone': number, 'code': code});
    _token = result['token'] as String;
    phone = number;
    notifyListeners();
    await refresh();
  }

  @override
  Future<void> signOut() async {
    try {
      if (_token.isNotEmpty) await _call('auth/logout', {});
    } on PilotError {
      // The in-memory session is discarded even when the connection is lost.
    } finally {
      _token = '';
      _clearAccount();
      ++_revision;
      notifyListeners();
      await refresh();
    }
  }

  Future<Map<String, dynamic>> _change(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await _call(path, body);
      await refresh();
      return result;
    } on PilotError {
      await refresh();
      rethrow;
    }
  }

  @override
  Future<PickupOrder> book(String boxId, int quantity, String requestId) async {
    final result = await _change('orders', {
      'boxId': boxId,
      'quantity': quantity,
      'requestId': requestId,
    });
    final booking = PickupOrder.fromJson(result);
    if (phone == booking.owner && order(booking.id) == null) {
      orders = [booking, ...orders];
      notifyListeners();
    }
    return booking;
  }

  @override
  Future<void> cancelBooking(PickupOrder order) async =>
      _change('orders/${order.id}/cancel', {});

  @override
  Future<void> saveReview(PickupOrder order) async => _change(
    'orders/${order.id}/review',
    {'rating': order.rating, 'feedback': order.feedback},
  );

  @override
  Future<void> submitIssue(PickupOrder order, String issue) async =>
      _change('orders/${order.id}/issue', {'issue': issue});

  @override
  Future<void> submitVenue({
    required String title,
    required String address,
    required String company,
    required int district,
    required double lat,
    required double lng,
  }) async => _change('venue', {
    'title': title,
    'address': address,
    'company': company,
    'district': district,
    'lat': lat,
    'lng': lng,
  });

  @override
  Future<void> publishBox(FoodBox box, String day) async =>
      _change('boxes', {...box.toJson(), 'day': day});

  @override
  Future<void> changeStock(FoodBox box, int stock) async =>
      _change('boxes/${box.id}/stock', {'expected': box.stock, 'stock': stock});

  @override
  Future<void> changeVisibility(FoodBox box, bool published) async =>
      _change('boxes/${box.id}/visibility', {'published': published});

  @override
  Future<PickupOrder> checkPickup(String code, String shop) async =>
      PickupOrder.fromJson(await _call('pickup/check', {'code': code}));

  @override
  Future<PickupOrder> finishPickup(
    String code,
    String shop,
    String orderId,
  ) async => PickupOrder.fromJson(
    await _change('pickup/collect', {'code': code, 'orderId': orderId}),
  );

  Future<void> changeStaff(String number, {required bool add}) async =>
      _change(add ? 'staff/add' : 'staff/remove', {'phone': number});

  Future<Map<String, dynamic>> adminSnapshot() => _call('admin');

  Future<void> adminAction(String path, Map<String, dynamic> body) async =>
      _change('admin/$path', body);
}
