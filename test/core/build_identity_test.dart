import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/build_identity.dart';

void main() {
  test('local builds expose an honest identity without a fake SHA', () {
    expect(BuildIdentity.version, isNotEmpty);
    expect(BuildIdentity.commit, 'local');
    expect(BuildIdentity.channel, 'debug');
    expect(BuildIdentity.hasCommit, isFalse);
    expect(BuildIdentity.shortLabel, contains('local'));
  });
}
