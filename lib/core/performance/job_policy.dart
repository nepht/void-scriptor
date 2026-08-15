/// Battery awareness (Step 26.70) and network job policy (Step 26.72).
///
/// Desktop can use more workers; mobile stays conservative for battery and
/// thermal reasons. Network work (AI downloads / cloud) can be gated to Wi-Fi
/// only, without hardcoding a mobile-specific branch prematurely.
enum TargetPlatformKind { desktop, mobile }

enum NetworkJobPolicy { unrestricted, wifiOnly }

class JobPolicy {
  const JobPolicy({
    this.network = NetworkJobPolicy.unrestricted,
    this.batterySaver = false,
  });

  final NetworkJobPolicy network;
  final bool batterySaver;

  static int workersFor(TargetPlatformKind kind, {required bool highPower}) {
    switch (kind) {
      case TargetPlatformKind.desktop:
        return highPower ? 4 : 2;
      case TargetPlatformKind.mobile:
        return highPower ? 2 : 1;
    }
  }

  /// Battery saver mode forbids expensive background work.
  bool get isExpensiveJobAllowed => !batterySaver;

  bool allowsNetworkJob({required bool onWifi}) {
    switch (network) {
      case NetworkJobPolicy.unrestricted:
        return true;
      case NetworkJobPolicy.wifiOnly:
        return onWifi;
    }
  }
}
