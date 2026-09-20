import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/character_inspector.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression coverage for vs-hunt-20260913-inspector INS-BUG-01:
/// CharacterInspector passed the raw characterId UUID straight to
/// InspectorBody as the display name, while Wardrobe/Weapon inspectors load
/// their model name. The loadout UX contract forbids surfacing raw UUID
/// tokens in the UI; an unresolvable id must read 'Unknown asset'.
///
/// Contract under test: the header shows the asset's real name once the
/// session data resolves, and NEVER the raw id token.
///
/// Harness note (Windows): every dart:io / real-DB await must run inside
/// `tester.runAsync`; the fake-async test zone never completes them.
class _FixedSessionController extends ProjectSessionController {
  _FixedSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  Future<ProjectSession> openSession(Directory root, String name) async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    return ProjectSessionManager().open(package);
  }

  Future<void> seedAsset(
    ProjectDatabase db,
    String projectId,
    String id,
    String name,
  ) async {
    final now = DateTime.now();
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            type: 'character',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<ProjectSession> pumpInspector(
    WidgetTester tester,
    String characterId,
  ) async {
    late ProjectSession session;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('char-insp-');
      addTearDown(() => root.delete(recursive: true));
      session = await openSession(root, 'Character Inspector Name');
      addTearDown(session.database.close);
      await seedAsset(
        session.database,
        session.manifest.id,
        'char-1',
        'Qowner',
      );
    });
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FixedSessionController(session),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 900,
              child: CharacterInspector(characterId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return session;
  }

  testWidgets('header shows the character name, never the raw UUID', (
    tester,
  ) async {
    await pumpInspector(tester, 'char-1');
    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('char-1'), findsNothing);
  });

  testWidgets('unknown character id renders a human label, not the token', (
    tester,
  ) async {
    await pumpInspector(tester, 'char-missing');
    expect(find.text('Unknown asset'), findsOneWidget);
    expect(find.text('char-missing'), findsNothing);
  });
}
