import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/models/note.dart';
import 'package:my_daily_plus/repositories/data_repository.dart';
import 'package:my_daily_plus/screens/event_detail_screen.dart';
import 'package:my_daily_plus/screens/event_edit_screen.dart';
import 'package:my_daily_plus/screens/note_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';

enum _CalView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  _CalView _view = _CalView.month;

  final _dateFmt = DateFormat('d MMMM yyyy', 'ru');

  void _applyView(_CalView v) {
    setState(() {
      _view = v;
      switch (v) {
        case _CalView.month:
          _format = CalendarFormat.month;
          break;
        case _CalView.week:
          _format = CalendarFormat.week;
          break;
        case _CalView.day:
          _format = CalendarFormat.week;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой Ежедневник+'),
        actions: [
          IconButton(
            tooltip: 'Новое событие',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => EventEditScreen(
                    initialDay: _selected,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_CalView>(
              segments: const [
                ButtonSegment(
                  value: _CalView.month,
                  label: Text('Месяц'),
                  icon: Icon(Icons.calendar_view_month, size: 18),
                ),
                ButtonSegment(
                  value: _CalView.week,
                  label: Text('Неделя'),
                  icon: Icon(Icons.view_week, size: 18),
                ),
                ButtonSegment(
                  value: _CalView.day,
                  label: Text('День'),
                  icon: Icon(Icons.view_day, size: 18),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                _applyView(s.first);
              },
            ),
          ),
          TableCalendar<void>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(_selected, d),
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Месяц',
              CalendarFormat.twoWeeks: '2 нед',
              CalendarFormat.week: 'Неделя',
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'ru_RU',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: colorScheme.error),
            ),
            onDaySelected: (sel, foc) {
              setState(() {
                _selected = sel;
                _focused = foc;
              });
            },
            onPageChanged: (f) => setState(() => _focused = f),
            eventLoader: (day) {
              return const [];
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Object>>(
              future: _loadDay(repo, _selected),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snap.data![0] as List<CalendarEvent>;
                final notes = snap.data![1] as List<Note>;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      _view == _CalView.day
                          ? 'День: ${_dateFmt.format(_selected)}'
                          : 'Выбрано: ${_dateFmt.format(_selected)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'События',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      Text(
                        'Нет событий',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      )
                    else
                      ...events.map(
                        (e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: e.color,
                              child: const Icon(Icons.event, color: Colors.white, size: 20),
                            ),
                            title: Text(e.title),
                            subtitle: Text(
                              '${DateFormat.Hm('ru').format(e.startOnDay(_selected))} — ${DateFormat.Hm('ru').format(e.endOnDay(_selected))}',
                            ),
                            onTap: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(
                                    eventId: e.id!,
                                    dayContext: _selected,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Заметки этого дня',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (notes.isEmpty)
                      Text(
                        'Нет заметок',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      )
                    else
                      ...notes.map(
                        (n) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.sticky_note_2_outlined),
                            title: Text(n.title),
                            subtitle: n.content != null && n.content!.isNotEmpty
                                ? Text(
                                    n.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailScreen(noteId: n.id!),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Object>> _loadDay(DataRepository repo, DateTime day) async {
    final ev = await repo.getEventsForDay(day);
    final nt = await repo.getNotesForDay(day);
    return [ev, nt];
  }
}
