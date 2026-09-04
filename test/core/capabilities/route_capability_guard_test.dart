// Sprint 145.27 — Core Worldbuilding Reduction (uniform non-Core route
// gating boundary). Route capability guard tests.
//
// Contract under test: a Core-owned route guard that redirects non-Core
// routes to a Core fallback while their canonical deferred capability has
// no activation evidence, and lets them through once (and only once) the
// capability is explicitly reactivated per 145.17 approval rules.
//
// Core routes (dashboard, bible, projects, settings, ...) must never be
// redirected by this guard.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/capabilities/reactivation_dependency_map.dart';
import 'package:void_scriptor/core/capabilities/route_capability_guard.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  group('RouteCapabilityGuard canonical rules', () {
    test('covers exactly the canonical deferred routes', () {
      final routes = RouteCapabilityGuard.canonicalRules
          .map((rule) => rule.route)
          .toSet();
      expect(routes, <String>{'/publishing', '/plugins'});
      expect(RouteCapabilityGuard.canonicalRules.length, 2);
    });

    test('canonical capability ids exist in the reactivation map', () {
      final knownIds = ReactivationDependencyMap.entries
          .map((entry) => entry.capabilityId)
          .toSet();
      for (final rule in RouteCapabilityGuard.canonicalRules) {
        expect(knownIds, contains(rule.capabilityId));
      }
    });

    test('core routes are never redirected at defaults', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      for (final coreRoute in <String>[
        '/dashboard',
        '/projects',
        '/bible',
        '/settings',
        '/security',
        '/workspace',
        '/assets',
      ]) {
        expect(
          guard.redirectFor(coreRoute),
          isNull,
          reason: '$coreRoute is a Core route and must stay reachable',
        );
      }
    });

    test('deferred non-Core routes redirect to the Core fallback', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      expect(guard.redirectFor('/publishing'), '/dashboard');
      expect(guard.redirectFor('/plugins'), '/dashboard');
    });

    test('explicit reactivation lets a deferred route through', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      guard.allowCapability('PUBLIC_PUBLISHING');
      expect(guard.redirectFor('/publishing'), isNull);
      // Sibling capability stays gated.
      expect(guard.redirectFor('/plugins'), '/dashboard');
    });

    test('unknown capability id is rejected', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      expect(
        () => guard.allowCapability('NOT_IN_CANONICAL_MAP'),
        throwsArgumentError,
      );
    });
  });

  group('RouteCapabilityGuard flag-driven rules', () {
    test('flag OFF redirects, flag ON lets through', () {
      final flags = FeatureFlagRegistry();
      final guard = RouteCapabilityGuard(
        flags: flags,
        rules: const [
          RouteCapabilityRule(
            route: '/community',
            capabilityId: 'COMMUNITY_CHAT',
            owningFlag: 'vs12_spoiler_sharing',
            fallbackRoute: '/dashboard',
          ),
        ],
      );
      expect(guard.redirectFor('/community'), '/dashboard');
      flags.enable('vs12_spoiler_sharing');
      expect(guard.redirectFor('/community'), isNull);
    });

    test('kill switch forces every flag-gated route back to fallback', () {
      final flags = FeatureFlagRegistry();
      final guard = RouteCapabilityGuard(
        flags: flags,
        rules: const [
          RouteCapabilityRule(
            route: '/community',
            capabilityId: 'COMMUNITY_CHAT',
            owningFlag: 'vs12_spoiler_sharing',
            fallbackRoute: '/dashboard',
          ),
        ],
      );
      flags.enable('vs12_spoiler_sharing');
      expect(guard.redirectFor('/community'), isNull);
      flags.engageKillSwitch();
      expect(guard.redirectFor('/community'), '/dashboard');
    });
  });

  group('RouteCapabilityGuard validation', () {
    test('duplicate route rules are rejected', () {
      expect(
        () => RouteCapabilityGuard(
          flags: FeatureFlagRegistry(),
          rules: const [
            RouteCapabilityRule(
              route: '/publishing',
              capabilityId: 'PUBLIC_PUBLISHING',
              fallbackRoute: '/dashboard',
            ),
            RouteCapabilityRule(
              route: '/publishing',
              capabilityId: 'CONNECTOR_MARKETPLACE',
              fallbackRoute: '/dashboard',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('fallback pointing at a protected route is rejected', () {
      expect(
        () => RouteCapabilityGuard(
          flags: FeatureFlagRegistry(),
          rules: const [
            RouteCapabilityRule(
              route: '/publishing',
              capabilityId: 'PUBLIC_PUBLISHING',
              fallbackRoute: '/plugins',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rule for an unknown canonical capability is rejected', () {
      expect(
        () => RouteCapabilityGuard(
          flags: FeatureFlagRegistry(),
          rules: const [
            RouteCapabilityRule(
              route: '/somewhere',
              capabilityId: 'NOT_IN_CANONICAL_MAP',
              fallbackRoute: '/dashboard',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('allowCapability after redirect does not unlock other routes', () {
      final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
      guard.allowCapability('CONNECTOR_MARKETPLACE');
      expect(guard.redirectFor('/plugins'), isNull);
      expect(guard.redirectFor('/publishing'), '/dashboard');
    });
  });
}
