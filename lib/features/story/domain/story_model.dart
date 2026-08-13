class StoryModel {
  const StoryModel({
    required this.assetId,
    required this.projectId,
    required this.title,
    this.synopsis = '',
    this.genre = '',
    this.status = '',
    this.notes = '',
  });

  final String assetId;
  final String projectId;
  final String title;
  final String synopsis;
  final String genre;
  final String status;
  final String notes;
}
