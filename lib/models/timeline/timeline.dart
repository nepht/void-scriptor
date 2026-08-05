// Timeline Model — v1.0.0

class Timeline {
  final String id;
  final String name;
  final List<TimelineEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  Timeline({
    required this.id,
    required this.name,
    this.events = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'events': events.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Timeline.fromJson(Map<String, dynamic> json) => Timeline(
        id: json['id'] as String,
        name: json['name'] as String,
        events: (json['events'] as List? ?? [])
            .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category;

  TimelineEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.category = 'general',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'category': category,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        category: json['category'] as String? ?? 'general',
      );
}
