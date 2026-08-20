import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/studio_entity.dart';
import 'package:void_scriptor/features/studio/domain/studio_workspace.dart';

void main() {
  test('creates an immutable studio entity with a stable id', () {
    const studio = StudioEntity(id: 'studio-1', name: 'Void Studio');
    expect(studio.id, 'studio-1');
    expect(studio.name, 'Void Studio');
    expect(studio.copyWith(name: 'Updated').id, studio.id);
  });

  test('supports explicit studio modes and defaults to overview', () {
    final modes = StudioModeRegistry();
    expect(modes.active, StudioMode.overview);
    modes.activate(StudioMode.production);
    expect(modes.active, StudioMode.production);
    expect(modes.available, contains(StudioMode.overview));
  });

  test('workspace state keeps studio and active mode together', () {
    const studio = StudioEntity(id: 'studio-1', name: 'Void Studio');
    final workspace = StudioWorkspace(studio: studio);
    expect(workspace.studio, studio);
    workspace.setMode(StudioMode.review);
    expect(workspace.mode, StudioMode.review);
  });
}
