import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/release/artifact_manifest.dart';

/// Sprint 102 / C6 — release-train foundation.
///
/// The manifest renderer must reproduce the LOCKED v1.0.1 artifact manifest
/// format exactly (docs/release/v1.0.1-artifact-manifest.md), so future RCs
/// are generated, not hand-edited.
void main() {
  group('ArtifactManifest markdown rendering', () {
    final manifest = ArtifactManifest(
      release: 'v9.9.9',
      candidate: 'v9.9.9-rc.1',
      commitSha: 'a' * 40,
      tagObjectSha: 'b' * 40,
      platform: 'Linux (Ubuntu WSL)',
      architecture: 'x64',
      buildMode: 'debug',
      buildCommand: 'flutter build linux --debug',
      artifactPath: 'build/linux/x64/debug/bundle/void_scriptor',
      artifactSizeBytes: 12345,
      sha256: 'c' * 64,
    );

    test('renders every locked-contract field', () {
      final out = manifest.toMarkdown();
      expect(out, contains('| Release | `v9.9.9` |'));
      expect(out, contains('| Candidate | `v9.9.9-rc.1` |'));
      expect(out, contains('| Commit SHA | `${'a' * 40}` |'));
      expect(out, contains('| Tag object | `${'b' * 40}` |'));
      expect(out, contains('| Artifact size | 12345 bytes |'));
      expect(out, contains('| SHA-256 | `${'c' * 64}` |'));
      expect(
        out,
        contains(
          '| Signature | NOT AVAILABLE — signing infrastructure not in scope |',
        ),
      );
    });

    test('is deterministic across calls', () {
      expect(manifest.toMarkdown(), manifest.toMarkdown());
    });

    test('matches the shape of the locked v1.0.1 contract', () {
      final out = manifest.toMarkdown();
      // Section headers of the locked document.
      expect(out, contains('# v9.9.9 Artifact Manifest'));
      expect(out, contains('## Candidate artifact'));
      expect(out, contains('## Validation evidence pada commit yang sama'));
      expect(out, contains('## Not covered'));
      expect(
        out,
        contains(
          'Jangan mengganti nilai terukur tanpa membangun ulang artefak',
        ),
      );
    });

    test('validation gates table renders measured values only', () {
      final out = manifest.toMarkdown(
        gates: const [
          ManifestGate(name: 'flutter analyze', result: 'PASS'),
          ManifestGate(name: 'full suite', result: 'PASS (+1522)'),
        ],
      );
      expect(out, contains('| `flutter analyze` | PASS |'));
      expect(out, contains('| `full suite` | PASS (+1522) |'));
    });
  });
}
