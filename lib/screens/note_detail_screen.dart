import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/event.dart';
import 'package:my_daily_plus/screens/event_detail_screen.dart';
import 'package:my_daily_plus/screens/note_edit_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Future<void> _reload() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return FutureBuilder(
      future: repo.getNoteById(widget.noteId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final n = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(n.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteEditScreen(note: n),
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
              if (n.linkedDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'День: ${DateFormat.yMMMMd('ru').format(DateTime.fromMillisecondsSinceEpoch(n.linkedDate!))}',
                      ),
                    ],
                  ),
                ),
              SelectableText(
                n.content ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Связанные события',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<int>>(
                future: repo.getLinkedEventIdsForNote(widget.noteId),
                builder: (context, evSnap) {
                  if (!evSnap.hasData) {
                    return const SizedBox.shrink();
                  }
                  final ids = evSnap.data!;
                  if (ids.isEmpty) {
                    return Text(
                      'Нет привязки к событиям',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    );
                  }
                  return Column(
                    children: ids.map((id) {
                      return FutureBuilder<CalendarEvent?>(
                        future: repo.getEventById(id),
                        builder: (context, eSnap) {
                          final e = eSnap.data;
                          if (e == null) return const SizedBox.shrink();
                          final day = e.anchorStart;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: e.color,
                                child: const Icon(Icons.event, color: Colors.white, size: 20),
                              ),
                              title: Text(e.title),
                              subtitle: Text(
                                DateFormat.yMMMd('ru').format(day),
                              ),
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailScreen(
                                      eventId: id,
                                      dayContext: day,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
