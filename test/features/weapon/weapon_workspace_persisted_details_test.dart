import 'dart:io';

// `show Value` only — a full drift import collides with matcher's `isNull`.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/weapon/application/create_weapon_service.dart';
import 'package:void_scriptor/features/weapon/data/weapon_repository_impl.dart';
import 'package:void_scriptor/features/weapon/domain/weapon_model.dart';
import 'package:void_scriptor/features/weapon/domain/weapon_workspace_data.dart';
import 'package:void_scriptor/features/weapon/presentation/weapon_workspace_controller.dart';
import 'package:void_scriptor/features/weapon/presentation/weapon_workspace_screen.dart';

/// vs-hunt-20260914-wardrobe-weapon WBUG-6 (Referee: REAL BUG, Medium).
/// The production weapon workspace rendered const sample chips and fixed
/// dimension/energy rows ('260 mm', 'Violet', 'Grip Recognition', ...)
/// regardless of persisted child rows. Fix mirrors the ENV-BUG-002 precedent
/// (run271): cards are data-driven from `WeaponWorkspaceData` resolved
/// through the repository; an empty database shows honest empty states.
void main() {
  const weaponId = 'weapon-1';

  const model = WeaponModel(
    assetId: weaponId,
    projectId: 'project-1',
    name: 'Belah Bayang',
    weaponType: 'Pedang Dua Tangan',
    primaryMaterial: 'Baja Hitam',
    energyType: 'Void Ringan',
    coreType: 'Inti Kaca',
    lengthMm: 1180.5,
    weightKg: 3.2,
  );

  const populated = WeaponWorkspaceData(
    components: [
      WeaponComponentInfo(name: 'Bilah Lenyap', componentType: 'blade'),
      WeaponComponentInfo(name: 'Pelindung Nadi', componentType: 'guard'),
    ],
    measurements: [
      WeaponMeasurementInfo(label: 'Panjang Bilah', value: 940.0, unit: 'mm'),
      WeaponMeasurementInfo(label: 'Ujung Gagang', value: 132.5, unit: 'mm'),
    ],
    colors: [
      WeaponColorInfo(name: 'Biru Malam', hexValue: '#112244', usage: 'Bilah'),
    ],
    energy: WeaponEnergyInfo(
      activation: 'Sentuhan Pemilik',
      emissionColor: 'Biru Redup',
    ),
    variants: [
      WeaponVariantInfo(name: 'Normal', isDefault: true),
      WeaponVariantInfo(name: 'Ritual', isDefault: false),
    ],
    references: [WeaponReferenceInfo(referenceType: 'samping')],
  );

  Future<void> pumpWorkspace(
    WidgetTester tester, {
    required WeaponWorkspaceData data,
    WeaponModel? weapon = model,
    double width = 1280,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weaponWorkspaceProvider(weaponId).overrideWith((ref) async => weapon),
          weaponWorkspaceDetailsProvider(
            weaponId,
          ).overrideWith((ref) async => data),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WeaponWorkspaceScreen(weaponId: weaponId)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('components/variants/references render persisted rows', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Bilah Lenyap'), findsOneWidget);
    expect(find.text('Pelindung Nadi'), findsOneWidget);
    expect(find.text('Ritual'), findsOneWidget);
    expect(find.text('samping'), findsOneWidget);
    // The old fake sample chips must be gone.
    expect(find.text('Edge'), findsNothing);
    expect(find.text('Guard'), findsNothing);
    expect(find.text('Core'), findsNothing);
    expect(find.text('Energy Channel'), findsNothing);
    expect(find.text('Overcharged'), findsNothing);
    expect(find.text('Prototype'), findsNothing);
    expect(
      find.textContaining('Front, Side, Back'),
      findsNothing,
      reason: 'references line was a hardcoded stub',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dimensions and energy render persisted sub-rows, not fakes', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Panjang Bilah'), findsOneWidget);
    expect(find.text('940 mm'), findsOneWidget);
    expect(find.text('Ujung Gagang'), findsOneWidget);
    expect(find.text('132.5 mm'), findsOneWidget);
    expect(find.text('Sentuhan Pemilik'), findsOneWidget);
    expect(find.text('Biru Redup'), findsOneWidget);
    // Overall values still come from the scalar model.
    expect(find.text('1180.5 mm'), findsWidgets);
    expect(find.text('3.2 kg'), findsWidgets);
    expect(find.text('260 mm'), findsNothing);
    expect(find.text('145 mm'), findsNothing);
    expect(find.text('Violet'), findsNothing);
    expect(find.text('Grip Recognition'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('specification card shows persisted scalars', (tester) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Pedang Dua Tangan'), findsWidgets);
    expect(find.text('Baja Hitam'), findsOneWidget);
    expect(find.text('Void Ringan'), findsWidgets);
    expect(find.text('Inti Kaca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty database shows honest empty states, no fake rows', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: const WeaponWorkspaceData());
    expect(find.text('Belum ada komponen tersimpan.'), findsOneWidget);
    expect(find.text('Belum ada varian tersimpan.'), findsOneWidget);
    expect(find.text('Belum ada referensi tersimpan.'), findsOneWidget);
    expect(find.text('Blade'), findsNothing);
    expect(find.text('Handle'), findsNothing);
    expect(find.text('Normal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading or missing session renders dashes, not fake defaults', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      data: const WeaponWorkspaceData(),
      weapon: null,
    );
    expect(find.text('420 mm'), findsNothing);
    expect(find.text('0.82 kg'), findsNothing);
    expect(find.text('Void Alloy'), findsNothing);
    expect(find.text('Void Energy'), findsNothing);
    expect(find.text('Crystalline Void Core'), findsNothing);
    expect(find.text('—'), findsAtLeastNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout stays overflow-free with populated data', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated, width: 390);
    expect(find.text('Bilah Lenyap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'repository maps persisted child rows through real Drift tables',
    () async {
      final root = await Directory.systemTemp.createTemp('wbug6-repo-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final db = await ProjectDatabaseService().open(databasePath);
      addTearDown(db.close);

      final id = await CreateWeaponService(database: db, paths: paths).create(
        projectId: 'project-1',
        name: 'Uji Belati',
        weaponType: 'dagger',
      );

      await db
          .into(db.weaponComponents)
          .insert(
            WeaponComponentsCompanion.insert(
              id: 'comp-1',
              weaponId: id,
              name: 'Gagang Tulang',
              componentType: 'handle',
            ),
          );
      await db
          .into(db.weaponMeasurements)
          .insert(
            WeaponMeasurementsCompanion.insert(
              id: 'meas-1',
              weaponId: id,
              label: 'Leher Bilah',
              value: 41.5,
              unit: 'mm',
            ),
          );
      await db
          .into(db.weaponColors)
          .insert(
            WeaponColorsCompanion.insert(
              id: 'color-1',
              weaponId: id,
              name: 'Biru Senja',
              hexValue: '#223366',
              usage: const Value('Bilah'),
            ),
          );
      final energyProfile = await (db.select(
        db.weaponEnergyProfiles,
      )..where((row) => row.weaponId.equals(id))).getSingleOrNull();
      if (energyProfile == null) {
        // CreateWeaponService seeds only the preservation profile; the energy
        // row is a user-editable record, so the fixture inserts it here.
        await db
            .into(db.weaponEnergyProfiles)
            .insert(
              WeaponEnergyProfilesCompanion.insert(
                weaponId: id,
                activation: const Value('Kunci Suara'),
                emissionColor: const Value('Emas Padam'),
              ),
            );
      } else {
        await db
            .update(db.weaponEnergyProfiles)
            .replace(
              energyProfile.copyWith(
                activation: 'Kunci Suara',
                emissionColor: 'Emas Padam',
              ),
            );
      }

      final data = await WeaponRepositoryImpl(
        database: db,
        projectId: 'project-1',
      ).getWorkspaceData(id);

      expect(data.components.map((c) => c.name), ['Gagang Tulang']);
      expect(data.measurements.map((m) => m.label), ['Leher Bilah']);
      expect(data.measurements.single.value, 41.5);
      expect(data.colors.single.name, 'Biru Senja');
      expect(data.colors.single.hexValue, '#223366');
      expect(data.colors.single.usage, 'Bilah');
      expect(data.energy?.activation, 'Kunci Suara');
      expect(data.energy?.emissionColor, 'Emas Padam');
      // CreateWeaponService seeds the default 'Normal' variant in the DB.
      expect(data.variants.map((v) => v.name), ['Normal']);
      expect(data.references, isEmpty);
      await db.close();
    },
  );
}
