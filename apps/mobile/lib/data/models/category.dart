import '../../core/utils/json.dart';

class Category {
  Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.icon,
    this.sortOrder = 0,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String? icon;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: asString(json['id']),
        nameAr: asString(json['nameAr']),
        nameEn: asString(json['nameEn']),
        slug: asString(json['slug']),
        icon: json['icon'] as String?,
        sortOrder: asInt(json['sortOrder']),
      );
}
