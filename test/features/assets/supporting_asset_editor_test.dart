import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/presentation/supporting_asset_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);

  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'Armor editor persists protection material and condition across restart',
    (tester) async {
      late Directory root;
      late ProjectPackage package;
      late ProjectSession session;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('armor-editor-');
        package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Armor Editor');
        session = await ProjectSessionManager().open(package);
        final now = DateTime.utc(2026, 9, 15);
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'armor-1',
                projectId: session.manifest.id,
                name: 'Void Plate',
                type: 'armor',
                createdAt: now,
                updatedAt: now,
              ),
            );
      });
      addTearDown(() => root.delete(recursive: true));

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: package.root.parent),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportingAssetWorkspaceScreen(assetId: 'armor-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ARMOR SPECIFICATION'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Protection'),
        'Arc impact shielding',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Material'),
        'Voidsteel laminate',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Condition'),
        'Battle-worn',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Armor'));
      await tester
          .pumpAndSettle(const Duration(milliseconds: 50))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw StateError('save UI did not settle'),
          );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      late SupportingAssetProfile profile;
      await tester.runAsync(() async {
        await session.close().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw StateError('first session did not close'),
        );
        session = await ProjectSessionManager()
            .open(package)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw StateError('package did not reopen'),
            );
        profile = await (session.database.select(
          session.database.supportingAssetProfiles,
        )..where((row) => row.assetId.equals('armor-1'))).getSingle();
      });
      addTearDown(session.close);

      expect(profile.assetType, 'armor');
      expect(profile.protection, 'Arc impact shielding');
      expect(profile.material, 'Voidsteel laminate');
      expect(profile.condition, 'Battle-worn');
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'Accessory editor persists category material and significance across restart',
    (tester) async {
      late Directory root;
      late ProjectPackage package;
      late ProjectSession session;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('accessory-editor-');
        package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Accessory Editor');
        session = await ProjectSessionManager().open(package);
        final now = DateTime.utc(2026, 9, 15);
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'accessory-1',
                projectId: session.manifest.id,
                name: 'Choir Signet',
                type: 'accessory',
                createdAt: now,
                updatedAt: now,
              ),
            );
      });
      addTearDown(() => root.delete(recursive: true));
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: package.root.parent),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportingAssetWorkspaceScreen(assetId: 'accessory-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACCESSORY SPECIFICATION'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Category'),
        'Signet ring',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Material'),
        'Obsidian and silver',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Narrative significance'),
        'Marks the bearer as a Choir emissary',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Accessory'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      late SupportingAssetProfile profile;
      await tester.runAsync(() async {
        await session.close();
        session = await ProjectSessionManager().open(package);
        profile = await (session.database.select(
          session.database.supportingAssetProfiles,
        )..where((row) => row.assetId.equals('accessory-1'))).getSingle();
      });
      addTearDown(session.close);

      expect(profile.assetType, 'accessory');
      expect(profile.category, 'Signet ring');
      expect(profile.material, 'Obsidian and silver');
      expect(profile.significance, 'Marks the bearer as a Choir emissary');
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  for (final scenario
      in <
        ({
          String type,
          String heading,
          String saveLabel,
          List<({String label, String value})> fields,
        })
      >[
        (
          type: 'prop',
          heading: 'ITEM SPECIFICATION',
          saveLabel: 'Save Item',
          fields: [
            (label: 'Purpose', value: 'Unlocks the polar archive'),
            (label: 'Usage rules', value: 'Consumes one memory per opening'),
            (label: 'State', value: 'Dormant'),
          ],
        ),
        (
          type: 'hair_variant',
          heading: 'HAIR VARIATION SPECIFICATION',
          saveLabel: 'Save Hair Variation',
          fields: [
            (label: 'Style', value: 'Braided crown'),
            (label: 'Color', value: 'Obsidian black'),
            (label: 'Length / shape', value: 'Shoulder length'),
          ],
        ),
      ]) {
    testWidgets(
      '${scenario.heading} editor persists its distinct fields across restart',
      (tester) async {
        late Directory root;
        late ProjectPackage package;
        late ProjectSession session;
        await tester.runAsync(() async {
          root = await Directory.systemTemp.createTemp(
            '${scenario.type}-editor-',
          );
          package = await ProjectPackageService(
            rootDirectory: root,
          ).create(name: scenario.heading);
          session = await ProjectSessionManager().open(package);
          final now = DateTime.utc(2026, 9, 15);
          await session.database
              .into(session.database.assets)
              .insert(
                AssetsCompanion.insert(
                  id: '${scenario.type}-1',
                  projectId: session.manifest.id,
                  name: scenario.heading,
                  type: scenario.type,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        });
        addTearDown(() => root.delete(recursive: true));
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectSessionProvider.overrideWith(() => _BoundSession(session)),
              projectPathsProvider.overrideWithValue(
                ProjectPaths(rootDirectory: package.root.parent),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SupportingAssetWorkspaceScreen(
                  assetId: '${scenario.type}-1',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(scenario.heading), findsWidgets);
        expect(
          find.widgetWithText(FilledButton, scenario.saveLabel),
          findsOneWidget,
        );
        for (final field in scenario.fields) {
          await tester.enterText(
            find.widgetWithText(TextField, field.label),
            field.value,
          );
        }
        await tester.tap(find.widgetWithText(FilledButton, scenario.saveLabel));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        late SupportingAssetProfile profile;
        await tester.runAsync(() async {
          await session.close();
          session = await ProjectSessionManager().open(package);
          profile =
              await (session.database.select(
                    session.database.supportingAssetProfiles,
                  )..where((row) => row.assetId.equals('${scenario.type}-1')))
                  .getSingle();
        });
        addTearDown(session.close);

        if (scenario.type == 'prop') {
          expect(profile.purpose, scenario.fields[0].value);
          expect(profile.usageRules, scenario.fields[1].value);
          expect(profile.itemState, scenario.fields[2].value);
        } else {
          expect(profile.hairStyle, scenario.fields[0].value);
          expect(profile.hairColor, scenario.fields[1].value);
          expect(profile.hairLength, scenario.fields[2].value);
        }
        expect(profile.assetType, scenario.type);
        expect(tester.takeException(), isNull);
      },
      skip: !Platform.isWindows,
    );
  }
}
