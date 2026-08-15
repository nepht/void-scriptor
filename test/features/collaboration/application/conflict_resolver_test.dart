import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/collaboration/application/conflict_resolver.dart';

void main() {
  test('detects 3-way conflict when both sides diverge', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '2'},
      theirs: {'a': '3'},
    );
    final conflicts = ConflictDetector.detect(change);
    expect(conflicts, ['a']);
  });

  test('no conflict when only ours changed', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '2'},
      theirs: {'a': '1'},
    );
    expect(ConflictDetector.detect(change), isEmpty);
  });

  test('resolver keepOurs picks ours value', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '2'},
      theirs: {'a': '3'},
    );
    final resolved = ConflictResolver.resolve(change, const {
      'a': ConflictResolution.keepOurs,
    });
    expect(resolved['a'], '2');
  });

  test('resolver keepTheirs picks theirs value', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '2'},
      theirs: {'a': '3'},
    );
    final resolved = ConflictResolver.resolve(change, const {
      'a': ConflictResolution.keepTheirs,
    });
    expect(resolved['a'], '3');
  });

  test('resolver leaves manual conflicts unresolved', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '2'},
      theirs: {'a': '3'},
    );
    final resolved = ConflictResolver.resolve(change, const {
      'a': ConflictResolution.manual,
    });
    expect(resolved.containsKey('a'), isFalse);
  });
}
