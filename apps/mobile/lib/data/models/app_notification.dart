import '../../core/utils/json.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.payload,
  });

  final String id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? payload;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: asString(json['id']),
        title: asString(json['title']),
        body: asString(json['body']),
        type: json['type'] as String?,
        isRead: asBool(json['read'] ?? json['isRead']),
        createdAt: asDate(json['createdAt']),
        payload: json['payload'] as Map<String, dynamic>?,
      );
}
