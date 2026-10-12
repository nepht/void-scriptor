import 'dart:convert';
import 'dart:io';

/// The explicit, narrow operator authorization that promotes the observed
/// GitHub App example into the canonical certification/release gates.
///
/// This is deliberately separate from the historical delayed approval record:
/// it records the new scope granted by the operator without rewriting the old
/// decision or implying that unrelated providers were certified.
class GithubAppReleaseAuthorization {
  const GithubAppReleaseAuthorization({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.visibility,
    required this.releaseState,
    required this.operatorAuthorized,
    required this.evidenceSource,
    required this.evidenceStatus,
    required this.scope,
  });

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_github_app_release_authorization.json';
  static const String authorizedSnapshotManifestPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot_authorized.json';
  static const String evidencePath =
      'docs/evidence/account-center-live-observation-20261011.json';
  static const String authorizedProviderId = 'github';
  static const String authorizedConnectorVersion = 'manifest-v1';
  static const String authorizedStatus = 'CERTIFIED';
  static const String authorizedVisibility = 'EXPOSED';
  static const String authorizedReleaseState = 'GA_AUTHORIZED';
  static const String authorizedSnapshotVerdict =
      'CERTIFIED_CONNECTOR_SNAPSHOT_AUTHORIZED_LOCAL';
  static const String requiredEvidenceStatus =
      'VERIFIED_LIVE_CERTIFICATION_EXAMPLE';

  final String providerId;
  final String connectorVersion;
  final String status;
  final String visibility;
  final String releaseState;
  final bool operatorAuthorized;
  final String evidenceSource;
  final String evidenceStatus;
  final List<String> scope;

  bool get isValid =>
      providerId == authorizedProviderId &&
      connectorVersion == authorizedConnectorVersion &&
      status == authorizedStatus &&
      visibility == authorizedVisibility &&
      releaseState == authorizedReleaseState &&
      operatorAuthorized &&
      evidenceSource == evidencePath &&
      evidenceStatus == requiredEvidenceStatus &&
      scope.toSet().containsAll(<String>{
        'github_app_certification',
        'canonical_release_gate',
        'sprint_119_entry',
      });

  static GithubAppReleaseAuthorization? load() {
    final manifest = _readObject(manifestPath);
    final evidence = _readObject(evidencePath);
    if (manifest == null || evidence == null) return null;

    final live = evidence['github_app_certification_example_observation'];
    if (live is! Map<String, dynamic> ||
        live['status'] != requiredEvidenceStatus ||
        live['resources'] is! Map<String, dynamic> ||
        live['rate_limit'] is! Map<String, dynamic> ||
        live['audit_event_counts'] is! Map<String, dynamic>) {
      return null;
    }

    final resources = live['resources'] as Map<String, dynamic>;
    final repositories = resources['repositories'];
    if (resources['count'] != 3 ||
        repositories is! List ||
        repositories.length != 3) {
      return null;
    }

    final scope = _strings(manifest['scope']);
    final authorization = GithubAppReleaseAuthorization(
      providerId: _text(manifest['provider_id']),
      connectorVersion: _text(manifest['connector_version']),
      status: _text(manifest['status']),
      visibility: _text(manifest['visibility']),
      releaseState: _text(manifest['release_state']),
      operatorAuthorized: manifest['operator_authorized'] == true,
      evidenceSource: _text(manifest['evidence_source']),
      evidenceStatus: _text(manifest['evidence_status']),
      scope: scope,
    );
    return authorization.isValid ? authorization : null;
  }

  static Map<String, dynamic>? _readObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
