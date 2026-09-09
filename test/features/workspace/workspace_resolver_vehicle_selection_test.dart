import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/assets/presentation/supporting_asset_workspace_screen.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// BUG-09 (hunt run165, Referee REAL BUG Low): a vehicle asset is producible
/// through the Asset Browser create dialog and reachable through browser
/// selection plus the global search sheet, but the resolver switch had no
/// vehicle case — the selection dead-ended on a callback-less ProjectOverview
/// while the panel header kept advertising "Asset Workspace".
void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets('vehicle selection opens the supporting asset workspace', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'resolver-vehicle-');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    final session = await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${temp.path}/pkg'),
      ).create(name: 'Vehicle Resolver Novel');
      return ProjectSessionManager().open(package);
    });
    final liveSession = session!;
    addTearDown(liveSession.close);

    // Real Drift write: the same production path the Asset Browser create
    // dialog uses for a stand-alone vehicle asset.
    const vehicleId = 'vehicle-resolver-1';
    await tester.runAsync(
      () => liveSession.database.assetDao.createStandaloneAsset(
        id: vehicleId,
        projectId: liveSession.manifest.id,
        name: 'Rover',
        type: 'vehicle',
        description: 'Six-wheeled surface rover',
        now: DateTime.now().toUtc(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(liveSession)),
          selectionProvider.overrideWith(
            () => _FixedSelection(
              SelectionModel(
                assetId: vehicleId,
                assetType: AssetType.vehicle,
                projectId: liveSession.manifest.id,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The dead-end: bare overview without callbacks must not render.
    expect(find.byType(ProjectOverview), findsNothing);
    // The typed vehicle workspace with the real asset row loaded.
    expect(find.byType(SupportingAssetWorkspaceScreen), findsOneWidget);
    expect(find.text('Rover'), findsOneWidget);
  });
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

class _FixedSelection extends SelectionController {
  _FixedSelection(this._selection);

  final SelectionModel _selection;

  @override
  SelectionModel? build() => _selection;
}
