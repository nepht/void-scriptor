import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/bible/application/faction_image_importer.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';
import 'package:void_scriptor/features/bible/domain/faction.dart' as domain;
import 'package:void_scriptor/features/bible/presentation/widgets/faction_image_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// vs-hunt-20260914-bible-ui BUI-BUG-04 (Referee: REAL BUG, Medium).
/// `WorldImageCard` reloads only when `entityId` changes, so an entity id
/// that stays equal across a direct project A -> project B session switch
/// keeps rendering project A's image. Factions are addressed by their own
/// UUID; two projects can legitimately carry the SAME id string, so the
/// card must treat project identity as part of its reload contract.
/// Reproduced with two disposable temp projects — no user data involved.
class _SwitchableSessionController extends ProjectSessionController {
  _SwitchableSessionController(this.session);

  ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;

  void switchTo(ProjectSession next) {
    session = next;
    state = AsyncValue.data(next);
  }
}

/// Mirrors the production composition: the workspace body only mounts the
/// card once the session provider resolves, and FactionImageCard itself
/// gates on session presence before it builds WorldImageCard. That is what
/// makes the A -> B switch "non-null -> non-null" with a constant entityId.
class _SessionGatedFactionCard extends ConsumerWidget {
  const _SessionGatedFactionCard({required this.factionId});

  final String factionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    return FactionImageCard(factionId: factionId);
  }
}

void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  /// Creates one temp project with a faction bound to [sharedFactionId]
  /// (deliberately the SAME id in both projects) whose image is a file
  /// inside that project's own package directory.
  Future<({ProjectSession session, Directory root})> seedProject(
    WidgetTester tester,
    String name,
    String sharedFactionId,
  ) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('world-img-$name-');
      addTearDown(() async {
        try {
          await root.delete(recursive: true);
        } catch (_) {}
      });
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'World Img $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      await FactionRepository(session.database).save(
        domain.FactionModel(
          assetId: sharedFactionId,
          projectId: session.manifest.id,
          name: 'Klan $name',
        ),
      );
      final source = File(p.join(root.path, 'sigil-$name.png'))
        ..writeAsBytesSync(pngBytes);
      await FactionImageImporter(
        database: session.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(assetId: sharedFactionId, sourcePath: source.path);
    });
    return (session: session, root: root);
  }

  Future<String> renderedImagePath(WidgetTester tester) async {
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(Image).evaluate().isNotEmpty) break;
    }
    final image = tester.widget<Image>(find.byType(Image).first);
    return (image.image as FileImage).file.path;
  }

  testWidgets(
    'FACTION IMAGE card follows the active project when a direct A -> B '
    'session switch keeps the same entityId (BUI-BUG-04)',
    (tester) async {
      const sharedFactionId = '7f3a1c00-same-in-both-projects-0000000000a1';
      final a = await seedProject(tester, 'A', sharedFactionId);
      final b = await seedProject(tester, 'B', sharedFactionId);

      final controller = _SwitchableSessionController(a.session);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [projectSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(
            home: Scaffold(
              body: _SessionGatedFactionCard(factionId: sharedFactionId),
            ),
          ),
        ),
      );

      // Precondition: project A's package image is rendered.
      final pathA = await renderedImagePath(tester);
      expect(pathA, contains('faction_images'));
      expect(
        p.normalize(pathA),
        startsWith(p.normalize(a.root.path)),
        reason: 'before the switch, the card shows project A image',
      );

      // Direct A -> B switch through the production session provider; the
      // factionId stays exactly equal, which is the bug trigger.
      controller.switchTo(b.session);
      await tester.pumpAndSettle();

      final pathAfter = await renderedImagePath(tester);
      expect(
        p.normalize(pathAfter),
        startsWith(p.normalize(b.root.path)),
        reason:
            'after switching to project B the card must show B\'s image, '
            'not retain A\'s (project-scoped callbacks changed, entityId did not)',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
