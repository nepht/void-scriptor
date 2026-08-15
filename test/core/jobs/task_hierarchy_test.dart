import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/task_hierarchy.dart';

void main() {
  test('JobDependency declares a dependsOn relationship', () {
    const dep = JobDependency(jobId: 'thumb-1', dependsOnId: 'hash-1');
    expect(dep.jobId, 'thumb-1');
    expect(dep.dependsOnId, 'hash-1');
  });

  test('task hierarchy groups derived children under a user parent', () {
    final hierarchy = TaskHierarchy();

    hierarchy.attach('import-1', label: 'Import 50 References');
    hierarchy.attachChild(
      'import-1',
      'import-1:copy',
      label: 'Copy files',
      kind: TaskKind.derived,
    );
    hierarchy.attachChild(
      'import-1',
      'import-1:hash',
      label: 'Calculate hashes',
      kind: TaskKind.derived,
    );

    final root = hierarchy.tree;
    expect(root, hasLength(1));
    expect(root.single.id, 'import-1');
    expect(root.single.children.map((c) => c.id), [
      'import-1:copy',
      'import-1:hash',
    ]);
  });

  test('derived child marks user task as derived', () {
    final hierarchy = TaskHierarchy();
    hierarchy.attach('import-2', label: 'Import');
    hierarchy.attachChild(
      'import-2',
      'import-2:thumb',
      label: 'Generate thumbnails',
      kind: TaskKind.derived,
    );

    expect(hierarchy.taskKindOf('import-2'), TaskKind.user);
    expect(hierarchy.taskKindOf('import-2:thumb'), TaskKind.derived);
  });

  test('unknown task ids return no kind', () {
    expect(TaskHierarchy().taskKindOf('missing'), isNull);
  });
}
