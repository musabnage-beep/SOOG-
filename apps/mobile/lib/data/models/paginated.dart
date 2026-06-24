import '../../core/utils/json.dart';

class Paginated<T> {
  Paginated({required this.items, required this.total, required this.page, required this.totalPages});

  final List<T> items;
  final int total;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory Paginated.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    final meta = (json['meta'] as Map?) ?? const {};
    return Paginated(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(),
      total: asInt(meta['total']),
      page: asInt(meta['page'], 1),
      totalPages: asInt(meta['totalPages'], 1),
    );
  }
}
