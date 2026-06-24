import '../../core/utils/json.dart';
import 'product.dart';

class CartLine {
  CartLine({
    required this.id,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    this.image,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.stockStatus = StockStatus.unknown,
  });

  final String id;
  final String productId;
  final String nameAr;
  final String nameEn;
  final String? image;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final StockStatus stockStatus;

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        id: asString(json['id']),
        productId: asString(json['productId']),
        nameAr: asString(json['nameAr']),
        nameEn: asString(json['nameEn']),
        image: json['image'] as String?,
        unitPrice: asDouble(json['unitPrice']),
        quantity: asInt(json['quantity']),
        lineTotal: asDouble(json['lineTotal']),
        stockStatus: stockStatusFrom(json['stockStatus']),
      );
}

class Cart {
  Cart({required this.items, required this.subtotal, required this.itemCount});

  final List<CartLine> items;
  final double subtotal;
  final int itemCount;

  int get totalQuantity => items.fold(0, (sum, l) => sum + l.quantity);
  bool get isEmpty => items.isEmpty;

  static Cart empty() => Cart(items: const [], subtotal: 0, itemCount: 0);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: ((json['items'] as List?) ?? const [])
            .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: asDouble(json['subtotal']),
        itemCount: asInt(json['itemCount']),
      );
}
