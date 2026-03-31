import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/services/notification_service.dart';

const _palette = <String>[
  '#E53935',
  '#FB8C00',
  '#43A047',
  '#1E88E5',
  '#8E24AA',
  '#5D4037',
  '#546E7A',
];

class EventEditScreen extends StatefulWidget {
  const EventEditScreen({
    super.key,
    this.event,
    this.initialDay,
  });

  final CalendarEvent? event;
  final DateTime? initialDay;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late DateTime _start;
  late DateTime _end;
  String _color = _palette[3];
  RecurrenceType _rec = RecurrenceType.none;
  int _reminder = 15;

  bool get _isEdit => widget.event?.id != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final day = widget.initialDay ?? DateTime.now();
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description ?? '';
      _start = e.anchorStart;
      _end = e.anchorEnd;
      _color = e.colorHex;
      _rec = e.recurrenceType;
      _reminder = e.reminderMinutesBefore;
    } else {
      _start = DateTime(day.year, day.month, day.day, 9, 0);
      _end = DateTime(day.year, day.month, day.day, 10, 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  String? _recurrenceToRule(RecurrenceType t) {
    switch (t) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return 'daily';
      case RecurrenceType.weekly:
        return 'weekly';
      case RecurrenceType.monthly:
        return 'monthly';
      case RecurrenceType.yearly:
        return 'yearly';
    }
  }

  Future<void> _pickDateTime({required bool start}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start ? _start : _end),
    );
    if (t == null || !mounted) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (start) {
        _start = dt;
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название')),
      );
      return;
    }
    final repo = AppScope.of(context);
    final ev = CalendarEvent(
      id: widget.event?.id,
      title: title,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      startTime: _start.millisecondsSinceEpoch,
      endTime: _end.millisecondsSinceEpoch,
      colorHex: _color,
      isRecurring: _rec != RecurrenceType.none,
      recurrenceRule: _recurrenceToRule(_rec),
      reminderMinutesBefore: _reminder,
    );
    if (_isEdit) {
      await repo.updateEvent(ev);
    } else {
      final id = await repo.insertEvent(ev);
      await NotificationService.instance.scheduleEventReminder(ev.copyWith(id: id));
      if (mounted) Navigator.pop(context);
      return;
    }
    await NotificationService.instance.scheduleEventReminder(ev);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.event?.id;
    if (id == null) return;
    final repo = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить событие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await NotificationService.instance.cancelEventReminder(id);
    if (!mounted) return;
    await repo.deleteEvent(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Событие' : 'Новое событие'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Описание',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Начало'),
            subtitle: Text(df.format(_start)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDateTime(start: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Конец'),
            subtitle: Text(df.format(_end)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDateTime(start: false),
          ),
          const SizedBox(height: 8),
          Text('Цвет', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final sel = _color == c;
              return InkWell(
                onTap: () => setState(() => _color = c),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF${c.replaceFirst('#', '')}', radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RecurrenceType>(
            value: _rec, // ignore: deprecated_member_use
            decoration: const InputDecoration(
              labelText: 'Повторение',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: RecurrenceType.none, child: Text('Не повторять')),
              DropdownMenuItem(value: RecurrenceType.daily, child: Text('Ежедневно')),
              DropdownMenuItem(value: RecurrenceType.weekly, child: Text('Еженедельно')),
              DropdownMenuItem(value: RecurrenceType.monthly, child: Text('Ежемесячно')),
              DropdownMenuItem(value: RecurrenceType.yearly, child: Text('Ежегодно')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _rec = v);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _reminder, // ignore: deprecated_member_use
            decoration: const InputDecoration(
              labelText: 'Напоминание за',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Без напоминания')),
              DropdownMenuItem(value: 5, child: Text('5 минут')),
              DropdownMenuItem(value: 15, child: Text('15 минут')),
              DropdownMenuItem(value: 30, child: Text('30 минут')),
              DropdownMenuItem(value: 60, child: Text('1 час')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _reminder = v);
            },
          ),
        ],
      ),
    );
  }
}
