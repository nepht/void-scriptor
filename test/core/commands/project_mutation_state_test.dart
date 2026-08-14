import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/project_mutation_state.dart';

void main() {
  test('project mutation state is dirty when sequences differ', () {
    expect(
      const ProjectMutationState(currentSequence: 4, savedSequence: 4).isDirty,
      isFalse,
    );
    expect(
      const ProjectMutationState(currentSequence: 5, savedSequence: 4).isDirty,
      isTrue,
    );
  });

  test('save point and mutation advance immutable state', () {
    const initial = ProjectMutationState(currentSequence: 2, savedSequence: 2);
    final changed = initial.mutated();
    final saved = changed.saved();

    expect(changed.currentSequence, 3);
    expect(changed.savedSequence, 2);
    expect(saved.currentSequence, 3);
    expect(saved.savedSequence, 3);
    expect(saved.isDirty, isFalse);
  });
}
