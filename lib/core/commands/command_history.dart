import 'app_command.dart';

class CommandHistory {
  CommandHistory({this.capacity = 200}) : assert(capacity > 0);

  final int capacity;
  final List<AppCommand> _undoStack = [];
  final List<AppCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  String? get undoLabel => canUndo ? _undoStack.last.label : null;
  String? get redoLabel => canRedo ? _redoStack.last.label : null;

  Future<void> execute(AppCommand command) async {
    await command.execute();
    _undoStack.add(command);
    _redoStack.clear();
    _trimUndoStack();
  }

  Future<void> push(AppCommand command) async {
    _undoStack.add(command);
    _redoStack.clear();
    _trimUndoStack();
  }

  Future<void> undo() async {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    try {
      await command.undo();
      _redoStack.add(command);
    } catch (_) {
      _undoStack.add(command);
      rethrow;
    }
  }

  Future<void> redo() async {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    try {
      await command.redo();
      _undoStack.add(command);
      _trimUndoStack();
    } catch (_) {
      _redoStack.add(command);
      rethrow;
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _trimUndoStack() {
    if (_undoStack.length <= capacity) return;
    _undoStack.removeRange(0, _undoStack.length - capacity);
  }
}
