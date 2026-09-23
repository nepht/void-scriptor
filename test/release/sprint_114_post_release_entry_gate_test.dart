import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/post_release_entry_gate.dart';

void main() {
  group('114.1 Post-Release Entry Gate', () {
    test('manifest records the delayed corrective path', () {
      final file = File(PostReleaseEntryGate.manifestPath);
      expect(file.existsSync(), isTrue);

      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '114.1');
      expect(manifest['path'], 'DELAYED');
      expect(manifest['release_status'], 'DEFERRED_RELEASE');
      expect(manifest['artifact_version'], '1.2.0-rc.1');
      expect(manifest['rollout_stage'], 'NOT_STARTED');
      expect(manifest['known_issues'], isA<List<dynamic>>());
      expect(manifest['residual_risks'], isA<List<dynamic>>());
    });

    test('validation rejects a fabricated released state', () {
      final result = PostReleaseEntryGate.validate(<String, dynamic>{
        'path': 'RELEASED',
        'release_status': 'PUBLISHED',
        'artifact_version': '1.2.0',
        'rollout_stage': 'ga-full',
        'known_issues': <String>[],
        'residual_risks': <String>[],
      });

      expect(result.isValid, isFalse);
      expect(result.errors, contains('public release evidence is unavailable'));
    });

    test('validation accepts the delayed local corrective record', () {
      final manifest =
          jsonDecode(File(PostReleaseEntryGate.manifestPath).readAsStringSync())
              as Map<String, dynamic>;

      final result = PostReleaseEntryGate.validate(manifest);
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
