import 'dart:convert';
import 'dart:io';

/// Evidence gate for Sprint 114.1.
///
/// The delayed path is valid only as a local corrective record. It must not
/// imply that a public release, rollout, or telemetry window occurred.
class PostReleaseEntryGate {
  static const String canonicalStep = '114.1';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_post_release_entry_gate.json';

  static const List<String> requiredFields = <String>[
    'path',
    'release_status',
    'artifact_version',
    'rollout_stage',
    'known_issues',
    'residual_risks',
  ];

  static PostReleaseEntryGateResult validate(Map<String, dynamic> manifest) {
    final errors = <String>[];
    for (final field in requiredFields) {
      if (!manifest.containsKey(field)) {
        errors.add('missing required field: $field');
      }
    }

    final path = manifest['path'];
    final releaseStatus = manifest['release_status'];
    final rolloutStage = manifest['rollout_stage'];
    if (path == 'RELEASED' || releaseStatus == 'PUBLISHED') {
      errors.add('public release evidence is unavailable');
    }
    if (path != 'DELAYED') {
      errors.add('path must be DELAYED until public release evidence exists');
    }
    if (releaseStatus != 'DEFERRED_RELEASE') {
      errors.add('release_status must remain DEFERRED_RELEASE');
    }
    if (rolloutStage != 'NOT_STARTED') {
      errors.add('rollout_stage must remain NOT_STARTED');
    }
    if (manifest['artifact_version'] != '1.2.0-rc.1') {
      errors.add('artifact_version must identify the local RC candidate');
    }
    if (manifest['known_issues'] is! List<dynamic> ||
        manifest['residual_risks'] is! List<dynamic>) {
      errors.add('known_issues and residual_risks must be lists');
    }

    return PostReleaseEntryGateResult(errors.isEmpty, errors);
  }

  static PostReleaseEntryGateResult validateManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return const PostReleaseEntryGateResult(false, <String>[
        'manifest missing',
      ]);
    }
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (manifest['canonical_step'] != canonicalStep) {
      return const PostReleaseEntryGateResult(false, <String>[
        'canonical_step mismatch',
      ]);
    }
    return validate(manifest);
  }
}

class PostReleaseEntryGateResult {
  final bool isValid;
  final List<String> errors;

  const PostReleaseEntryGateResult(this.isValid, this.errors);
}
