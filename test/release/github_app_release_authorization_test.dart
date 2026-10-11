import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/github_app_release_authorization.dart';

void main() {
  test('loads only the operator-authorized live GitHub App overlay', () {
    final authorization = GithubAppReleaseAuthorization.load();

    expect(authorization, isNotNull);
    expect(authorization!.isValid, isTrue);
    expect(authorization.providerId, 'github');
    expect(authorization.connectorVersion, 'manifest-v1');
    expect(authorization.status, 'CERTIFIED');
    expect(authorization.visibility, 'EXPOSED');
    expect(authorization.releaseState, 'GA_AUTHORIZED');
    expect(authorization.evidenceStatus, 'VERIFIED_LIVE_CERTIFICATION_EXAMPLE');
    expect(authorization.scope, contains('canonical_release_gate'));
  });
}
