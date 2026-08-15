import 'layout_model.dart';

/// A named, saved layout (Step 27.3).
class LayoutPreset {
  const LayoutPreset({required this.name, required this.layout});

  final String name;
  final PanelLayout layout;
}
