import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/enums.dart';
import 'package:toidym/shared/models/order.dart';

/// Результат выдачи заказа по QR-коду или 4-значному PIN.
class PickupCompletionResult {
  const PickupCompletionResult({
    required this.order,
    required this.wasAlreadyPickedUp,
  });

  final Order order;
  final bool wasAlreadyPickedUp;
}

/// Нәтиже: 1 минуттық CRON Resale Worker немесе 15 мин спринт аяқталғандағы транзакция.
class ResaleWorkerResult {
  const ResaleWorkerResult({
    required this.expiredOrders,
    required this.updatedBoxes,
  });

  final List<Order> expiredOrders;
  final List<Box> updatedBoxes;

  bool get hasChanges => expiredOrders.isNotEmpty;
}

/// Интерфейс репозитория заказов (доверительное бронирование + офлайн-оплата на месте).
abstract interface class OrderRepository {
  Future<List<Order>> getOrders(String userId);

  Stream<List<Order>> watchOrders();

  Future<List<Order>> getVenuePendingOrders(String venueId);

  Future<List<Order>> getVenueAllOrders(String venueId);

  Future<Order?> getOrderById(String orderId);

  /// Создаёт бронь со статусом `RESERVED` (оплата на месте при получении).
  Future<Order> createReservation({
    required String userId,
    required String boxId,
    required String venueId,
    required int quantity,
    required int totalPrice,
    required int originalTotalPrice,
    bool isCharityBox = false,
  });

  Future<Order> cancelOrderByBuyer(String orderId);

  Future<Order> cancelOrderByVenue({
    required String orderId,
    required String reason,
  });

  /// Фиксация неявки `NO_SHOW` и начисление 1 Strike покупателю.
  Future<Order> markOrderNoShow(String orderId);

  /// 1 минуттық CRON жоспарлаушы (Resale Worker): 15-мин спринті біткен барлық RESERVED тапсырыстарды NO_SHOW жасап, +1 Strike беріп, боксты қайта сатылымға (Resale) шығарады.
  Future<ResaleWorkerResult> runResaleCronWorker([DateTime? now]);

  /// Нақты тапсырыс бойынша 15-мин спринт аяқталғанда (00:00) лезде атомарлы қайта сату (Resale) транзакциясы.
  Future<ResaleWorkerResult> expireOrderSprintNow(
    String orderId, [
    DateTime? now,
  ]);

  /// Выдача заказа заведением по QR или 4-значному PIN -> статус `COMPLETED`.
  Future<PickupCompletionResult> completePickup({
    required String venueId,
    String? qrCode,
    String? pinCode,
  });

  Future<Order> submitComplaint({
    required String orderId,
    required String note,
    List<String> photoPaths = const [],
  });

  Future<Order> resolveComplaint({
    required String orderId,
    required ComplaintStatus status,
    required String resolutionNote,
  });
}
