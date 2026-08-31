// Sprint 145.22 — Module Boundary and Feature Flags.
//
// Enforceable capability boundary: a non-Core service is only reachable
// behind an explicit gate. When its feature flag is OFF, invoking the gated
// body MUST NOT run (no network/credential/filesystem/database side effect);
// the caller either receives the capability-disabled error (strict path) or
// a safe fallback (degraded path). When enabled, the body runs.

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/capabilities/capability_gate.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  const cloudSync = CapabilityDescriptor(
    id: 'cloud_sync',
    flag: 'vs12_spoiler_sharing', // existing wave-1 flag stands in for a
    // deferred non-Core capability.
    fallback: 'Sinkronisasi nonaktif: proyek berjalan sepenuhnya lokal.',
  );

  group('CapabilityGate default OFF', () {
    test('guard throws before running the body (no side effect)', () {
      final gate = CapabilityGate(
        flags: FeatureFlagRegistry(),
        capabilities: const [cloudSync],
      );

      var executed = false;
      expect(
        () => gate.run('cloud_sync', () {
          executed = true;
          return 'network touch';
        }),
        throwsA(
          isA<CapabilityDisabledError>().having(
            (e) => e.capabilityId,
            'capabilityId',
            'cloud_sync',
          ),
        ),
      );
      expect(executed, isFalse, reason: 'body must never run while OFF');
    });

    test('runOrFallback returns fallback without executing the body', () {
      final gate = CapabilityGate(
        flags: FeatureFlagRegistry(),
        capabilities: const [cloudSync],
      );

      var executed = 0;
      final result = gate.runOrFallback('cloud_sync', () {
        executed++;
        return 'remote';
      }, fallback: 'local');

      expect(result, 'local');
      expect(executed, 0, reason: 'OFF capability must not execute body');
    });

    test('error message exposes flag and fallback for diagnostics', () {
      final gate = CapabilityGate(
        flags: FeatureFlagRegistry(),
        capabilities: const [cloudSync],
      );

      try {
        gate.run('cloud_sync', () => 'x');
        fail('expected CapabilityDisabledError');
      } on CapabilityDisabledError catch (e) {
        expect(e.capabilityId, 'cloud_sync');
        expect(e.flag, 'vs12_spoiler_sharing');
        expect(e.message, contains('vs12_spoiler_sharing'));
        expect(e.message, contains('lokal'));
      }
    });
  });

  group('CapabilityGate when enabled', () {
    test('guard runs the body and returns its value', () {
      final flags = FeatureFlagRegistry()..enable('vs12_spoiler_sharing');
      final gate = CapabilityGate(
        flags: flags,
        capabilities: const [cloudSync],
      );

      var executed = false;
      final result = gate.run('cloud_sync', () {
        executed = true;
        return 'remote-ok';
      });

      expect(result, 'remote-ok');
      expect(executed, isTrue);
      expect(gate.isEnabled('cloud_sync'), isTrue);
    });
  });

  group('CapabilityGate validation and kill-switch', () {
    test('unknown capability id is rejected with ArgumentError', () {
      final gate = CapabilityGate(
        flags: FeatureFlagRegistry(),
        capabilities: const [cloudSync],
      );
      expect(() => gate.isEnabled('nope'), throwsArgumentError);
      expect(() => gate.run('nope', () => 1), throwsArgumentError);
    });

    test('kill-switch forces an enabled capability back to guarded OFF', () {
      final flags = FeatureFlagRegistry()..enable('vs12_spoiler_sharing');
      final gate = CapabilityGate(
        flags: flags,
        capabilities: const [cloudSync],
      );
      expect(gate.isEnabled('cloud_sync'), isTrue);

      flags.engageKillSwitch();

      expect(gate.isEnabled('cloud_sync'), isFalse);
      expect(
        () => gate.run('cloud_sync', () => 'x'),
        throwsA(isA<CapabilityDisabledError>()),
      );
    });
  });
}
