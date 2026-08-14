abstract interface class AppCommand {
  String get id;

  String get projectId;

  String get label;

  Future<void> execute();

  Future<void> undo();

  Future<void> redo();
}

abstract class BaseCommand implements AppCommand {
  BaseCommand({required this.id, required this.projectId, required this.label});

  @override
  final String id;

  @override
  final String projectId;

  @override
  final String label;

  @override
  Future<void> redo() => execute();
}
