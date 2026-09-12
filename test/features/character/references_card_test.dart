import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/application/character_reference_binder.dart';
import 'package:void_scriptor/features/character/presentation/widgets/references_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// run243: Primary References harus menampilkan gambar paket yang nyata
/// ketika slot terikat (dulu enam kotak label mati + snackbar palsu).
class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

class _NullSession extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  testWidgets(
    'bound Face slot renders the package image; unbound slots stay honest',
    (tester) async {
      late ProjectSession session;
      late Directory root;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('refs-card-');
        addTearDown(() async {
          try {
            await root.delete(recursive: true);
          } catch (_) {}
        });
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Refs Card');
        session = await ProjectSessionManager().open(package);
        addTearDown(session.database.close);
        final now = DateTime(2026);
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'char-ref',
                projectId: session.manifest.id,
                name: 'Qowner',
                type: 'character',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.characters)
            .insert(
              CharactersCompanion.insert(
                assetId: 'char-ref',
                projectId: session.manifest.id,
                displayName: 'Qowner',
              ),
            );
        final source = File(p.join(root.path, 'face.png'))
          ..writeAsBytesSync(pngBytes);
        await CharacterReferenceBinder(
          database: session.database,
          assetsDirectory: session.package.assetsDirectory,
        ).bind(
          characterId: 'char-ref',
          slotLabel: 'Face',
          sourcePath: source.path,
        );
      });

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: session.package.root.parent),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ReferencesCard(characterId: 'char-ref')),
          ),
        ),
      );
      // Slot dibaca dari drift (I/O nyata): pompa berjangka + evaluasi
      // finder via runAsync, pola persis test worldbuilding body.
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final ready = await tester.runAsync(
          () async => find.text('Face').evaluate().isNotEmpty,
        );
        if (ready == true) break;
      }
      await tester.pumpAndSettle();

      expect(find.text('Primary References'), findsOneWidget);
      // Slot terikat = gambar nyata dari namespace paket (DecorationImage).
      final bound = find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final deco = w.decoration;
        if (deco is! BoxDecoration) return false;
        final img = deco.image;
        return img is DecorationImage &&
            img.image is FileImage &&
            (img.image as FileImage).file.path.contains('character_references');
      });
      expect(bound, findsOneWidget);
      // Slot lain jujur: label + status kosong, bukan kotak tanpa makna.
      expect(find.textContaining('No image'), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'without a session the card keeps its labels and shows no dead add button',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _NullSession()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ReferencesCard(characterId: 'x')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primary References'), findsOneWidget);
      expect(find.textContaining('No image'), findsNWidgets(6));
      // Tidak ada affordance mati: tombol tambah hilang tanpa sesi.
      expect(find.byIcon(Icons.add), findsNothing);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
