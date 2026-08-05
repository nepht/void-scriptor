// Story Model — v1.0.0

class Story {
  final String id;
  final String title;
  final String summary;
  final List<Chapter> chapters;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    this.summary = '',
    this.chapters = const [],
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String? ?? '',
        chapters: (json['chapters'] as List? ?? [])
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

class Chapter {
  final String id;
  final String title;
  final String content;
  final int number;
  final DateTime createdAt;

  Chapter({
    required this.id,
    required this.title,
    this.content = '',
    this.number = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'number': number,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        number: json['number'] as int? ?? 1,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
