import 'package:aldiafa/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> base(Map<String, dynamic> extra) => {
      'id': 'p1',
      'nameAr': 'مكسرات',
      'nameEn': 'Nuts',
      'price': 13,
      'sku': 'SKU-1',
      ...extra,
    };

void main() {
  test('weight units appear only when priced, labelled by pieceLabel', () {
    final p = Product.fromJson(base({'halfKgPrice': 30, 'kgPrice': 55, 'pieceLabel': 'علبة'}));
    expect(p.saleOptions.map((o) => o.unit).toList(), ['PIECE', 'HALF_KG', 'KG']);
    expect(p.saleOptions.map((o) => o.label).toList(), ['علبة', 'نص كيلو', 'كيلو']);
    expect(p.saleOptions.map((o) => o.price).toList(), [13.0, 30.0, 55.0]);
  });

  test('plain product keeps a single default option', () {
    final p = Product.fromJson(base({}));
    expect(p.saleOptions.length, 1);
    expect(p.saleOptions.single.label, 'حبة');
  });

  test('discount and carton still work alongside weights', () {
    final p = Product.fromJson(base({
      'discountPrice': 10,
      'kgPrice': 55,
      'sellByCarton': true,
      'unitsPerCarton': 12,
      'cartonPrice': 140,
    }));
    expect(p.saleOptions.map((o) => o.unit).toList(), ['PIECE', 'KG', 'CARTON']);
    expect(p.saleOptions.first.price, 10.0);
    expect(p.saleOptions.last.label, 'كرتون (12 حبة)');
  });
}
