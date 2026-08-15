import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_controller.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_preset_repository.dart';
import 'package:void_scriptor/features/workspace_layout/application/project_layout_restorer.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/detachable_window_button.dart';

class _FakeRepo implements LayoutPresetRepository {
  PanelLayout? restoredResult;
  PanelLayout? stored;

  @override
  Future<List<LayoutPreset>> list(String projectId) async => [];

  @override
  Future<void> save(String projectId, LayoutPreset preset) async {}

  @override
  Future<void> delete(String projectId, String name) async {}

  @override
  Future<PanelLayout?> restore(String projectId) async => restoredResult;

  @override
  Future<void> persist(String projectId, PanelLayout layout) async {
    stored = layout;
  }
}

void main() {
  testWidgets('restoreProjectLayout applies a persisted layout', (
    tester,
  ) async {
    final repo = _FakeRepo();
    const saved = PanelLayout(
      leftWidth: 280,
      rightWidth: 320,
      leftCollapsed: true,
      rightCollapsed: false,
      splitRatio: 0.6,
    );
    repo.restoredResult = saved;

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [layoutPresetRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await restoreProjectLayout(capturedRef!, 'p1');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    expect(container.read(layoutProvider).leftWidth, 280);
    expect(container.read(layoutProvider).leftCollapsed, isTrue);
  });

  testWidgets('detachable window button shows honest not-yet message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DetachableWindowButton(label: 'Timeline')),
      ),
    );

    await tester.tap(find.byKey(const Key('detach-window')));
    await tester.pump();

    expect(find.textContaining('later sprint'), findsOneWidget);
  });
}
