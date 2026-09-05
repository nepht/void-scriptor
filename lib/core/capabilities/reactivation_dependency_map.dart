/// Sprint 145.39 - Non-Core Preservation and Disablement.
///
/// Reactivation dependency map: setiap capability yang dinonaktifkan/deferred
/// (sumber kanonik: core_mvp_scope_reset_spec.json -> deferred_until_evidence)
/// wajib punya entri eksplisit yang mendokumentasikan cara mengaktifkannya
/// kembali tanpa menebak: layer, feature flag pemilik state (atau null bila
/// belum ada flag khusus), modul lib/features yang benar-benar ada di tree,
/// entry evidence sesuai kontrak 145.17, dan default state.
///
/// File ini HANYA metadata kontrak reaktivasi: tanpa runtime side effect,
/// tanpa import lib/features (arah dependensi Core tetap turun), tanpa
/// mengubah status apapun. Aktifasi nyata tetap butuh approval rilis
/// terpisah (aturan 145.17 poin 7).
///
/// Test arsitektur:
/// test/core/capabilities/reactivation_dependency_map_test.dart
library;

/// State default sebuah capability deferred dalam product.
/// OFF = flag primitive ada dan default OFF.
/// DEFERRED = belum ada runtime/flag khusus; backlog sampai entry evidence.
enum ReactivationDefaultState { off, deferred }

/// Satu entri reaktivasi untuk satu capability deferred.
class ReactivationEntry {
  const ReactivationEntry({
    required this.capabilityId,
    required this.label,
    required this.layer,
    required this.entryEvidence,
    this.owningFlag,
    this.featureModules = const <String>[],
    this.defaultState = ReactivationDefaultState.deferred,
  });

  /// Id stabil yang sama dengan spec kanonik (deferred_until_evidence).
  final String capabilityId;

  /// Label manusiawi untuk report/diagnostik.
  final String label;

  /// Layer roadmap: CLOUD, NETWORK, NETWORK/OPS, PLATFORM FOLLOW-UP,
  /// CLOUD FOLLOW-UP, ENGINE FOLLOW-UP.
  final String layer;

  /// Flag FeatureFlagRegistry (lib/core/feature_flags) yang memegang state runtime, bila ada.
  /// Null = capability belum punya flag khusus; default DEFERRED.
  final String? owningFlag;

  /// Modul lib/features yang benar-benar ada di tree (divalidasi test agar
  /// peta tidak menyebut modul imajiner).
  final List<String> featureModules;

  /// Bukti masuk minimum sebelum capability boleh diaktifkan (kontrak 145.17).
  final String entryEvidence;

  final ReactivationDefaultState defaultState;
}

/// Peta reaktivasi 21 capability deferred kanonik (10 spesifikasi awal + 11
/// demo engine yang dibekukan Choi 2026-09-05 sebagai prasyarat 145.43).
abstract final class ReactivationDependencyMap {
  /// Semua entri reaktivasi capability deferred. Urutan mengikuti spec
  /// (deferred_until_evidence).
  static const List<ReactivationEntry> entries = <ReactivationEntry>[
    ReactivationEntry(
      capabilityId: 'COMMUNITY_CHAT',
      label: 'Community chat & moderation',
      layer: 'NETWORK',
      owningFlag: 'vs12_spoiler_sharing',
      featureModules: <String>['spoiler'],
      entryEvidence:
          'Moderation policy/tooling, abuse escalation, privacy tests, '
          'operational owner (145.17 registry: Community)',
    ),
    ReactivationEntry(
      capabilityId: 'READER_PLATFORM',
      label: 'Reader platform (hosted content)',
      layer: 'NETWORK',
      featureModules: <String>['multiverse'],
      entryEvidence:
          'Published artifact contract, access control, abuse handling, '
          'uptime/rollback evidence (145.17 registry: Reader platform)',
    ),
    ReactivationEntry(
      capabilityId: 'PUBLIC_PUBLISHING',
      label: 'Public publishing pipeline',
      layer: 'NETWORK',
      featureModules: <String>['export', 'cinematic_production'],
      entryEvidence:
          'Versioned snapshot, preview, rollback, metadata, rights, and '
          'end-to-end service tests (145.17 registry: Publishing pipeline)',
      defaultState: ReactivationDefaultState.off,
    ),
    ReactivationEntry(
      capabilityId: 'AUTHOR_PAYMENT_AND_PAYOUT',
      label: 'Author payment & payout',
      layer: 'NETWORK',
      featureModules: <String>['creator'],
      entryEvidence:
          'Sandbox payment, webhook idempotency, refund/chargeback, ledger, '
          'payout and compliance evidence (145.17 registry: Payment/payout)',
    ),
    ReactivationEntry(
      capabilityId: 'CONNECTOR_MARKETPLACE',
      label: 'Connector marketplace',
      layer: 'NETWORK',
      featureModules: <String>['marketplace'],
      entryEvidence:
          'Signed package, permission review, provenance, uninstall/rollback, '
          'privacy-safe analytics (145.17 registry: Marketplace)',
    ),
    ReactivationEntry(
      capabilityId: 'DEVELOPER_PLATFORM',
      label: 'Developer platform (SDK & support surface)',
      layer: 'NETWORK',
      featureModules: <String>['workflow'],
      entryEvidence:
          'Stable public contract, compatibility policy, security review, '
          'sample integration (145.17 registry: Developer platform)',
    ),
    ReactivationEntry(
      capabilityId: 'MULTI_REGION',
      label: 'Multi-region deployment & data residency',
      layer: 'NETWORK/OPS',
      featureModules: <String>[],
      entryEvidence:
          'Region matrix, localization, observability, incident/recovery '
          'drills (145.17 registry: Regional scale)',
    ),
    ReactivationEntry(
      capabilityId: 'MOBILE_FULL_EDITOR',
      label: 'Mobile full editor',
      layer: 'PLATFORM FOLLOW-UP',
      featureModules: <String>[],
      entryEvidence:
          'Android/iOS persistence, permissions, interruption/restart, '
          'responsive integration (145.17 registry: Mobile full editor)',
    ),
    ReactivationEntry(
      capabilityId: 'MACOS_RELEASE',
      label: 'macOS release (signing & notarization)',
      layer: 'PLATFORM FOLLOW-UP',
      featureModules: <String>[],
      entryEvidence:
          'Developer ID, notarization, packaging, native storage and QA '
          'evidence (145.17 registry: macOS release)',
    ),
    ReactivationEntry(
      capabilityId: 'DOZENS_OF_AI_AND_CLOUD_PROVIDERS',
      label: 'Dozens of AI & cloud providers',
      layer: 'CLOUD FOLLOW-UP',
      featureModules: <String>['ai'],
      entryEvidence:
          'One-by-one provider contract and sandbox evidence '
          '(145.17 registry: Dozens of AI/cloud providers)',
    ),
    // ---- Demo engine capabilities (dibekukan Choi 2026-09-05, prasyarat
    // ---- 145.43). Modul demo hidup di lib/core/<domain>/ (bukan
    // ---- lib/features), sehingga featureModules dibiarkan kosong.
    ReactivationEntry(
      capabilityId: 'RENDER_ENGINE',
      label: 'Render engine (demo preview)',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Renderer pipeline evidence + user validation (145.17 registry: '
          'Render engine)',
    ),
    ReactivationEntry(
      capabilityId: 'ANIMATION_ENGINE',
      label: 'Animation engine (demo preview)',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Animation pipeline evidence + user validation (145.17 registry: '
          'Animation engine)',
    ),
    ReactivationEntry(
      capabilityId: 'AUDIO_ENGINE',
      label: 'Audio engine (demo preview)',
      layer: 'ENGINE FOLLOW-UP',
      featureModules: <String>['audio'],
      entryEvidence:
          'Audio pipeline evidence + user validation (145.17 registry: '
          'Audio engine)',
    ),
    ReactivationEntry(
      capabilityId: 'VIRTUAL_PRODUCTION',
      label: 'Virtual production suite',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Virtual production workflow evidence (145.17 registry: Virtual '
          'production)',
    ),
    ReactivationEntry(
      capabilityId: 'ENTERPRISE_STUDIO',
      label: 'Enterprise studio tooling',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Enterprise workflow evidence (145.17 registry: Enterprise studio)',
    ),
    ReactivationEntry(
      capabilityId: 'KNOWLEDGE_ENGINE',
      label: 'Knowledge engine (demo preview)',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Knowledge pipeline evidence + user validation (145.17 registry: '
          'Knowledge engine)',
    ),
    ReactivationEntry(
      capabilityId: 'AGENT_RUNTIME',
      label: 'Agent runtime',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Agent safety + execution evidence (145.17 registry: Agent '
          'runtime)',
    ),
    ReactivationEntry(
      capabilityId: 'STUDIO_COMMAND_CENTER',
      label: 'Studio command center',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Governance/task workflow evidence (145.17 registry: Studio '
          'command center)',
    ),
    ReactivationEntry(
      capabilityId: 'CREATIVE_OS',
      label: 'Creative OS surface',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Creative OS integration evidence (145.17 registry: Creative OS)',
    ),
    ReactivationEntry(
      capabilityId: 'XR_STUDIO',
      label: 'XR Studio surface',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'XR pipeline evidence + device validation (145.17 registry: XR '
          'Studio)',
    ),
    ReactivationEntry(
      capabilityId: 'METAVERSE_STUDIO',
      label: 'Metaverse Studio surface',
      layer: 'ENGINE FOLLOW-UP',
      entryEvidence:
          'Metaverse pipeline evidence + user validation (145.17 registry: '
          'Metaverse Studio)',
    ),
  ];
}
