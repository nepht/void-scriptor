class PromptDiff {
  const PromptDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });
  final List<String> added;
  final List<String> removed;
  final bool changed;
}

/// Computes a simple line-level unified diff between prompt versions
/// (Step 28.19).
class PromptDiffer {
  const PromptDiffer();

  PromptDiff diff(String before, String after) {
    final beforeLines = before.split('\n');
    final afterLines = after.split('\n');
    final beforeSet = beforeLines.toSet();
    final afterSet = afterLines.toSet();
    final added = afterLines.where((line) => !beforeSet.contains(line)).toList();
    final removed = beforeLines
        .where((line) => !afterSet.contains(line))
        .toList();
    return PromptDiff(
      added: added,
      removed: removed,
      changed: added.isNotEmpty || removed.isNotEmpty,
    );
  }
}
