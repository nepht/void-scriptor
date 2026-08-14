class ProjectMutationState {
  const ProjectMutationState({
    required this.currentSequence,
    required this.savedSequence,
  });

  final int currentSequence;
  final int savedSequence;

  bool get isDirty => currentSequence != savedSequence;

  ProjectMutationState mutated() => ProjectMutationState(
    currentSequence: currentSequence + 1,
    savedSequence: savedSequence,
  );

  ProjectMutationState saved() => ProjectMutationState(
    currentSequence: currentSequence,
    savedSequence: currentSequence,
  );
}
