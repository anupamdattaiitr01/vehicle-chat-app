class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatMessageTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final month = _months[date.month - 1];

      int hour = date.hour;
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      final minute = date.minute.toString().padLeft(2, '0');

      return '$month ${date.day}, $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}