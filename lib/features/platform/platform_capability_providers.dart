import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/platform_capability.dart';

/// Capabilities of the platform this app instance runs on.
///
/// Override in tests to simulate a specific platform.
final platformCapabilitiesProvider = Provider<PlatformCapabilitySet>(
  (ref) => resolveCurrentPlatformCapabilities(),
);
