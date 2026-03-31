import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/models/note.dart';
import 'package:my_daily_plus/screens/event_edit_screen.dart';
import 'package:my_daily_plus/screens/note_detail_screen.dart';
import 'package:my_daily_plus/screens/note_edit_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.dayContext,
  });

  final int eventId;
  final DateTime dayContext;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<void> _reload() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final df = DateFormat('d MMMM yyyy, HH:mm', 'ru');

    return FutureBuilder(
      future: repo.getEventById(widget.eventId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final e = snap.data!;
        final start = e.startOnDay(widget.dayContext);
        final end = e.endOnDay(widget.dayContext);

        return Scaffold(
          appBar: AppBar(
            title: Text(e.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventEditScreen(event: e),
                    ),
                  );
                  await _reload();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: e.color,
                    child: const Icon(Icons.event, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${df.format(start)} — ${DateFormat.Hm('ru').format(end)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (e.isRecurring)
                          Text(
                            'Повтор: ${_recLabel(e)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (e.description != null && e.description!.isNotEmpty)
                Text(e.description!),
              const SizedBox(height: 24),
              Text(
                'Связанные заметки',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Note>>(
                future: repo.getNotesLinkedToEvent(widget.eventId),
                builder: (context, ns) {
                  if (!ns.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = ns.data!;
                  if (list.isEmpty) {
                    return Text(
                      'Пока нет связанных заметок',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    );
                  }
                  return Column(
                    children: list
                        .map(
                          (n) => Card(
                            child: ListTile(
                              title: Text(n.title),
                              onTap: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoteDetailScreen(noteId: n.id!),
                                  ),
                                );
                                await _reload();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteEditScreen(
                        linkedEventId: widget.eventId,
                        linkedDay: widget.dayContext,
                      ),
                    ),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Добавить заметку к событию'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _recLabel(CalendarEvent e) {
    switch (e.recurrenceType) {
      case RecurrenceType.daily:
        return 'ежедневно';
      case RecurrenceType.weekly:
        return 'еженедельно';
      case RecurrenceType.monthly:
        return 'ежемесячно';
      case RecurrenceType.yearly:
        return 'ежегодно';
      case RecurrenceType.none:
        return '';
    }
  }
}
