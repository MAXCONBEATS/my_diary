class Note {
  Note({
    this.id,
    required this.title,
    this.content,
    this.categoryId,
    required this.createdAt,
    this.linkedDate,
  });

  final int? id;
  final String title;
  final String? content;
  final int? categoryId;
  final int createdAt;
  /// Начало календарного дня (локальное), к которому привязана заметка.
  final int? linkedDate;

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title']! as String,
      content: map['content'] as String?,
      categoryId: map['category_id'] as int?,
      createdAt: map['created_at']! as int,
      linkedDate: map['linked_date'] as int?,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'category_id': categoryId,
        'created_at': createdAt,
        'linked_date': linkedDate,
      };

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? categoryId,
    int? createdAt,
    int? linkedDate,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      linkedDate: linkedDate ?? this.linkedDate,
    );
  }
}
