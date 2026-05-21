extension DateTimeExt on DateTime {
  String get toDateString => '$year-${_twoDigits(month)}-${_twoDigits(day)}';

  String get toTimeString =>
      '${_twoDigits(hour)}:${_twoDigits(minute)}:${_twoDigits(second)}';

  String get toDateTimeString => '$toDateString $toTimeString';

  String get toDisplayDate => '$year年${month}月${day}日';

  String get toDisplayDateTime => '$toDisplayDate ${_twoDigits(hour)}:${_twoDigits(minute)}';

  String get toRelativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';
    return '${(diff.inDays / 365).floor()}年前';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
