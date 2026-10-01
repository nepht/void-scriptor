/// Detects common secret patterns for warnings (Step 30.12).
///
/// 117.32: the four original patterns were measured against realistic
/// credentials and matched none of them — a PEM private key block, an
/// OpenSSH key, a Google API key, an Anthropic key, a GitHub fine-grained
/// PAT, a Slack webhook URL, a Stripe live key, and a JWT all passed
/// straight through, while a synthetic `sk-abcdefgh12345678` was caught.
/// Whatever `ArchiveSecretPolicy` relies on to keep credentials out of a
/// portable archive was therefore only as good as those four literals. The
/// families below are the ones that actually occur in this project's own
/// provider and dependency surface.
class SecretScanner {
  const SecretScanner();

  static final _patterns = <RegExp>[
    RegExp(r'sk-[A-Za-z0-9]{8,}'),
    RegExp(r'AKIA[A-Z0-9]{16}'),
    RegExp(r'ghp_[A-Za-z0-9]{20,}'),
    RegExp(r'xox[baprs]-[A-Za-z0-9-]{10,}'),
    // PEM / OpenSSH private key material, in any armor label.
    RegExp(r'-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----'),
    // Google API keys.
    RegExp(r'AIza[0-9A-Za-z_\-]{35}'),
    // Anthropic and Stripe keys with an explicit provider prefix.
    RegExp(r'sk-ant-[A-Za-z0-9_\-]{16,}'),
    RegExp(r'sk_(?:live|test)_[A-Za-z0-9]{10,}'),
    // GitHub fine-grained personal access tokens.
    RegExp(r'github_pat_[A-Za-z0-9_]{20,}'),
    // Slack incoming-webhook URLs.
    RegExp(r'https://hooks\.slack\.com/services/[A-Za-z0-9/+_-]{8,}'),
    // Compact JWT: header.payload.signature, every segment non-empty.
    RegExp(r'eyJ[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}'),
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
