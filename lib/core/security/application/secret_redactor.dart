/// Masks and redacts secret values (Step 30.11).
class SecretRedactor {
  const SecretRedactor();

  String mask(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 4) return '****';
    return '${value.substring(0, 3)}****';
  }

  /// Replaces every occurrence of every listed secret with `[REDACTED]`.
  ///
  /// 117.32: two measured failures in the previous implementation.
  ///
  /// Exact-substring matching let a case variant through — `replaceAll` is
  /// case-sensitive, so an uppercase rendering of a stored secret was logged
  /// in full.
  ///
  /// Order dependence meant the outcome changed with the order of the input
  /// list: with `['sk-abc', 'sk-abcDEF…']` the shorter secret is replaced
  /// first and leaves `sk-[REDACTED]DEF…`, while the reverse order fully
  /// redacts it. Reordering the same secrets therefore changed what was
  /// logged. Sorting longest-first makes a secret always replace a prefix of
  /// a longer one, and the result no longer depends on input order.
  String redact(String text, {required List<String> secrets}) {
    // Longest first: a short secret that is a prefix of a longer one must not
    // be substituted before the longer match, or the tail stays in the log.
    final ordered = secrets.where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    // De-duplicate case-insensitively: two entries differing only by case
    // would otherwise drive two separate passes over the same text.
    final seen = <String, String>{};
    for (final secret in ordered) {
      seen.putIfAbsent(secret.toLowerCase(), () => secret);
    }
    var result = text;
    for (final secret in seen.values) {
      // Escape the secret so a credential containing regex metacharacters —
      // which real base64/JWT secrets routinely do — is matched literally
      // instead of silently failing to compile or matching something else.
      result = result.replaceAll(
        RegExp(RegExp.escape(secret), caseSensitive: false),
        '[REDACTED]',
      );
    }
    return result;
  }
}
