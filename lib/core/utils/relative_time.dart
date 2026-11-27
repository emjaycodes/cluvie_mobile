import 'package:intl/intl.dart';

/// "now", "5m", "3h", "2d", then a date ("12 Mar", or "12 Mar 2025" in an
/// earlier year). Short, for post headers.
String timeAgo(DateTime when, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final d = n.difference(when);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return when.year == n.year ? DateFormat('d MMM').format(when) : DateFormat('d MMM y').format(when);
}

/// The spoken form of [timeAgo]: "just now", "5 minutes ago", "on 12 March".
String timeAgoSpoken(DateTime when, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final d = n.difference(when);
  String plural(int v, String unit) => '$v $unit${v == 1 ? '' : 's'} ago';
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return plural(d.inMinutes, 'minute');
  if (d.inDays < 1) return plural(d.inHours, 'hour');
  if (d.inDays < 7) return plural(d.inDays, 'day');
  return 'on ${DateFormat('d MMMM y').format(when)}';
}

/// Time left until [end]: "2d 4h", "5h 12m", "12m", "under a minute".
/// Null once [end] has passed.
String? timeLeft(DateTime end, {DateTime? now}) {
  final d = end.difference(now ?? DateTime.now());
  if (d.isNegative || d == Duration.zero) return null;
  if (d.inDays >= 1) {
    final h = d.inHours % 24;
    return h == 0 ? '${d.inDays}d' : '${d.inDays}d ${h}h';
  }
  if (d.inHours >= 1) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours}h' : '${d.inHours}h ${m}m';
  }
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return 'under a minute';
}

/// When [end] is, in words: "today at 20:00", "tomorrow at 9:30 AM",
/// "Fri 28 Nov at 20:00".
///
/// [use24h] follows the device (`MediaQuery.alwaysUse24HourFormatOf`);
/// false gives the locale's 12-hour form.
String dayAndTime(DateTime end, {DateTime? now, bool use24h = true}) {
  final n = now ?? DateTime.now();
  // Calendar days compared as UTC dates, so a DST change (a 23h or 25h
  // day) can't turn "tomorrow" into "today".
  final today = DateTime.utc(n.year, n.month, n.day);
  final day = DateTime.utc(end.year, end.month, end.day);
  final time = (use24h ? DateFormat.Hm() : DateFormat.jm()).format(end);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'today at $time';
  if (diff == 1) return 'tomorrow at $time';
  return '${DateFormat('EEE d MMM').format(end)} at $time';
}
