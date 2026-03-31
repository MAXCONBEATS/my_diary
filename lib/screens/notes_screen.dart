import 'package:flutter/material.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/note.dart';
import 'package:my_daily_plus/repositories/data_repository.dart';
import 'package:my_daily_plus/screens/note_detail_screen.dart';
import 'package:my_daily_plus/screens/note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Note>> _loadNotes(DataRepository repo) async {
    if (_query.trim().isEmpty) return repo.getAllNotes();
    return repo.searchNotes(_query);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Поиск по заголовку и тексту',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Note>>(
              key: ValueKey(_query),
              future: _loadNotes(repo),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notes = snap.data!;
                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                      'Заметок пока нет',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  );
                }
                return FutureBuilder<Map<int, String>>(
                  future: _categoryNames(repo),
                  builder: (context, catSnap) {
                    final names = catSnap.data ?? {};
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notes.length,
                      itemBuilder: (context, i) {
                        final n = notes[i];
                        final cat = n.categoryId != null
                            ? names[n.categoryId!]
                            : null;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(n.title),
                            subtitle: n.content != null &&
                                    n.content!.isNotEmpty
                                ? Text(
                                    n.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : (cat != null ? Text(cat) : null),
                            onTap: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NoteDetailScreen(noteId: n.id!),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const NoteEditScreen(),
            ),
          );
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Заметка'),
      ),
    );
  }

  Future<Map<int, String>> _categoryNames(DataRepository repo) async {
    final cats = await repo.getCategories();
    return {for (final c in cats) c.id: c.name};
  }
}
