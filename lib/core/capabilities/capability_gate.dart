/// Sprint 145.22 — Module Boundary and Feature Flags.
///
/// Enforceable boundary for non-Core (deferred) capabilities. A capability is
/// declared once via [CapabilityDescriptor] (stable id + owning feature flag
/// + human fallback), and every runtime entry into its service body goes
/// through [CapabilityGate]. While the flag is OFF, the guarded body can
/// never execute, so a disabled capability cannot perform network,
/// credential, filesystem, database, or payment side effects — the gate
/// throws [CapabilityDisabledError] before the body runs (strict path) or
/// returns a caller-provided fallback (degraded path).
///
/// [FeatureFlagRegistry] remains the single flag primitive: default OFF,
/// unknown ids rejected, kill-switch forces every flag back to guarded OFF.
/// This file lives in `lib/core` and imports nothing from `lib/features`.
library;

import '../feature_flags/feature_flag_registry.dart';

/// Static declaration of one optional (non-Core) capability.
class CapabilityDescriptor {
  const CapabilityDescriptor({
    required this.id,
    required this.flag,
    required this.fallback,
  });

  /// Stable capability identifier used at gate call sites (e.g. cloud_sync).
  final String id;

  /// The [FeatureFlagRegistry] flag that owns this capability's state.
  final String flag;

  /// Human-readable message describing the safe Core-only behavior while
  /// the capability is disabled.
  final String fallback;
}

/// Thrown by [CapabilityGate.run] before a disabled capability's body can
/// execute. Carries the capability id, owning flag, and the declared
/// fallback text so callers and diagnostics can act without re-deriving.
class CapabilityDisabledError extends Error {
  CapabilityDisabledError({
    required this.capabilityId,
    required this.flag,
    required this.fallback,
  });

  final String capabilityId;
  final String flag;
  final String fallback;

  String get message =>
      'Capability "$capabilityId" dinonaktifkan (flag $flag OFF). '
      '$fallback';

  @override
  String toString() => 'CapabilityDisabledError: $message';
}

/// Composition-root gate over [FeatureFlagRegistry].
///
/// Instances are independent; register the capabilities a composition root
/// wires, then guard every entry point of the wrapped non-Core service.
class CapabilityGate {
  CapabilityGate({
    required this._flags,
    required List<CapabilityDescriptor> capabilities,
  }) : _descriptors = Map<String, CapabilityDescriptor>.fromEntries(
         capabilities.map((c) => MapEntry(c.id, c)),
       );

  final FeatureFlagRegistry _flags;
  final Map<String, CapabilityDescriptor> _descriptors;

  /// True only when the owning flag is currently enabled.
  bool isEnabled(String capabilityId) {
    final descriptor = _require(capabilityId);
    return _flags.isEnabled(descriptor.flag);
  }

  /// Declared fallback text for diagnostics and UI banners.
  String fallbackFor(String capabilityId) => _require(capabilityId).fallback;

  /// Strict path: runs [body] only when the capability is enabled; throws
  /// [CapabilityDisabledError] BEFORE [body] executes otherwise.
  T run<T>(String capabilityId, T Function() body) {
    if (!isEnabled(capabilityId)) {
      final descriptor = _require(capabilityId);
      throw CapabilityDisabledError(
        capabilityId: descriptor.id,
        flag: descriptor.flag,
        fallback: descriptor.fallback,
      );
    }
    return body();
  }

  /// Degraded path: returns [fallback] without executing [body] while the
  /// capability is disabled; executes and returns [body] when enabled.
  T runOrFallback<T>(String capabilityId, T Function() body, {T? fallback}) {
    if (!isEnabled(capabilityId)) {
      if (fallback != null) return fallback;
      final descriptor = _require(capabilityId);
      throw CapabilityDisabledError(
        capabilityId: descriptor.id,
        flag: descriptor.flag,
        fallback: descriptor.fallback,
      );
    }
    return body();
  }

  CapabilityDescriptor _require(String capabilityId) {
    final descriptor = _descriptors[capabilityId];
    if (descriptor == null) {
      throw ArgumentError.value(
        capabilityId,
        'capabilityId',
        'Unknown capability id',
      );
    }
    return descriptor;
  }
}
