import '../../core/utils/json.dart';
import 'address.dart';

enum OrderStatus {
  submitted,
  underReview,
  confirmationRequired,
  approved,
  preparing,
  ready,
  outForDelivery,
  delivered,
  pickedUp,
  rejected,
  cancelled,
  unknown,
}

extension OrderStatusX on OrderStatus {
  static OrderStatus from(dynamic v) {
    switch (v?.toString()) {
      case 'SUBMITTED':
        return OrderStatus.submitted;
      case 'UNDER_REVIEW':
        return OrderStatus.underReview;
      case 'CONFIRMATION_REQUIRED':
        return OrderStatus.confirmationRequired;
      case 'APPROVED':
        return OrderStatus.approved;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'PICKED_UP':
        return OrderStatus.pickedUp;
      case 'REJECTED':
        return OrderStatus.rejected;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  String get labelAr {
    switch (this) {
      case OrderStatus.submitted:
        return 'تم الإرسال';
      case OrderStatus.underReview:
        return 'قيد المراجعة';
      case OrderStatus.confirmationRequired:
        return 'بانتظار تأكيدك';
      case OrderStatus.approved:
        return 'تمت الموافقة';
      case OrderStatus.preparing:
        return 'قيد التجهيز';
      case OrderStatus.ready:
        return 'جاهز';
      case OrderStatus.outForDelivery:
        return 'في الطريق إليك';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.pickedUp:
        return 'تم الاستلام';
      case OrderStatus.rejected:
        return 'مرفوض';
      case OrderStatus.cancelled:
        return 'ملغي';
      case OrderStatus.unknown:
        return 'غير معروف';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.pickedUp ||
      this == OrderStatus.rejected ||
      this == OrderStatus.cancelled;

  bool get isActive => !isTerminal;
}

enum OrderItemAvailability { available, unavailable, partial, unknown }

OrderItemAvailability availabilityFrom(dynamic v) {
  switch (v?.toString()) {
    case 'AVAILABLE':
      return OrderItemAvailability.available;
    case 'UNAVAILABLE':
      return OrderItemAvailability.unavailable;
    case 'PARTIAL':
      return OrderItemAvailability.partial;
    default:
      return OrderItemAvailability.unknown;
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.nameAr,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.availability = OrderItemAvailability.available,
  });

  final String id;
  final String productId;
  final String nameAr;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final OrderItemAvailability availability;

  bool get isUnavailable => availability == OrderItemAvailability.unavailable;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: asString(json['id']),
        productId: asString(json['productId']),
        nameAr: asString(json['nameAr']),
        unitPrice: asDouble(json['unitPrice']),
        quantity: asInt(json['quantity']),
        lineTotal: asDouble(json['lineTotal']),
        availability: availabilityFrom(json['availability']),
      );
}

class OrderStatusEvent {
  OrderStatusEvent({required this.status, required this.createdAt, this.note});

  final OrderStatus status;
  final DateTime? createdAt;
  final String? note;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
        status: OrderStatusX.from(json['status']),
        createdAt: asDate(json['createdAt']),
        note: json['note'] as String?,
      );
}

enum FulfillmentType { delivery, pickup }

class Order {
  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.fulfillmentType,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.distanceMeters,
    this.etaMinutes,
    this.customerNote,
    this.rejectionReason,
    this.items = const [],
    this.statusHistory = const [],
    this.address,
    this.createdAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final FulfillmentType fulfillmentType;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int? distanceMeters;
  final int? etaMinutes;
  final String? customerNote;
  final String? rejectionReason;
  final List<OrderItem> items;
  final List<OrderStatusEvent> statusHistory;
  final Address? address;
  final DateTime? createdAt;

  bool get isDelivery => fulfillmentType == FulfillmentType.delivery;
  bool get needsConfirmation => status == OrderStatus.confirmationRequired;
  List<OrderItem> get unavailableItems => items.where((i) => i.isUnavailable).toList();

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: asString(json['id']),
        orderNumber: asString(json['orderNumber']),
        status: OrderStatusX.from(json['status']),
        fulfillmentType: json['fulfillmentType'] == 'PICKUP'
            ? FulfillmentType.pickup
            : FulfillmentType.delivery,
        subtotal: asDouble(json['subtotal']),
        deliveryFee: asDouble(json['deliveryFee']),
        total: asDouble(json['total']),
        distanceMeters: json['distanceMeters'] == null ? null : asInt(json['distanceMeters']),
        etaMinutes: json['etaMinutes'] == null ? null : asInt(json['etaMinutes']),
        customerNote: json['customerNote'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusHistory: ((json['statusHistory'] as List?) ?? const [])
            .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        address: json['address'] == null
            ? null
            : Address.fromJson(json['address'] as Map<String, dynamic>),
        createdAt: asDate(json['createdAt']) ?? asDate(json['submittedAt']),
      );
}
