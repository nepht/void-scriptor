/// Platform capability contract (G5).
///
/// Declares what the current platform can honestly do. Capabilities are
/// injected (`isWeb:`) so tests stay deterministic; production resolves via
/// [resolveCurrentPlatformCapabilities].
library;

import 'package:flutter/foundation.dart';

/// Capabilities Void Scriptor relies on for project-level work.
enum PlatformCapability {
  /// Real local filesystem folders (project packages).
  localFileSystem('Local file system'),

  /// Per-project SQLite databases via drift NativeDatabase.
  projectSqliteDatabase('Project SQLite database'),

  /// Read-only SQLite access (recovery/audit paths).
  readOnlySqlite('Read-only SQLite');

  const PlatformCapability(this.label);

  final String label;
}

/// Builds the human-readable, actionable message for a missing capability.
String unsupportedCapabilityMessage({
  required PlatformCapability capability,
  required String action,
  required String platformLabel,
}) =>
    '$platformLabel belum mendukung "$action" '
    '(${capability.label} belum tersedia di platform ini). '
    'Gunakan aplikasi desktop (Windows/macOS/Linux) untuk aksi ini.';

/// Typed, actionable error raised when a platform lacks a capability.
class UnsupportedPlatformCapabilityError extends UnsupportedError {
  UnsupportedPlatformCapabilityError(
    this.capability, {
    required this.action,
    required this.platformLabel,
  }) : super(
         unsupportedCapabilityMessage(
           capability: capability,
           action: action,
           platformLabel: platformLabel,
         ),
       );

  final PlatformCapability capability;
  final String action;
  final String platformLabel;

  @override
  String toString() => 'UnsupportedPlatformCapabilityError: $message';
}

/// Immutable set of capabilities for one platform.
class PlatformCapabilitySet {
  const PlatformCapabilitySet._(this._supported, this._platformLabel);

  final Set<PlatformCapability> _supported;
  final String _platformLabel;

  bool supports(PlatformCapability capability) =>
      _supported.contains(capability);

  /// Throws [UnsupportedPlatformCapabilityError] naming [action] when the
  /// capability is missing; returns silently when present.
  void require(PlatformCapability capability, {required String action}) {
    if (_supported.contains(capability)) return;
    throw UnsupportedPlatformCapabilityError(
      capability,
      action: action,
      platformLabel: _platformLabel,
    );
  }

  /// Human-readable, actionable message for a missing capability without
  /// throwing — for inline UI banners.
  String unsupportedMessageFor(
    PlatformCapability capability, {
    required String action,
  }) {
    return unsupportedCapabilityMessage(
      capability: capability,
      action: action,
      platformLabel: _platformLabel,
    );
  }
}

const Set<PlatformCapability> _nativeCapabilities = {
  PlatformCapability.localFileSystem,
  PlatformCapability.projectSqliteDatabase,
  PlatformCapability.readOnlySqlite,
};

// Web today: project packages use dart:io and read-only SQLite throws
// UnsupportedError, so no project-persistence capability is claimed.
const Set<PlatformCapability> _webCapabilities = {};

PlatformCapabilitySet resolvePlatformCapabilities({required bool isWeb}) =>
    isWeb
    ? const PlatformCapabilitySet._(_webCapabilities, 'Web')
    : const PlatformCapabilitySet._(_nativeCapabilities, 'Desktop');

/// Production seam: resolves from the real platform.
PlatformCapabilitySet resolveCurrentPlatformCapabilities() =>
    resolvePlatformCapabilities(isWeb: kIsWeb);
