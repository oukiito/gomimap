// SPDX-License-Identifier: GPL-3.0-or-later

/// A civil date, independent of the device's time zone and daylight saving.
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(int year, int month, int day)
    : value = DateTime.utc(year, month, day) {
    if (year < 1 ||
        year > 9999 ||
        value.year != year ||
        value.month != month ||
        value.day != day) {
      throw FormatException('Invalid calendar date');
    }
  }
  final DateTime value;
  factory CalendarDate.parse(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      throw FormatException('Expected YYYY-MM-DD');
    }
    final parts = text.split('-').map(int.parse).toList();
    return CalendarDate(parts[0], parts[1], parts[2]);
  }
  factory CalendarDate.fromFields(DateTime date) =>
      CalendarDate(date.year, date.month, date.day);

  /// All municipalities in the Japan-only schema use Asia/Tokyo (UTC+09:00).
  factory CalendarDate.inJapan(DateTime instant) =>
      CalendarDate.fromFields(instant.toUtc().add(const Duration(hours: 9)));
  int get weekday => value.weekday;
  int get monthOccurrence => (value.day - 1) ~/ 7 + 1;
  CalendarDate addDays(int days) =>
      CalendarDate.fromFields(value.add(Duration(days: days)));
  DateTime get startInJapanUtc => value.subtract(const Duration(hours: 9));
  @override
  int compareTo(CalendarDate other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) =>
      other is CalendarDate && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value.toIso8601String().substring(0, 10);
}

/// Start is included; end is excluded throughout the dataset schema.
class DatePeriod {
  DatePeriod(this.start, this.end) {
    if (start.compareTo(end) >= 0) {
      throw FormatException('Empty or reversed date period');
    }
  }
  final CalendarDate start;
  final CalendarDate end;
  bool contains(CalendarDate date) =>
      start.compareTo(date) <= 0 && date.compareTo(end) < 0;
  bool overlaps(DatePeriod other) =>
      start.compareTo(other.end) < 0 && other.start.compareTo(end) < 0;
}

class LocalTime implements Comparable<LocalTime> {
  LocalTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('Invalid local time');
    }
  }
  final int hour;
  final int minute;
  factory LocalTime.parse(String text) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      throw FormatException('Expected HH:mm');
    }
    final parts = text.split(':').map(int.parse).toList();
    return LocalTime(parts[0], parts[1]);
  }
  @override
  int compareTo(LocalTime other) =>
      (hour * 60 + minute).compareTo(other.hour * 60 + other.minute);
  @override
  bool operator ==(Object other) =>
      other is LocalTime && hour == other.hour && minute == other.minute;
  @override
  int get hashCode => Object.hash(hour, minute);
  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
