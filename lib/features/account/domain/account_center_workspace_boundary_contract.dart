/// Sprint 115.4 — Workspace Boundary Contract.
///
/// Satu sumber kebenaran batas Account & Cloud Center terhadap Novel dan
/// Character Workspace: scope global (`GLOBAL_USER`), tanpa co-ownership
/// data workspace, akses workspace wajib permission eksplisit, transfer
/// wajib consent eksplisit, dan backup boundary yang terpisah.
///
/// grounding: product spec `account_cloud_center_spec.json`
/// (placement.scope, security_contract.cross_workspace_rule,
/// workspace_architecture ADR-WS-001) serta route/namespace live di repo
/// (`AppRoutes`, `WorkspaceFileNamespace`, `WorkspacePermissionPolicy`).
/// Murni Dart tanpa dependensi Flutter supaya domain test bisa memvalidasi
/// manifest `docs/planning/v1.2/sprint_115_workspace_boundary_contract.json`.
library;

/// Scope kepemilikan data yang dibaca atau ditulis sebuah surface/aksi.
enum AccountCenterDataScope {
  /// Scope akun global (profil, connections, storage cloud, billing).
  globalUser,

  /// Data milik Novel Workspace.
  novelWorkspace,

  /// Data milik Character Workspace.
  characterWorkspace,
}

/// Batas backup/wrapper data yang wajib terpisah (acceptance
/// `separate_backup_boundaries`).
enum AccountBackupBoundary {
  /// Boundary milik akun global: metadata akun saja, tanpa data workspace.
  accountGlobal('ACCOUNT_GLOBAL'),

  /// Boundary milik Novel Workspace.
  novelWorkspace('NOVEL_WORKSPACE'),

  /// Boundary milik Character Workspace.
  characterWorkspace('CHARACTER_WORKSPACE');

  const AccountBackupBoundary(this.id);

  /// ID manifest (uppercase) untuk dokumentasi dan test paritas.
  final String id;
}

/// Hasil evaluasi batas workspace.
enum WorkspaceBoundaryDecision {
  /// Aksi murni scope global; tidak menyentuh data workspace.
  allowedGlobalScope('ALLOWED_GLOBAL_SCOPE'),

  /// Aksi workspace yang didukung permission/consent eksplisit.
  allowedWorkspaceScoped('ALLOWED_WORKSPACE_SCOPED'),

  /// Ditolak: akses data workspace tanpa permission eksplisit.
  deniedWorkspacePermissionRequired('DENIED_WORKSPACE_PERMISSION_REQUIRED'),

  /// Ditolak: transfer lintas scope tanpa consent eksplisit.
  deniedTransferConsentRequired('DENIED_TRANSFER_CONSENT_REQUIRED');

  const WorkspaceBoundaryDecision(this.id);

  /// ID manifest (uppercase) untuk dokumentasi dan test paritas.
  final String id;
}

abstract final class AccountCenterWorkspaceBoundaryContract {
  /// Scope Account & Cloud Center sesuai product spec `placement.scope`.
  static const String scope = 'GLOBAL_USER';

  /// Keputusan arsitektur pemisahan workspace (sumber sprint).
  static const String decisionId = 'ADR-WS-001';

  /// Workspace yang tidak boleh membungkus Account Center
  /// (`placement.must_not_be_nested_under`).
  static const List<String> forbiddenNestingScopes = <String>[
    'NOVEL_WORKSPACE',
    'CHARACTER_WORKSPACE',
  ];

  /// `workspace_architecture.novel_character_data_co_ownership_allowed`.
  /// Account Center tidak pernah ikut memiliki data Novel/Character.
  static const bool novelCharacterDataCoOwnershipAllowed = false;

  /// Prefiks route live yang mewakili workspace novel/character di repo ini
  /// (`AppRoutes.workspace`, `AppRoutes.studio` + `AppRoutes.studioProject`).
  static const List<String> workspaceRoutePrefixes = <String>[
    '/workspace',
    '/studio',
  ];

  /// Namespace data workspace live (`WorkspaceFileNamespace`).
  static const String novelWorkspaceDataNamespace = 'workspaces/novels';
  static const String characterWorkspaceDataNamespace = 'workspaces/characters';

  /// Kode keputusan yang didokumentasikan manifest.
  static const List<String> decisionCodes = <String>[
    'ALLOWED_GLOBAL_SCOPE',
    'ALLOWED_WORKSPACE_SCOPED',
    'DENIED_WORKSPACE_PERMISSION_REQUIRED',
    'DENIED_TRANSFER_CONSENT_REQUIRED',
  ];

  /// Kode pelanggaran boundary yang didokumentasikan manifest.
  static const List<String> violationCodes = <String>[
    'ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA',
    'NOVEL_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_CHARACTER_DATA',
    'CHARACTER_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_NOVEL_DATA',
  ];

  /// `true` bila [route] adalah surface global: path absolut yang tidak
  /// berada di bawah prefiks workspace mana pun dan tidak menampilkan
  /// segmen workspace (`workspace`, `studio`) di dalamnya — route account
  /// tidak boleh membungkus surface workspace (co-ownership) dan route
  /// account tidak boleh tersembunyi di bawah workspace
  /// (`placement.must_not_be_nested_under`). Route relatif, kosong, atau
  /// mengandung segmen workspace = bukan surface global (fail closed).
  static bool isGlobalSurfaceRoute(String route) {
    if (!route.startsWith('/')) {
      return false;
    }
    for (final prefix in workspaceRoutePrefixes) {
      if (route == prefix || route.startsWith('$prefix/')) {
        return false;
      }
      if (route.split('/').contains(prefix.substring(1))) {
        return false;
      }
    }
    return true;
  }

  /// Gerbang akses data workspace: target global selalu lolos; target
  /// Novel/Character butuh permission eksplisit (selaras dengan
  /// `WorkspacePermissionPolicy`, yang menuntut link/grant eksplisit).
  static WorkspaceBoundaryDecision resolveWorkspaceAccess({
    required AccountCenterDataScope target,
    required bool hasExplicitWorkspacePermission,
  }) {
    if (target == AccountCenterDataScope.globalUser) {
      return WorkspaceBoundaryDecision.allowedGlobalScope;
    }
    return hasExplicitWorkspacePermission
        ? WorkspaceBoundaryDecision.allowedWorkspaceScoped
        : WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired;
  }

  /// Gerbang transfer lintas scope (`security_contract.cross_workspace_rule`):
  /// global -> global bebas consent; segala pasangan yang menyentuh workspace
  /// menuntut transfer consent eksplisit.
  static WorkspaceBoundaryDecision resolveTransfer({
    required AccountCenterDataScope source,
    required AccountCenterDataScope destination,
    required bool hasExplicitTransferConsent,
  }) {
    if (source == AccountCenterDataScope.globalUser &&
        destination == AccountCenterDataScope.globalUser) {
      return WorkspaceBoundaryDecision.allowedGlobalScope;
    }
    return hasExplicitTransferConsent
        ? WorkspaceBoundaryDecision.allowedWorkspaceScoped
        : WorkspaceBoundaryDecision.deniedTransferConsentRequired;
  }

  /// Validasi pemisahan backup boundary berdasarkan path relatif terhadap
  /// package root. Mengembalikan daftar kode pelanggaran (kosong = bersih).
  static List<String> backupBoundaryViolations({
    required AccountBackupBoundary boundary,
    required List<String> relativePaths,
  }) {
    final violations = <String>[];
    for (final rawPath in relativePaths) {
      final owner = _workspaceOwnerOf(rawPath);
      if (owner == null) {
        continue;
      }
      switch (boundary) {
        case AccountBackupBoundary.accountGlobal:
          violations.add('ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA');
        case AccountBackupBoundary.novelWorkspace:
          if (owner == AccountBackupBoundary.characterWorkspace) {
            violations.add(
              'NOVEL_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_CHARACTER_DATA',
            );
          }
        case AccountBackupBoundary.characterWorkspace:
          if (owner == AccountBackupBoundary.novelWorkspace) {
            violations.add(
              'CHARACTER_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_NOVEL_DATA',
            );
          }
      }
    }
    return violations;
  }

  /// Boundary pemilik path workspace, atau `null` bila bukan data workspace.
  static AccountBackupBoundary? _workspaceOwnerOf(String relativePath) {
    final normalized = relativePath.replaceAll(r'\', '/');
    if (normalized == novelWorkspaceDataNamespace ||
        normalized.startsWith('$novelWorkspaceDataNamespace/')) {
      return AccountBackupBoundary.novelWorkspace;
    }
    if (normalized == characterWorkspaceDataNamespace ||
        normalized.startsWith('$characterWorkspaceDataNamespace/')) {
      return AccountBackupBoundary.characterWorkspace;
    }
    return null;
  }
}
