class SearchDocument {
  const SearchDocument({
    required this.entityId,
    required this.entityType,
    required this.title,
    required this.body,
  });

  final String entityId;
  final String entityType;
  final String title;
  final String body;
}
