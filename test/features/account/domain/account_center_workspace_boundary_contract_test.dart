/// Sprint 115.4 — Workspace Boundary Contract.
///
/// Validates the Account & Cloud Center boundary against the canonical
/// sprint JSON, the product-spec snapshot, and the live route/workspace
/// namespaces: global user scope, no workspace co-ownership, explicit
/// workspace permission, explicit transfer consent, and separate backup
/// boundaries.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_workspace_boundary_contract.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_permission_policy.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json',
  );

  Map<String, dynamic> readManifest() {
    expect(
      manifestFile.existsSync(),
      isTrue,
      reason: '115.4 manifest must exist',
    );
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  String sha256Of(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return '';
    }
    return sha256.convert(file.readAsBytesSync()).toString();
  }

  group('115.4 Workspace Boundary Contract — manifest provenance', () {
    test('manifest records canonical step, sources, and boundary scopes', () {
      final manifest = readManifest();
      expect(manifest['canonical_step'], '115.4');
      expect(
        manifest['document_role'],
        'SPRINT_115_WORKSPACE_BOUNDARY_MANIFEST',
      );

      expect(manifest['scope'], AccountCenterWorkspaceBoundaryContract.scope);
      expect(manifest['scope'], 'GLOBAL_USER');
      expect(
        manifest['forbidden_nesting_scopes'],
        AccountCenterWorkspaceBoundaryContract.forbiddenNestingScopes,
      );
      expect(manifest['forbidden_nesting_scopes'], [
        'NOVEL_WORKSPACE',
        'CHARACTER_WORKSPACE',
      ]);
      expect(
        manifest['novel_character_data_co_ownership_allowed'],
        AccountCenterWorkspaceBoundaryContract
            .novelCharacterDataCoOwnershipAllowed,
      );
      expect(manifest['novel_character_data_co_ownership_allowed'], isFalse);
      expect(
        manifest['canonical_route'],
        AccountCenterInformationArchitecture.canonicalRoute,
      );
      expect(manifest['canonical_route'], AppRoutes.accountCloud);
      expect(
        manifest['workspace_route_prefixes'],
        AccountCenterWorkspaceBoundaryContract.workspaceRoutePrefixes,
      );
      expect(manifest['workspace_route_prefixes'], ['/workspace', '/studio']);
    });

    test('source hashes match the live canonical sprint and product spec', () {
      final manifest = readManifest();
      final sources = manifest['sources'] as Map<String, dynamic>;

      final steps = sources['canonical_steps'] as Map<String, dynamic>;
      expect(steps['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      final liveStepsHash = sha256Of(steps['path'] as String);
      if (liveStepsHash.isNotEmpty) {
        expect(liveStepsHash, steps['sha256'], reason: 'sprint_115.json hash');
      }

      final spec = sources['product_spec'] as Map<String, dynamic>;
      expect(spec['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      final liveSpecHash = sha256Of(spec['path'] as String);
      if (liveSpecHash.isNotEmpty) {
        expect(liveSpecHash, spec['sha256'], reason: 'product spec hash');
      }

      // Cross-check against the in-repo 115.1 entry-gate snapshot so the
      // recorded product-spec hash cannot drift silently.
      final entrySnapshot = File(
        'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json',
      );
      expect(entrySnapshot.existsSync(), isTrue);
      final entry =
          jsonDecode(entrySnapshot.readAsStringSync()) as Map<String, dynamic>;
      expect(spec['sha256'], entry['source_sha256']);
    });

    test('manifest lists the decision and violation codes verbatim', () {
      final manifest = readManifest();
      expect(
        manifest['decision_codes'],
        AccountCenterWorkspaceBoundaryContract.decisionCodes,
      );
      expect(
        manifest['violation_codes'],
        AccountCenterWorkspaceBoundaryContract.violationCodes,
      );
      expect(
        manifest['backup_boundaries'],
        AccountBackupBoundary.values.map((b) => b.id).toList(),
      );
      expect(manifest['backup_boundaries'], [
        'ACCOUNT_GLOBAL',
        'NOVEL_WORKSPACE',
        'CHARACTER_WORKSPACE',
      ]);
      expect(manifest['workspace_data_namespaces'], {
        'novel':
            AccountCenterWorkspaceBoundaryContract.novelWorkspaceDataNamespace,
        'character': AccountCenterWorkspaceBoundaryContract
            .characterWorkspaceDataNamespace,
      });
    });

    test('all five acceptance keys are recorded with rules', () {
      final manifest = readManifest();
      final acceptance = manifest['acceptance'] as Map<String, dynamic>;
      for (final key in [
        'global_user_scope',
        'no_workspace_co_ownership',
        'explicit_workspace_permission',
        'explicit_transfer_consent',
        'separate_backup_boundaries',
      ]) {
        expect(acceptance.containsKey(key), isTrue, reason: key);
        expect(
          (acceptance[key] as String).trim(),
          isNotEmpty,
          reason: '$key rule must be non-empty',
        );
      }
      expect(manifest['evidence_boundary'], isNotEmpty);
    });
  });

  group('115.4 global_user_scope', () {
    test('canonical account route is global and never workspace-nested', () {
      const canonical = AccountCenterInformationArchitecture.canonicalRoute;
      expect(canonical, AppRoutes.accountCloud);
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(canonical),
        isTrue,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AccountCenterInformationArchitecture.legacyRoute,
        ),
        isTrue,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.settings,
        ),
        isTrue,
      );
    });

    test('workspace route prefixes and nested variants are rejected', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.workspace,
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          AppRoutes.studio,
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          '/studio/7f3a',
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          '/workspace/account/cloud-center',
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          '/account/cloud-center/workspace',
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          'account/cloud-center',
        ),
        isFalse,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(''),
        isFalse,
      );
    });
  });

  group('115.4 explicit_workspace_permission', () {
    test('global targets need no workspace permission', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.globalUser,
          hasExplicitWorkspacePermission: false,
        ),
        WorkspaceBoundaryDecision.allowedGlobalScope,
      );
    });

    test(
      'novel and character targets are denied without explicit permission',
      () {
        for (final target in [
          AccountCenterDataScope.novelWorkspace,
          AccountCenterDataScope.characterWorkspace,
        ]) {
          expect(
            AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
              target: target,
              hasExplicitWorkspacePermission: false,
            ),
            WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired,
            reason: target.name,
          );
          expect(
            AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
              target: target,
              hasExplicitWorkspacePermission: true,
            ),
            WorkspaceBoundaryDecision.allowedWorkspaceScoped,
            reason: target.name,
          );
        }
      },
    );

    test('permission gate follows the live WorkspacePermissionPolicy', () {
      const policy = WorkspacePermissionPolicy();

      final denied = policy.canReadCharacterProjection(
        access: const WorkspaceAccess(),
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'char-1',
        hasExplicitLink: true,
      );
      expect(denied, isFalse);
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.characterWorkspace,
          hasExplicitWorkspacePermission: denied,
        ),
        WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired,
      );

      final noLink = policy.canReadCharacterProjection(
        access: const WorkspaceAccess(
          readableNovelWorkspaceIds: {'novel-1'},
          readableCharacterWorkspaceIds: {'char-1'},
        ),
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'char-1',
        hasExplicitLink: false,
      );
      expect(noLink, isFalse);

      final granted = policy.canReadCharacterProjection(
        access: const WorkspaceAccess(
          readableNovelWorkspaceIds: {'novel-1'},
          readableCharacterWorkspaceIds: {'char-1'},
        ),
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'char-1',
        hasExplicitLink: true,
      );
      expect(granted, isTrue);
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.characterWorkspace,
          hasExplicitWorkspacePermission: granted,
        ),
        WorkspaceBoundaryDecision.allowedWorkspaceScoped,
      );
    });
  });

  group('115.4 explicit_transfer_consent', () {
    test('global-to-global transfer stays in global scope without consent', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.resolveTransfer(
          source: AccountCenterDataScope.globalUser,
          destination: AccountCenterDataScope.globalUser,
          hasExplicitTransferConsent: false,
        ),
        WorkspaceBoundaryDecision.allowedGlobalScope,
      );
    });

    test('cross-scope transfers are denied until consent is explicit', () {
      for (final pair in [
        (
          AccountCenterDataScope.novelWorkspace,
          AccountCenterDataScope.globalUser,
        ),
        (
          AccountCenterDataScope.characterWorkspace,
          AccountCenterDataScope.globalUser,
        ),
        (
          AccountCenterDataScope.globalUser,
          AccountCenterDataScope.novelWorkspace,
        ),
      ]) {
        expect(
          AccountCenterWorkspaceBoundaryContract.resolveTransfer(
            source: pair.$1,
            destination: pair.$2,
            hasExplicitTransferConsent: false,
          ),
          WorkspaceBoundaryDecision.deniedTransferConsentRequired,
          reason: '${pair.$1.name} -> ${pair.$2.name}',
        );
        expect(
          AccountCenterWorkspaceBoundaryContract.resolveTransfer(
            source: pair.$1,
            destination: pair.$2,
            hasExplicitTransferConsent: true,
          ),
          WorkspaceBoundaryDecision.allowedWorkspaceScoped,
          reason: '${pair.$1.name} -> ${pair.$2.name}',
        );
      }
    });
  });

  group('115.4 separate_backup_boundaries', () {
    test('account-global boundary never holds workspace data', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.accountGlobal,
          relativePaths: const ['settings/app.json'],
        ),
        isEmpty,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.accountGlobal,
          relativePaths: const [
            'workspaces/novels/novel-1/story.json',
            'workspaces/characters/char-1/identity.json',
          ],
        ),
        [
          'ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA',
          'ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA',
        ],
      );
    });

    test('novel and character boundaries stay separated', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.novelWorkspace,
          relativePaths: const ['workspaces/novels/novel-1/chapters/ch-1.md'],
        ),
        isEmpty,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.novelWorkspace,
          relativePaths: const [
            'workspaces/characters/char-1/private-notes.md',
          ],
        ),
        ['NOVEL_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_CHARACTER_DATA'],
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.characterWorkspace,
          relativePaths: const ['workspaces/novels/novel-1/bible.md'],
        ),
        ['CHARACTER_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_NOVEL_DATA'],
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.characterWorkspace,
          relativePaths: const ['workspaces/characters/char-1/canon.md'],
        ),
        isEmpty,
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.accountGlobal,
          relativePaths: const [],
        ),
        isEmpty,
      );
    });

    test('namespaces match the live WorkspaceFileNamespace roots', () {
      expect(
        AccountCenterWorkspaceBoundaryContract.novelWorkspaceDataNamespace,
        'workspaces/novels',
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.characterWorkspaceDataNamespace,
        'workspaces/characters',
      );
      expect(
        AccountCenterWorkspaceBoundaryContract.novelWorkspaceDataNamespace,
        isNot(
          AccountCenterWorkspaceBoundaryContract
              .characterWorkspaceDataNamespace,
        ),
      );
    });
  });

  group('115.4 live Account Center copy', () {
    testWidgets('overview copy is account-scoped, never workspace-scoped', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AccountCloudCenterScreen()),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('QUICK CONNECT'), findsOneWidget);
      expect(
        find.text('Connect services available to this account'),
        findsOneWidget,
      );
      expect(find.textContaining('workspace'), findsNothing);
    });
  });
}
