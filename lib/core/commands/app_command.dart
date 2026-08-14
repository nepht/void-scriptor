abstract interface class AppCommand {
  String get id;

  String get projectId;

  String get label;

  Future<void> execute();

  Future<void> undo();

  Future<void> redo();

  String get commandType;

  Map<String, Object?> get payload;

  Map<String, Object?>? get undoPayload;

  String get source;
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
  String get commandType => id;

  @override
  Map<String, Object?> get payload => const {};

  @override
  Map<String, Object?>? get undoPayload => null;

  @override
  String get source => 'user';

  @override
  Future<void> redo() => execute();
}
