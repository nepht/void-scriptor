// Sprint 145.39 prasyarat — canonical demo route gating.
//
// Keputusan Choi (2026-09-05, otorisasi eksplisit): 11 route demo engine
// (render, animation, audio, virtual-production, enterprise-studio,
// knowledge, agents, studio-command-center, creative-os, xr-studio,
// metaverse) adalah surface non-Core deferred dan wajib digate oleh
// RouteCapabilityGuard dengan capabilityId kanonik yang didaftarkan di
// ReactivationDependencyMap. Selama capability belum di-allow (145.17),
// route dialihkan ke fallback Core (/dashboard).
//
// Slice ini diselesaikan sebagai prasyarat 145.43-145.47 (ADR-0003 Option B
// urutan kerja: route-gating demo sebelum pilot).
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/capabilities/reactivation_dependency_map.dart';
import 'package:void_scriptor/core/capabilities/route_capability_guard.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  const demoRoutes = <String>[
    '/render',
    '/animation',
    '/audio',
    '/virtual-production',
    '/enterprise-studio',
    '/knowledge',
    '/agents',
    '/studio-command-center',
    '/creative-os',
    '/xr-studio',
    '/metaverse',
  ];

  group('canonical demo route gating (keputusan Choi 2026-09-05)', () {
    test('canonical rules cover exactly the 11 demo routes + 2 deferred', () {
      final routes = RouteCapabilityGuard.canonicalRules
          .map((rule) => rule.route)
          .toSet();
      expect(routes, containsAll(demoRoutes));
      expect(routes, containsAll(<String>{'/publishing', '/plugins'}));
      expect(RouteCapabilityGuard.canonicalRules.length, 13);
    });

    test('setiap rule demo memetakan ke capabilityId kanonik peta reaktivasi',
        () {
      final knownIds = ReactivationDependencyMap.entries
          .map((entry) => entry.capabilityId)
          .toSet();
      for (final route in demoRoutes) {
        final rule = RouteCapabilityGuard.canonicalRules
            .singleWhere((rule) => rule.route == route);
        expect(knownIds.contains(rule.capabilityId), isTrue,
            reason: '$route memakai capabilityId tak kanonik');
        expect(rule.fallbackRoute, '/dashboard');
      }
    });

    test('peta reaktivasi mendaftar 11 capability demo engine baru', () {
      final ids = ReactivationDependencyMap.entries
          .map((entry) => entry.capabilityId)
          .toSet();
      const demoIds = <String>[
        'RENDER_ENGINE',
        'ANIMATION_ENGINE',
        'AUDIO_ENGINE',
        'VIRTUAL_PRODUCTION',
        'ENTERPRISE_STUDIO',
        'KNOWLEDGE_ENGINE',
        'AGENT_RUNTIME',
        'STUDIO_COMMAND_CENTER',
        'CREATIVE_OS',
        'XR_STUDIO',
        'METAVERSE_STUDIO',
      ];
      for (final id in demoIds) {
        expect(ids.contains(id), isTrue, reason: '$id belum terdaftar');
      }
    });

    test('route demo dialihkan ke dashboard selama capability deferred', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      for (final route in demoRoutes) {
        expect(guard.redirectFor(route), '/dashboard',
            reason: '$route harus digate selama capability deferred');
      }
    });

    test('allowCapability membuka satu route demo tanpa membuka lainnya', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      guard.allowCapability('RENDER_ENGINE');
      expect(guard.redirectFor('/render'), isNull);
      expect(guard.redirectFor('/animation'), '/dashboard');
    });

    test('route Core tetap tidak pernah dialihkan', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      for (final route in <String>[
        '/dashboard',
        '/projects',
        '/workspace',
        '/settings',
      ]) {
        expect(guard.redirectFor(route), isNull);
      }
    });
  });
}
