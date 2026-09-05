/// Sprint 145.27 — Core Worldbuilding Reduction (uniform non-Core route
/// gating boundary).
///
/// Kontrak: route non-Core deferred (sumber kanonik:
/// `core_mvp_scope_reset_spec.json` -> deferred_until_evidence, dipetakan di
/// [ReactivationDependencyMap]) tidak boleh mengeksekusi permukaan produknya
/// selama capability-nya belum punya entry evidence 145.17. Guard ini adalah
/// satu mekanisme seragam di layer Core yang memutuskan redirect untuk route
/// tersebut; pemanggil (router/shell) tinggal meneruskan hasilnya tanpa
/// mengetahui daftar capability.
///
/// Aturan keputusan redirect:
/// 1. Route tanpa aturan = route Core -> tidak pernah dialihkan.
/// 2. Route dengan aturan dialihkan ke fallbackRoute selama:
///    - capability belum di-allow eksplisit (aktivasi 145.17), DAN
///    - owning flag-nya (bila ada) masih OFF.
/// 3. Kill-switch memaksa semua route ber-flag kembali ke fallback.
///
/// File ini di `lib/core`, tanpa import `lib/features` (arah dependensi Core
/// tetap turun), tanpa side effect runtime: guard hanya menjawab pertanyaan
/// redirect, tidak mengubah status apapun.
library;

import 'reactivation_dependency_map.dart';
import '../feature_flags/feature_flag_registry.dart';

/// Aturan gating untuk satu route non-Core deferred.
class RouteCapabilityRule {
  const RouteCapabilityRule({
    required this.route,
    required this.capabilityId,
    required this.fallbackRoute,
    this.owningFlag,
  });

  /// Path route yang digate (persis string route, bukan pattern).
  final String route;

  /// Capability kanonik pemilik route; wajib ada di
  /// [ReactivationDependencyMap.entries].
  final String capabilityId;

  /// Route Core tujuan redirect selama capability tidak tersedia.
  final String fallbackRoute;

  /// Flag [FeatureFlagRegistry] yang memegang state runtime, bila ada.
  /// Null = capability masih DEFERRED (belum ada flag khusus).
  final String? owningFlag;
}

/// Guard seragam route non-Core deferred. Lihat doc library di atas.
class RouteCapabilityGuard {
  /// Aturan awal kanonik: hanya route yang benar-benar terdaftar di router
  /// dan dipetakan ke capability deferred. Route Core (dashboard, bible,
  /// projects, settings, security, workspace, assets, ...) sengaja tidak
  /// punya aturan sehingga tidak pernah dialihkan.
  static const List<RouteCapabilityRule> canonicalRules = <RouteCapabilityRule>[
    RouteCapabilityRule(
      route: '/publishing',
      capabilityId: 'PUBLIC_PUBLISHING',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/plugins',
      capabilityId: 'CONNECTOR_MARKETPLACE',
      fallbackRoute: '/dashboard',
    ),
    // ---- Demo engine routes (dibekukan Choi 2026-09-05, prasyarat 145.43):
    // ---- selama capability belum di-allow (145.17), route demo dialihkan
    // ---- ke Dashboard agar Core MVP tetap bebas surface non-Core.
    RouteCapabilityRule(
      route: '/render',
      capabilityId: 'RENDER_ENGINE',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/animation',
      capabilityId: 'ANIMATION_ENGINE',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/audio',
      capabilityId: 'AUDIO_ENGINE',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/virtual-production',
      capabilityId: 'VIRTUAL_PRODUCTION',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/enterprise-studio',
      capabilityId: 'ENTERPRISE_STUDIO',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/knowledge',
      capabilityId: 'KNOWLEDGE_ENGINE',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/agents',
      capabilityId: 'AGENT_RUNTIME',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/studio-command-center',
      capabilityId: 'STUDIO_COMMAND_CENTER',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/creative-os',
      capabilityId: 'CREATIVE_OS',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/xr-studio',
      capabilityId: 'XR_STUDIO',
      fallbackRoute: '/dashboard',
    ),
    RouteCapabilityRule(
      route: '/metaverse',
      capabilityId: 'METAVERSE_STUDIO',
      fallbackRoute: '/dashboard',
    ),
  ];

  RouteCapabilityGuard({
    required this.flags,
    List<RouteCapabilityRule> rules = canonicalRules,
  }) : _rules = Map<String, RouteCapabilityRule>.fromEntries(
         rules.map((rule) => MapEntry(rule.route, rule)),
       ) {
    final seen = <String>{};
    for (final rule in rules) {
      if (!seen.add(rule.route)) {
        throw ArgumentError('Duplicate route rule for ${rule.route}');
      }
      final knownIds = ReactivationDependencyMap.entries
          .map((entry) => entry.capabilityId)
          .toSet();
      if (!knownIds.contains(rule.capabilityId)) {
        throw ArgumentError(
          'Unknown canonical capability: ${rule.capabilityId}',
        );
      }
    }
    final protected = <String>{
      ...canonicalRules.map((rule) => rule.route),
      ...rules.map((rule) => rule.route),
    };
    for (final rule in rules) {
      if (protected.contains(rule.fallbackRoute)) {
        throw ArgumentError(
          'Fallback route ${rule.fallbackRoute} for ${rule.route} points at '
          'a gated non-Core route; fallback must be a Core route',
        );
      }
    }
  }

  final FeatureFlagRegistry flags;
  final Map<String, RouteCapabilityRule> _rules;
  final Set<String> _allowedCapabilities = <String>{};

  /// Mengaktifkan satu capability (jalur approval 145.17): route-nya lewat,
  /// capability lain tetap digate. ID harus ada di peta reaktivasi kanonik.
  void allowCapability(String capabilityId) {
    final knownIds = ReactivationDependencyMap.entries
        .map((entry) => entry.capabilityId)
        .toSet();
    if (!knownIds.contains(capabilityId)) {
      throw ArgumentError('Unknown canonical capability: $capabilityId');
    }
    _allowedCapabilities.add(capabilityId);
  }

  /// Route fallback untuk [route], atau null bila route boleh lewat:
  /// route tanpa aturan (Core), atau capability-nya sudah tersedia.
  String? redirectFor(String route) {
    final rule = _rules[route];
    if (rule == null) return null;
    if (_allowedCapabilities.contains(rule.capabilityId)) return null;
    final flag = rule.owningFlag;
    if (flag != null && flags.isEnabled(flag)) return null;
    return rule.fallbackRoute;
  }
}
