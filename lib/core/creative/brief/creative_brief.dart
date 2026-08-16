/// Creative brief (Step 40.4–40.6).
class CreativeBrief {
  const CreativeBrief({
    required this.id,
    required this.title,
    required this.genre,
    required this.tone,
    this.goals = const [],
  });

  final String id;
  final String title;
  final String genre;
  final String tone;
  final List<String> goals;

  bool get isValid => title.isNotEmpty && tone.isNotEmpty;

  factory CreativeBrief.fromMap(Map<String, dynamic> map) {
    return CreativeBrief(
      id: map['id'] as String,
      title: map['title'] as String,
      genre: map['genre'] as String? ?? '',
      tone: map['tone'] as String? ?? '',
      goals: (map['goals'] as List?)?.cast<String>() ?? const [],
    );
  }
}
