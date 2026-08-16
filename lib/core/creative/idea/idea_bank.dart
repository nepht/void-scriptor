/// A creative idea (Step 40.7).
class Idea {
  const Idea({
    required this.id,
    required this.title,
    required this.description,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
}

/// Idea bank with tag query and dedupe (Step 40.8–40.9).
class IdeaBank {
  final Map<String, Idea> _ideas = {};

  void add(Idea idea) => _ideas.putIfAbsent(idea.title, () => idea);

  List<Idea> get all => List.unmodifiable(_ideas.values);

  List<Idea> queryByTag(String tag) => [
    for (final idea in _ideas.values)
      if (idea.tags.contains(tag)) idea,
  ];
}
