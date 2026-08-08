import '../../core/utils/json.dart';

enum StockStatus { inStock, lowStock, outOfStock, unknown }

StockStatus stockStatusFrom(dynamic v) {
  switch (v?.toString()) {
    case 'IN_STOCK':
      return StockStatus.inStock;
    case 'LOW_STOCK':
      return StockStatus.lowStock;
    case 'OUT_OF_STOCK':
      return StockStatus.outOfStock;
    default:
      return StockStatus.unknown;
  }
}

class ProductImage {
  ProductImage({required this.url, this.isMain = false, this.sortOrder = 0});

  final String url;
  final bool isMain;
  final int sortOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        url: asString(json['url']),
        isMain: asBool(json['isMain']),
        sortOrder: asInt(json['sortOrder']),
      );
}

class Product {
  Product({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.price,
    this.discountPrice,
    required this.sku,
    this.tags = const [],
    this.images = const [],
    this.categoryId,
    this.categoryNameAr,
    this.stockStatus = StockStatus.unknown,
    this.quantity = 0,
    this.sellByCarton = false,
    this.unitsPerCarton,
    this.cartonPrice,
    this.halfKgPrice,
    this.kgPrice,
    this.pieceLabel,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final double? discountPrice;
  final String sku;
  final List<String> tags;
  final List<ProductImage> images;
  final String? categoryId;
  final String? categoryNameAr;
  final StockStatus stockStatus;
  final int quantity;
  final bool sellByCarton;
  final int? unitsPerCarton;
  final double? cartonPrice;
  final double? halfKgPrice;
  final double? kgPrice;
  final String? pieceLabel;

  bool get hasDiscount => discountPrice != null && discountPrice! > 0 && discountPrice! < price;
  double get effectivePrice => hasDiscount ? discountPrice! : price;
  bool get isOutOfStock => stockStatus == StockStatus.outOfStock;
  bool get hasCarton => sellByCarton && cartonPrice != null && cartonPrice! > 0;

  /// Every way this product can be bought. The base unit is always available;
  /// the rest appear only when the admin priced them.
  List<SaleOption> get saleOptions => [
        SaleOption(
          unit: 'PIECE',
          label: (pieceLabel?.trim().isNotEmpty ?? false) ? pieceLabel!.trim() : 'حبة',
          price: effectivePrice,
        ),
        if (halfKgPrice != null && halfKgPrice! > 0)
          SaleOption(unit: 'HALF_KG', label: 'نص كيلو', price: halfKgPrice!),
        if (kgPrice != null && kgPrice! > 0)
          SaleOption(unit: 'KG', label: 'كيلو', price: kgPrice!),
        if (hasCarton)
          SaleOption(
            unit: 'CARTON',
            label: unitsPerCarton != null ? 'كرتون ($unitsPerCarton حبة)' : 'كرتون',
            price: cartonPrice!,
          ),
      ];

  int get discountPercent =>
      hasDiscount ? (((price - discountPrice!) / price) * 100).round() : 0;

  String? get mainImage {
    if (images.isEmpty) return null;
    final main = images.firstWhere((i) => i.isMain, orElse: () => images.first);
    return main.url;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return Product(
      id: asString(json['id']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      price: asDouble(json['price']),
      discountPrice: json['discountPrice'] == null ? null : asDouble(json['discountPrice']),
      sku: asString(json['sku']),
      tags: ((json['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      images: ((json['images'] as List?) ?? const [])
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryId: category is Map ? asString(category['id']) : json['categoryId'] as String?,
      categoryNameAr: category is Map ? asString(category['nameAr']) : null,
      stockStatus: stockStatusFrom(json['stockStatus']),
      quantity: asInt(json['quantity']),
      sellByCarton: asBool(json['sellByCarton']),
      unitsPerCarton: json['unitsPerCarton'] == null ? null : asInt(json['unitsPerCarton']),
      cartonPrice: json['cartonPrice'] == null ? null : asDouble(json['cartonPrice']),
      halfKgPrice: json['halfKgPrice'] == null ? null : asDouble(json['halfKgPrice']),
      kgPrice: json['kgPrice'] == null ? null : asDouble(json['kgPrice']),
      pieceLabel: json['pieceLabel'] as String?,
    );
  }
}

/// One purchasable unit of a product (base unit, half kilo, kilo, carton).
class SaleOption {
  const SaleOption({required this.unit, required this.label, required this.price});

  /// API `SaleUnit` value sent with the add-to-cart request.
  final String unit;
  final String label;
  final double price;
}
