import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/publishing/domain/build_target.dart';
import 'package:void_scriptor/core/publishing/domain/release_channel.dart';
import 'package:void_scriptor/core/publishing/domain/semver.dart';

void main() {
  test('BuildTarget enum values', () {
    expect(BuildTarget.values, hasLength(4));
    expect(BuildTarget.web.name, 'web');
  });

  test('ReleaseChannel enum values', () {
    expect(ReleaseChannel.values, hasLength(3));
    expect(ReleaseChannel.stable.name, 'stable');
  });

  test('SemVer parses and compares', () {
    final v1 = SemVer.parse('1.2.3');
    expect(v1.major, 1);
    expect(v1.minor, 2);
    expect(v1.patch, 3);
    expect(v1.toString(), '1.2.3');

    final v2 = SemVer.parse('1.2.4');
    expect(v1.compareTo(v2), lessThan(0));
    expect(v2.compareTo(v1), greaterThan(0));
    expect(v1.compareTo(SemVer.parse('1.2.3')), 0);
  });
}
