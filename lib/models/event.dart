import 'package:flutter/material.dart';

/// Правило повторения: хранится в [recurrenceRule], [isRecurring] = true.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

class CalendarEvent {
  CalendarEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.colorHex,
    this.isRecurring = false,
    this.recurrenceRule,
    this.reminderMinutesBefore = 15,
  });

  final int? id;
  final String title;
  final String? description;
  final int startTime;
  final int endTime;
  final String colorHex;
  final bool isRecurring;
  final String? recurrenceRule;
  final int reminderMinutesBefore;

  DateTime get anchorStart => DateTime.fromMillisecondsSinceEpoch(startTime);
  DateTime get anchorEnd => DateTime.fromMillisecondsSinceEpoch(endTime);

  Duration get duration => anchorEnd.difference(anchorStart);

  RecurrenceType get recurrenceType {
    if (!isRecurring) return RecurrenceType.none;
    switch (recurrenceRule) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'yearly':
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.none;
    }
  }

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue;
  }

  /// Событие без повторения попадает только в день якоря.
  bool occursOnDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (!isRecurring || recurrenceType == RecurrenceType.none) {
      final s = anchorStart;
      return s.year == d.year && s.month == d.month && s.day == d.day;
    }
    final anchor = DateTime(anchorStart.year, anchorStart.month, anchorStart.day);
    if (d.isBefore(anchor)) return false;

    switch (recurrenceType) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        return d.weekday == anchor.weekday;
      case RecurrenceType.monthly:
        if (d.day != anchor.day) return false;
        return d.year > anchor.year ||
            (d.year == anchor.year && d.month >= anchor.month);
      case RecurrenceType.yearly:
        return d.month == anchor.month &&
            d.day == anchor.day &&
            d.year >= anchor.year;
      case RecurrenceType.none:
        return false;
    }
  }

  DateTime startOnDay(DateTime day) {
    final a = anchorStart;
    return DateTime(day.year, day.month, day.day, a.hour, a.minute, a.second);
  }

  DateTime endOnDay(DateTime day) => startOnDay(day).add(duration);

  factory CalendarEvent.fromMap(Map<String, Object?> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      title: map['title']! as String,
      description: map['description'] as String?,
      startTime: map['start_time']! as int,
      endTime: map['end_time']! as int,
      colorHex: (map['color'] as String?) ?? '#2196F3',
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      reminderMinutesBefore: map['reminder_minutes_before'] as int? ?? 15,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'color': colorHex,
        'is_recurring': isRecurring ? 1 : 0,
        'recurrence_rule': recurrenceRule,
        'reminder_minutes_before': reminderMinutesBefore,
      };

  CalendarEvent copyWith({
    int? id,
    String? title,
    String? description,
    int? startTime,
    int? endTime,
    String? colorHex,
    bool? isRecurring,
    String? recurrenceRule,
    int? reminderMinutesBefore,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}
