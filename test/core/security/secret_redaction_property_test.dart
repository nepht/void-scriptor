import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';

/// Property-style exhaustive coverage for the redaction primitives
/// (Sprint 145.36 "redaction" axis: provider payloads must never leak
/// credentials into logs/history; these properties hold for every value
/// the primitives can receive).
void main() {
  const redactor = SecretRedactor();
  const scanner = SecretScanner();
  final rng = Random(14536);

  String randomSecret(
    int length, {
    bool allowDash = false,
    bool upper = false,
  }) {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const alphabetDash =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-';
    const alphabetUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final chars = upper
        ? alphabetUpper
        : allowDash
        ? alphabetDash
        : alphabet;
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
      growable: false,
    ).join();
  }

  /// Builds a credential whose body matches the scanner's format regex.
  String formatSecret(
    String prefix,
    int bodyLength, {
    bool allowDash = false,
    bool upper = false,
  }) {
    return '$prefix${randomSecret(bodyLength, allowDash: allowDash, upper: upper)}';
  }

  group('SecretRedactor.mask properties (exhaustive lengths)', () {
    test('empty stays empty', () {
      expect(redactor.mask(''), '');
    });

    test('every short value (1..4) becomes four asterisks', () {
      for (var length = 1; length <= 4; length++) {
        for (var i = 0; i < 25; i++) {
          expect(
            redactor.mask(randomSecret(length)),
            '****',
            reason: 'length=$length',
          );
        }
      }
    });

    test(
      'every longer value keeps first 3 chars and never contains full value',
      () {
        for (var length = 5; length <= 64; length += 3) {
          for (var i = 0; i < 25; i++) {
            final value = randomSecret(length);
            final masked = redactor.mask(value);
            expect(
              masked.length,
              7,
              reason: 'masked=$masked value-len=$length',
            );
            expect(masked.substring(0, 3), value.substring(0, 3));
            expect(masked, '${value.substring(0, 3)}****');
            expect(
              masked,
              isNot(contains(value)),
              reason: 'mask must never contain the whole secret',
            );
          }
        }
      },
    );

    test('mask is deterministic', () {
      for (var i = 0; i < 20; i++) {
        final value = randomSecret(8 + rng.nextInt(24));
        expect(redactor.mask(value), redactor.mask(value));
      }
    });

    test('masking a masked value does not throw and stays stable', () {
      for (var i = 0; i < 20; i++) {
        final once = redactor.mask(randomSecret(20));
        expect(
          redactor.mask(once),
          once,
          reason: 'mask(mask(x)) should be stable for short masked forms',
        );
      }
    });
  });

  group('SecretRedactor.redact properties', () {
    test('replaces every occurrence of every listed secret', () {
      final secrets = List.generate(
        10,
        (_) => randomSecret(12 + rng.nextInt(20)),
        growable: false,
      );
      final builder = StringBuffer();
      for (var i = 0; i < 10; i++) {
        builder
          ..write('prefix-$i ')
          ..write(secrets[i])
          ..write(' suffix-$i ');
      }
      builder
        ..write('begin ')
        ..write(secrets[0])
        ..write(' mid ')
        ..write(secrets[1])
        ..write(' end');
      final cleaned = redactor.redact(builder.toString(), secrets: secrets);
      for (final secret in secrets) {
        expect(
          cleaned,
          isNot(contains(secret)),
          reason: 'secret #${secrets.indexOf(secret)} leaked',
        );
      }
      expect('[REDACTED]'.allMatches(cleaned).length, 12);
      expect(cleaned, contains('begin [REDACTED]'));
      expect(cleaned, contains('[REDACTED] end'));
    });

    test('redact with empty secret list is identity', () {
      const text = 'any text without secrets stays intact';
      expect(redactor.redact(text, secrets: const []), text);
    });

    test('redact is idempotent: no [REDACTED] token is ever re-scanned', () {
      final secrets = [
        '[REDACTED]',
        ...List.generate(5, (_) => randomSecret(16), growable: false),
      ];
      final payload = 'a=${secrets[1]} b=${secrets[2]} c=${secrets[3]}';
      final once = redactor.redact(payload, secrets: secrets);
      final twice = redactor.redact(once, secrets: secrets);
      expect(once, twice);
      // No plaintext secret and no nested redaction marker remains.
      expect(once, isNot(contains(secrets[1])));
      expect(once, isNot(contains('[REDACTED][REDACTED]')));
    });

    test('overlapping secrets: longer secret wins, no partial residue', () {
      const long = 'long-prefix-abcdefghij';
      final short = long.substring(0, 12);
      final payload = 'token=$long;also=$short';
      final cleaned = redactor.redact(payload, secrets: [short, long]);
      expect(cleaned, isNot(contains(long)));
      expect(cleaned, isNot(contains(short)));
      // The longer replacement first leaves no partial short secret.
      expect('[REDACTED]'.allMatches(cleaned).length, 2);
    });
  });

  group('SecretScanner detection properties', () {
    final formats = <String, String>{
      'openai sk': formatSecret('sk-', 40),
      'aws access key': formatSecret('AKIA', 16, upper: true),
      'github token': formatSecret('ghp_', 36),
      'slack token': formatSecret('xoxb-', 24, allowDash: true),
    };

    test('detects every supported credential format inside free text', () {
      for (final entry in formats.entries) {
        final text = 'log line: ${entry.value} at end';
        final found = scanner.scan(text);
        expect(
          found,
          contains(entry.value),
          reason: 'format ${entry.key} not detected',
        );
      }
    });

    test('does not false-positive on ordinary prose', () {
      const prose = [
        'The story begins with a hero named Alex and a token of friendship.',
        'She said "ok" and walked away; no keys were involved today.',
        'xoxb is not a word; AKIA means nothing here; ghp means nothing.',
        'short sk-1 keys and akia short values never match',
        'line with sk-abc123 (too short) and ghp_x (too short)',
        'SK- prefix uppercase is not the lowercase pattern',
      ];
      for (final text in prose) {
        expect(scanner.scan(text), isEmpty, reason: 'false positive: $text');
      }
    });

    test('matches are exact and non-empty for realistic keys', () {
      final text = formats.values.join(' ');
      final found = scanner.scan(text);
      for (final value in formats.values) {
        expect(found, contains(value));
      }
      for (final match in found) {
        expect(match, isNotEmpty);
      }
    });
  });
}
