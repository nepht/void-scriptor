import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/job_policy.dart';

void main() {
  test('platform defaults: desktop workers 2-4, mobile 1-2', () {
    expect(
      JobPolicy.workersFor(TargetPlatformKind.desktop, highPower: true),
      4,
    );
    expect(
      JobPolicy.workersFor(TargetPlatformKind.desktop, highPower: false),
      2,
    );
    expect(JobPolicy.workersFor(TargetPlatformKind.mobile, highPower: true), 2);
    expect(
      JobPolicy.workersFor(TargetPlatformKind.mobile, highPower: false),
      1,
    );
  });

  test('battery saver mode restricts expensive background jobs', () {
    const policy = JobPolicy(
      network: NetworkJobPolicy.wifiOnly,
      batterySaver: true,
    );

    expect(policy.isExpensiveJobAllowed, isFalse);
  });

  test('wifi-only network policy gates network jobs', () {
    const wifiOnly = JobPolicy(network: NetworkJobPolicy.wifiOnly);

    expect(wifiOnly.allowsNetworkJob(onWifi: true), isTrue);
    expect(wifiOnly.allowsNetworkJob(onWifi: false), isFalse);

    const unrestricted = JobPolicy(network: NetworkJobPolicy.unrestricted);
    expect(unrestricted.allowsNetworkJob(onWifi: false), isTrue);
  });
}
