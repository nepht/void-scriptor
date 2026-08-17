import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/application/creator_studio_controller.dart';
import 'package:void_scriptor/features/creator/domain/creator_metrics.dart';
import 'package:void_scriptor/features/creator/domain/creator_workspace_section.dart';

void main() {
  group('CreatorStudioController', () {
    test('initial state memakai default metrics & section', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(creatorStudioProvider);
      expect(state.metrics.activeProjects, 0);
      expect(state.activeSection, CreatorWorkspaceSection.myProjects);
      expect(state.profile, isNull);
    });

    test('setSection mengubah active section', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(creatorStudioProvider.notifier)
          .setSection(CreatorWorkspaceSection.portfolio);
      expect(
        container.read(creatorStudioProvider).activeSection,
        CreatorWorkspaceSection.portfolio,
      );
    });

    test('updateMetrics memperbarui metrics', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(creatorStudioProvider.notifier)
          .updateMetrics(
            const CreatorMetrics(
              activeProjects: 3,
              publishedWorks: 5,
              portfolioViews: 120,
              aiUsage: 40,
              storageBytes: 2048,
            ),
          );
      expect(container.read(creatorStudioProvider).metrics.activeProjects, 3);
      expect(
        container.read(creatorStudioProvider).metrics.storageLabel,
        '2.0 KB',
      );
    });
  });
}
