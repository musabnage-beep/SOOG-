import 'package:intl/intl.dart';

abstract class Formatters {
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ر.س',
    decimalDigits: 2,
  );

  static String money(num value) => _money.format(value);

  static String date(DateTime date) =>
      DateFormat('d MMM y • h:mm a', 'ar').format(date.toLocal());

  static String shortDate(DateTime date) => DateFormat('d MMM y', 'ar').format(date.toLocal());

  static String distance(int meters) {
    if (meters < 1000) return '$meters م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  static String eta(int minutes) {
    if (minutes < 60) return '$minutes دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h ساعة' : '$h س $m د';
  }
}
