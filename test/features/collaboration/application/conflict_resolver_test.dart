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

  // A key only the remote side changed is not a conflict, so no resolution is
  // supplied for it. The merged state must still carry the remote edit: the
  // base value it falls back to is the state the user already replaced.
  test('resolver keeps a remote-only edit instead of reverting it to base', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '1'},
      theirs: {'a': '2'},
    );
    final resolved = ConflictResolver.resolve(change, const {});
    expect(resolved['a'], '2');
  });

  // A key the remote side added is not in `ours` at all, so a merge that only
  // walks `ours` drops the remote addition without a trace.
  test('resolver keeps a remote-only addition instead of dropping it', () {
    const change = SyncChangeSet(base: {}, ours: {}, theirs: {'b': '2'});
    final resolved = ConflictResolver.resolve(change, const {});
    expect(resolved, {'b': '2'});
  });
}
