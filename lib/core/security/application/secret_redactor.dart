/// Masks and redacts secret values (Step 30.11).
class SecretRedactor {
  const SecretRedactor();

  String mask(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 4) return '****';
    return '${value.substring(0, 3)}****';
  }

  String redact(String text, {required List<String> secrets}) {
    var result = text;
    for (final secret in secrets) {
      if (secret.isNotEmpty) {
        result = result.replaceAll(secret, '[REDACTED]');
      }
    }
    return result;
  }
}
