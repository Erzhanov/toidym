import 'package:flutter/foundation.dart';
import 'package:toidym/shared/models/enums.dart';

/// Модель заказа покупателя.
@immutable
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.boxId,
    required this.venueId,
    required this.quantity,
    required this.totalPrice,
    required this.originalTotalPrice,
    required this.status,
    required this.qrCode,
    required this.pinCode,
    required this.paymentMethod,
    required this.createdAt,
    this.pickedUpAt,
    this.cancellationReason,
    this.complaintSubmitted = false,
    this.complaintStatus = ComplaintStatus.none,
    this.complaintNote,
    this.complaintResolutionNote,
    this.complaintPhotoPaths = const [],
    this.complaintSubmittedAt,
    this.isCharityBox = false,
  });

  final String id;
  final String orderNumber;
  final String userId;
  final String boxId;
  final String venueId;
  final int quantity;
  final int totalPrice;
  final int originalTotalPrice;
  final OrderStatus status;
  final String qrCode;
  final String pinCode;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final String? cancellationReason;
  final bool complaintSubmitted;
  final ComplaintStatus complaintStatus;
  final String? complaintNote;
  final String? complaintResolutionNote;
  final List<String> complaintPhotoPaths;
  final DateTime? complaintSubmittedAt;
  final bool isCharityBox;

  int get savedAmount =>
      (originalTotalPrice - totalPrice).clamp(0, originalTotalPrice);

  String get formattedPin => pinCode.split('').join(' ');

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? boxId,
    String? venueId,
    int? quantity,
    int? totalPrice,
    int? originalTotalPrice,
    OrderStatus? status,
    String? qrCode,
    String? pinCode,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? pickedUpAt,
    String? cancellationReason,
    bool? complaintSubmitted,
    ComplaintStatus? complaintStatus,
    String? complaintNote,
    String? complaintResolutionNote,
    List<String>? complaintPhotoPaths,
    DateTime? complaintSubmittedAt,
    bool? isCharityBox,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      boxId: boxId ?? this.boxId,
      venueId: venueId ?? this.venueId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      originalTotalPrice: originalTotalPrice ?? this.originalTotalPrice,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      pinCode: pinCode ?? this.pinCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      complaintSubmitted: complaintSubmitted ?? this.complaintSubmitted,
      complaintStatus: complaintStatus ?? this.complaintStatus,
      complaintNote: complaintNote ?? this.complaintNote,
      complaintResolutionNote:
          complaintResolutionNote ?? this.complaintResolutionNote,
      complaintPhotoPaths: complaintPhotoPaths ?? this.complaintPhotoPaths,
      complaintSubmittedAt: complaintSubmittedAt ?? this.complaintSubmittedAt,
      isCharityBox: isCharityBox ?? this.isCharityBox,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'userId': userId,
        'boxId': boxId,
        'venueId': venueId,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'originalTotalPrice': originalTotalPrice,
        'status': status.apiValue,
        'qrCode': qrCode,
        'pinCode': pinCode,
        'paymentMethod': paymentMethod.apiValue,
        'createdAt': createdAt.toIso8601String(),
        'pickedUpAt': pickedUpAt?.toIso8601String(),
        'cancellationReason': cancellationReason,
        'complaintSubmitted': complaintSubmitted,
        'complaintStatus': complaintStatus.apiValue,
        'complaintNote': complaintNote,
        'complaintResolutionNote': complaintResolutionNote,
        'complaintPhotoPaths': complaintPhotoPaths,
        'complaintSubmittedAt': complaintSubmittedAt?.toIso8601String(),
        'isCharityBox': isCharityBox,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    final submitted = json['complaintSubmitted'] as bool? ?? false;
    return Order(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '#0000',
      userId: json['userId'] as String? ?? '',
      boxId: json['boxId'] as String? ?? '',
      venueId: json['venueId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      originalTotalPrice: (json['originalTotalPrice'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromApi(json['status'] as String?),
      qrCode: json['qrCode'] as String? ?? '',
      pinCode: json['pinCode'] as String? ?? '0000',
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      pickedUpAt: DateTime.tryParse(json['pickedUpAt'] as String? ?? ''),
      cancellationReason: json['cancellationReason'] as String?,
      complaintSubmitted: submitted,
      complaintStatus: json['complaintStatus'] != null
          ? ComplaintStatus.fromApi(json['complaintStatus'] as String?)
          : (submitted ? ComplaintStatus.open : ComplaintStatus.none),
      complaintNote: json['complaintNote'] as String?,
      complaintResolutionNote: json['complaintResolutionNote'] as String?,
      complaintPhotoPaths: (json['complaintPhotoPaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      complaintSubmittedAt:
          DateTime.tryParse(json['complaintSubmittedAt'] as String? ?? ''),
      isCharityBox: json['isCharityBox'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Order &&
        other.id == id &&
        other.orderNumber == orderNumber &&
        other.userId == userId &&
        other.boxId == boxId &&
        other.venueId == venueId &&
        other.quantity == quantity &&
        other.totalPrice == totalPrice &&
        other.originalTotalPrice == originalTotalPrice &&
        other.status == status &&
        other.qrCode == qrCode &&
        other.pinCode == pinCode &&
        other.paymentMethod == paymentMethod &&
        other.createdAt == createdAt &&
        other.pickedUpAt == pickedUpAt &&
        other.cancellationReason == cancellationReason &&
        other.complaintSubmitted == complaintSubmitted &&
        other.complaintStatus == complaintStatus &&
        other.complaintNote == complaintNote &&
        other.complaintResolutionNote == complaintResolutionNote &&
        listEquals(other.complaintPhotoPaths, complaintPhotoPaths) &&
        other.complaintSubmittedAt == complaintSubmittedAt &&
        other.isCharityBox == isCharityBox;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        orderNumber,
        userId,
        boxId,
        venueId,
        quantity,
        totalPrice,
        originalTotalPrice,
        status,
        qrCode,
        pinCode,
        paymentMethod,
        createdAt,
        pickedUpAt,
        cancellationReason,
        complaintSubmitted,
        complaintStatus,
        complaintNote,
        complaintResolutionNote,
        Object.hashAll(complaintPhotoPaths),
        complaintSubmittedAt,
        isCharityBox,
      ]);
}
