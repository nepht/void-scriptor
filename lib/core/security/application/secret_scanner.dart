/// Detects common secret patterns for warnings (Step 30.12).
class SecretScanner {
  const SecretScanner();

  static final _patterns = <RegExp>[
    RegExp(r'sk-[A-Za-z0-9]{8,}'),
    RegExp(r'AKIA[A-Z0-9]{16}'),
    RegExp(r'ghp_[A-Za-z0-9]{20,}'),
    RegExp(r'xox[baprs]-[A-Za-z0-9-]{10,}'),
  ];

  List<String> scan(String text) {
    final matches = <String>[];
    for (final pattern in _patterns) {
      for (final match in pattern.allMatches(text)) {
        matches.add(match.group(0)!);
      }
    }
    return matches;
  }
}
