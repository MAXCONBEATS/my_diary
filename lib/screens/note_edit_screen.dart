import 'package:flutter/material.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/models/category.dart';
import 'package:my_daily_plus/models/note.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({
    super.key,
    this.note,
    this.linkedEventId,
    this.linkedDay,
  });

  final Note? note;
  final int? linkedEventId;
  final DateTime? linkedDay;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int? _categoryId;
  DateTime? _linkedDay;

  bool get _isEdit => widget.note?.id != null;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n != null) {
      _title.text = n.title;
      _content.text = n.content ?? '';
      _categoryId = n.categoryId;
      _linkedDay = n.linkedDate != null
          ? DateTime.fromMillisecondsSinceEpoch(n.linkedDate!)
          : null;
    } else {
      _linkedDay = widget.linkedDay != null
          ? DateTime(
              widget.linkedDay!.year,
              widget.linkedDay!.month,
              widget.linkedDay!.day,
            )
          : null;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  int? _dayStartMillis(DateTime? d) {
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _linkedDay ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d != null) {
      setState(() => _linkedDay = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите заголовок')),
      );
      return;
    }
    final repo = AppScope.of(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = Note(
      id: widget.note?.id,
      title: title,
      content: _content.text.trim().isEmpty ? null : _content.text.trim(),
      categoryId: _categoryId,
      createdAt: widget.note?.createdAt ?? now,
      linkedDate: _dayStartMillis(_linkedDay),
    );

    int noteId;
    if (_isEdit) {
      await repo.updateNote(n);
      noteId = widget.note!.id!;
    } else {
      noteId = await repo.insertNote(n);
      if (widget.linkedEventId != null) {
        await repo.linkNoteToEvent(noteId, widget.linkedEventId!);
      }
    }
    if (mounted) Navigator.pop(context, noteId);
  }

  Future<void> _delete() async {
    final id = widget.note?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppScope.of(context).deleteNote(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Заметка' : 'Новая заметка'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: AppScope.of(context).getCategories(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _content,
                minLines: 6,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: 'Текст',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (cats.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _categoryId, // ignore: deprecated_member_use
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Без категории'),
                    ),
                    ...cats.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Привязка к дню'),
                subtitle: Text(
                  _linkedDay == null
                      ? 'Не выбрана'
                      : '${_linkedDay!.day}.${_linkedDay!.month}.${_linkedDay!.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _linkedDay = null),
                ),
                onTap: _pickDay,
              ),
            ],
          );
        },
      ),
    );
  }
}
