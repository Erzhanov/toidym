import 'dart:async';
import 'dart:math' as math;

import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/auth_repository.dart';
import 'package:toidym/domain/repositories/box_repository.dart';
import 'package:toidym/domain/repositories/order_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';

class OrderException implements Exception {
  const OrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Мок-репозиторий заказов (доверительное бронирование RESERVED, 15-мин Спринт + Resale CRON, NO_SHOW + Strike, COMPLETED).
class MockOrderRepository implements OrderRepository {
  MockOrderRepository(
    this._boxRepository,
    this._authRepository,
    this._venueRepository,
  ) : _orders = SeedData.createOrders().toList();

  final BoxRepository _boxRepository;
  final AuthRepository _authRepository;
  final VenueRepository _venueRepository;
  final List<Order> _orders;
  final _controller = StreamController<List<Order>>.broadcast();
  final _rng = math.Random();
  int _nextNumber = 1235;

  void _emit() {
    _controller.add(List<Order>.unmodifiable(_orders));
  }

  @override
  Future<List<Order>> getOrders(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _orders
        .where((o) => o.userId == userId)
        .toList(growable: false);
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    yield List<Order>.unmodifiable(_orders);
    yield* _controller.stream;
  }

  @override
  Future<List<Order>> getVenuePendingOrders(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _orders
        .where((o) =>
            o.venueId == venueId && o.status.isActive && !o.isCharityBox)
        .toList(growable: false);
  }

  @override
  Future<List<Order>> getVenueAllOrders(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _orders
        .where((o) => o.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final order in _orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  @override
  Future<Order> createReservation({
    required String userId,
    required String boxId,
    required String venueId,
    required int quantity,
    required int totalPrice,
    required int originalTotalPrice,
    bool isCharityBox = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final currentUser = _authRepository.currentUser;
    if (currentUser != null && currentUser.isBanned) {
      throw const OrderException(
        'Ваш аккаунт временно ограничен из-за 3 неявок (Strikes)',
      );
    }

    await _boxRepository.decrementStock(boxId: boxId, quantity: quantity);

    final id = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final pin = (1000 + _rng.nextInt(9000)).toString();
    final orderNum = '#${_nextNumber++}';

    final order = Order(
      id: id,
      orderNumber: orderNum,
      userId: userId,
      boxId: boxId,
      venueId: venueId,
      quantity: quantity,
      totalPrice: totalPrice,
      originalTotalPrice: originalTotalPrice,
      status: isCharityBox ? OrderStatus.completed : OrderStatus.reserved,
      qrCode: 'TOIDYM:ORDER:$id:PIN:$pin',
      pinCode: pin,
      paymentMethod: PaymentMethod.onSite,
      createdAt: DateTime.now(),
      pickedUpAt: isCharityBox ? DateTime.now() : null,
      isCharityBox: isCharityBox,
    );

    _orders.insert(0, order);
    if (isCharityBox) {
      await _authRepository.recordSavedBoxes(
        boxesCount: quantity,
        savedMoneyTenge: order.savedAmount,
      );
    }
    _emit();
    return order;
  }

  @override
  Future<Order> cancelOrderByBuyer(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw const OrderException('Заказ не найден');

    final order = _orders[idx];
    final box = await _boxRepository.getBoxById(order.boxId);
    if (box == null) throw const OrderException('Бокс не найден');

    if (!BoxBusinessRules.canBuyerCancelOrder(order: order, box: box)) {
      throw const OrderException(
        'Отмена недоступна: до начала выдачи осталось меньше часа',
      );
    }

    final updated = order.copyWith(
      status: OrderStatus.cancelledByUser,
      cancellationReason: 'Отменено покупателем до закрытия окна',
    );
    _orders[idx] = updated;
    await _boxRepository.restoreStock(
      boxId: order.boxId,
      quantity: order.quantity,
    );
    _emit();
    return updated;
  }

  @override
  Future<Order> cancelOrderByVenue({
    required String orderId,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw const OrderException('Заказ не найден');

    final order = _orders[idx];
    final updated = order.copyWith(
      status: OrderStatus.cancelledByVenue,
      cancellationReason: 'Отменено заведением ($reason)',
    );
    _orders[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<Order> markOrderNoShow(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw const OrderException('Заказ не найден');

    final existing = _orders[idx];
    if (!existing.status.isActive) return existing;

    final updated = existing.copyWith(
      status: OrderStatus.noShow,
      cancellationReason: 'Неявка в окно выдачи (NO_SHOW · +1 Strike)',
    );
    _orders[idx] = updated;
    await _authRepository.addStrike(existing.userId);
    _emit();
    return updated;
  }

  Future<({Order order, Box box})?> _executeResaleTransition(
    int idx,
    DateTime currentTime,
  ) async {
    final existing = _orders[idx];
    if (!existing.status.isActive || existing.isCharityBox) return null;

    final box = await _boxRepository.getBoxById(existing.boxId);
    if (box == null) return null;

    final venue = await _venueRepository.getVenueById(existing.venueId);
    final resaleWindow = venue != null
        ? BoxBusinessRules.calculateResalePickupWindow(
            venue: venue,
            sprintWindow: box.pickupWindow,
            now: currentTime,
          )
        : PickupWindow(
            start: currentTime,
            end: currentTime.add(
              const Duration(
                minutes: BusinessRulesConfig.lastMinuteResaleDurationMinutes,
              ),
            ),
          );

    final updatedOrder = existing.copyWith(
      status: OrderStatus.noShow,
      cancellationReason: '15-мин спринт истёк (NO_SHOW · +1 Strike · Resale)',
    );
    _orders[idx] = updatedOrder;

    await _authRepository.addStrike(existing.userId);
    final updatedBox = await _boxRepository.requeueForResale(
      boxId: box.id,
      quantityDelta: existing.quantity,
      resaleWindow: resaleWindow,
    );
    return (order: updatedOrder, box: updatedBox);
  }

  @override
  Future<ResaleWorkerResult> runResaleCronWorker([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final expiredOrders = <Order>[];
    final updatedBoxes = <Box>[];

    for (var i = 0; i < _orders.length; i++) {
      final candidate = _orders[i];
      if (!candidate.status.isActive || candidate.isCharityBox) continue;

      final box = await _boxRepository.getBoxById(candidate.boxId);
      if (box == null || box.isResale) continue;

      // Если наступило время окончания 15-минутного окна (напр. 19:15) и заказ не COMPLETED -> Resale
      if (!currentTime.isBefore(box.pickupWindow.end)) {
        final result = await _executeResaleTransition(i, currentTime);
        if (result != null) {
          expiredOrders.add(result.order);
          updatedBoxes.add(result.box);
        }
      }
    }

    if (expiredOrders.isNotEmpty) {
      _emit();
    }
    return ResaleWorkerResult(
      expiredOrders: expiredOrders,
      updatedBoxes: updatedBoxes,
    );
  }

  @override
  Future<ResaleWorkerResult> expireOrderSprintNow(
    String orderId, [
    DateTime? now,
  ]) async {
    final currentTime = now ?? DateTime.now();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) {
      return const ResaleWorkerResult(expiredOrders: [], updatedBoxes: []);
    }

    final result = await _executeResaleTransition(idx, currentTime);
    if (result == null) {
      return const ResaleWorkerResult(expiredOrders: [], updatedBoxes: []);
    }

    _emit();
    return ResaleWorkerResult(
      expiredOrders: [result.order],
      updatedBoxes: [result.box],
    );
  }

  @override
  Future<PickupCompletionResult> completePickup({
    required String venueId,
    String? qrCode,
    String? pinCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalizedQr = qrCode?.trim();
    final normalizedPin = pinCode?.replaceAll(' ', '').trim();

    final idx = _orders.indexWhere((o) {
      if (o.venueId != venueId) return false;
      final matchesQr =
          normalizedQr != null && normalizedQr.isNotEmpty && o.qrCode == normalizedQr;
      final matchesPin =
          normalizedPin != null && normalizedPin.isNotEmpty && o.pinCode == normalizedPin;
      return matchesQr || matchesPin;
    });

    if (idx == -1) {
      throw const OrderException('Заказ с таким QR или кодом не найден');
    }

    final existing = _orders[idx];
    if (existing.status == OrderStatus.completed) {
      return PickupCompletionResult(order: existing, wasAlreadyPickedUp: true);
    }
    if (!existing.status.isActive) {
      throw const OrderException('Этот заказ уже отменён или истёк');
    }

    final updated = existing.copyWith(
      status: OrderStatus.completed,
      pickedUpAt: DateTime.now(),
    );
    _orders[idx] = updated;

    await _authRepository.recordSavedBoxes(
      boxesCount: updated.quantity,
      savedMoneyTenge: updated.savedAmount,
    );
    _emit();
    return PickupCompletionResult(order: updated, wasAlreadyPickedUp: false);
  }

  @override
  Future<Order> submitComplaint({
    required String orderId,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw const OrderException('Заказ не найден');

    final existing = _orders[idx];
    if (!BoxBusinessRules.canSubmitComplaint(order: existing)) {
      throw const OrderException(
        'Жалобу можно подать в течение 24 часов после получения заказа',
      );
    }

    final updated = existing.copyWith(
      complaintSubmitted: true,
      complaintStatus: ComplaintStatus.open,
      complaintNote: note,
      complaintPhotoPaths: photoPaths,
      complaintSubmittedAt: DateTime.now(),
    );
    _orders[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<Order> resolveComplaint({
    required String orderId,
    required ComplaintStatus status,
    required String resolutionNote,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw const OrderException('Заказ не найден');

    final existing = _orders[idx];
    final updated = existing.copyWith(
      complaintSubmitted: true,
      complaintStatus: status,
      complaintResolutionNote: resolutionNote,
    );
    _orders[idx] = updated;
    _emit();
    return updated;
  }
}
