import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/task_hierarchy.dart';

/// core-hunt-20260906 BUG-56: attachChild replaced _nodes[id] with a fresh
/// node, so the previous parent kept a stale orphan child object and an id
/// re-parented under two parents produced a duplicated, inconsistent tree.
void main() {
  group('core-hunt-20260906 task hierarchy re-attach (BUG-56)', () {
    test(
      're-attaching an id under a new parent detaches it from the old one',
      () {
        final hierarchy = TaskHierarchy();
        hierarchy.attach('import', label: 'Import');
        hierarchy.attachChild(
          'import',
          'hash',
          label: 'Hash',
          kind: TaskKind.derived,
        );
        hierarchy.attach('cleanup', label: 'Cleanup');

        hierarchy.attachChild(
          'cleanup',
          'hash',
          label: 'Hash',
          kind: TaskKind.derived,
        );

        final importNode = hierarchy.tree.firstWhere((n) => n.id == 'import');
        final cleanupNode = hierarchy.tree.firstWhere((n) => n.id == 'cleanup');
        expect(
          importNode.children.map((c) => c.id),
          isNot(contains('hash')),
          reason: 'BUG-56: old parent kept a stale orphan child object',
        );
        expect(cleanupNode.children.map((c) => c.id), contains('hash'));
      },
    );

    test('a re-attached id exists exactly once (moved, not duplicated)', () {
      final hierarchy = TaskHierarchy();
      hierarchy.attach('a', label: 'A');
      hierarchy.attach('b', label: 'B');
      hierarchy.attachChild('a', 'x', label: 'X', kind: TaskKind.derived);
      hierarchy.attachChild('b', 'x', label: 'X', kind: TaskKind.derived);

      // Re-attach MOVES the node: the old parent no longer holds it and
      // the id appears under exactly one parent in the whole tree.
      final aNode = hierarchy.tree.firstWhere((n) => n.id == 'a');
      expect(aNode.children.map((c) => c.id), isNot(contains('x')));
      final bNode = hierarchy.tree.firstWhere((n) => n.id == 'b');
      expect(bNode.children.single.id, 'x');
      final occurrences = hierarchy.tree
          .expand((n) => n.children)
          .where((c) => c.id == 'x')
          .length;
      expect(occurrences, 1, reason: 'BUG-56: duplicated nodes for one id');
    });

    test('re-attach updates label and kind in place', () {
      final hierarchy = TaskHierarchy();
      hierarchy.attach('p', label: 'P');
      hierarchy.attachChild('p', 'job', label: 'Old', kind: TaskKind.derived);
      hierarchy.attach('q', label: 'Q');

      hierarchy.attachChild('q', 'job', label: 'Renamed', kind: TaskKind.user);

      final node = hierarchy.tree
          .firstWhere((n) => n.id == 'q')
          .children
          .single;
      expect(node.label, 'Renamed');
      expect(node.kind, TaskKind.user);
    });

    test('self-parenting is a no-op, not a cycle', () {
      final hierarchy = TaskHierarchy();
      hierarchy.attach('p', label: 'P');
      hierarchy.attachChild('p', 'p', label: 'P', kind: TaskKind.user);
      final node = hierarchy.tree.firstWhere((n) => n.id == 'p');
      expect(node.children, isEmpty);
    });

    test('re-parenting under own descendant is refused (no cycle)', () {
      final hierarchy = TaskHierarchy();
      hierarchy.attach('root', label: 'Root');
      hierarchy.attachChild(
        'root',
        'mid',
        label: 'Mid',
        kind: TaskKind.derived,
      );
      hierarchy.attachChild(
        'mid',
        'leaf',
        label: 'Leaf',
        kind: TaskKind.derived,
      );

      // leaf cannot become the parent of root (cycle).
      hierarchy.attachChild('leaf', 'root', label: 'Root', kind: TaskKind.user);

      TaskNode? findNode(List<TaskNode> nodes, String id) {
        for (final node in nodes) {
          if (node.id == id) return node;
          final hit = findNode(node.children, id);
          if (hit != null) return hit;
        }
        return null;
      }

      final rootNode = findNode(hierarchy.tree, 'root')!;
      expect(rootNode.children.map((c) => c.id), contains('mid'));
      final midNode = findNode(hierarchy.tree, 'mid')!;
      expect(midNode.children.single.id, 'leaf');
      final leafNode = findNode(hierarchy.tree, 'leaf')!;
      expect(leafNode.children, isEmpty);
    });
  });
}
