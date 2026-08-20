import 'studio_entity.dart';

enum StudioMode { overview, production, review }

class StudioModeRegistry {
  StudioMode _active = StudioMode.overview;

  StudioMode get active => _active;
  List<StudioMode> get available => List.unmodifiable(StudioMode.values);

  void activate(StudioMode mode) => _active = mode;
}

class StudioWorkspace {
  StudioWorkspace({required this.studio}) : _mode = StudioMode.overview;

  final StudioEntity studio;
  StudioMode _mode;

  StudioMode get mode => _mode;
  void setMode(StudioMode mode) => _mode = mode;
}
