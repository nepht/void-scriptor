import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_localization_formatting.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';

void main() {
  group('115.49 required_evidence bucket', () {
    test('locks the eight canonical buckets in canonical order', () {
      expect(
        AccountCenterLocalizationFormatting.requiredEvidence,
        const <String>[
          'text_expansion',
          'rtl',
          'dates',
          'relative_time',
          'storage_units',
          'percentages',
          'currencies',
          'tax',
        ],
      );
    });

    test('rejects a bucket outside the canonical set', () {
      expect(
        () => AccountCenterLocalizationFormatting.buildReport({
          for (final key
              in AccountCenterLocalizationFormatting.requiredEvidence)
            key: const AccountCenterLocalizationEvidence(
              localResult: 'PASS',
              note: 'ok',
            ),
          'provider_names': const AccountCenterLocalizationEvidence(
            localResult: 'PASS',
            note: 'extra',
          ),
        }),
        throwsArgumentError,
      );
    });

    test('fails closed when a canonical bucket is missing', () {
      expect(
        () => AccountCenterLocalizationFormatting.buildReport({
          'text_expansion': const AccountCenterLocalizationEvidence(
            localResult: 'PASS',
            note: 'ok',
          ),
        }),
        throwsStateError,
      );
    });

    test('passes only when every canonical bucket reports PASS', () {
      final pass = AccountCenterLocalizationFormatting.buildReport({
        for (final key in AccountCenterLocalizationFormatting.requiredEvidence)
          key: const AccountCenterLocalizationEvidence(
            localResult: 'PASS',
            note: 'ok',
          ),
      });
      expect(pass.isPass, isTrue);
      expect(pass.toPublicJson().keys.toSet(), {
        for (final key in AccountCenterLocalizationFormatting.requiredEvidence)
          key,
      });

      final withGap = AccountCenterLocalizationFormatting.buildReport({
        for (final key in AccountCenterLocalizationFormatting.requiredEvidence)
          key: AccountCenterLocalizationEvidence(
            localResult: key == 'dates' ? 'GAP' : 'PASS',
            note: 'dates not rendered yet',
          ),
      });
      expect(withGap.isPass, isFalse);
      expect(withGap.toPublicJson()['dates'], 'GAP');
    });
  });

  group('115.49 storage_units', () {
    test('formats decimal units, not binary units under a decimal label', () {
      expect(
        AccountCenterLocalizationFormatting.storageUnits(-1),
        'unavailable',
      );
      expect(AccountCenterLocalizationFormatting.storageUnits(0), '0 B');
      expect(AccountCenterLocalizationFormatting.storageUnits(999), '999 B');
      expect(AccountCenterLocalizationFormatting.storageUnits(1000), '1 KB');
      expect(AccountCenterLocalizationFormatting.storageUnits(1500), '1.5 KB');
      expect(AccountCenterLocalizationFormatting.storageUnits(4096), '4.1 KB');
      expect(AccountCenterLocalizationFormatting.storageUnits(1000000), '1 MB');
      expect(
        AccountCenterLocalizationFormatting.storageUnits(1500000000),
        '1.5 GB',
      );
      expect(
        AccountCenterLocalizationFormatting.storageUnits(2500000000000),
        '2.5 TB',
      );
    });

    test('one binary gibibyte is not labelled one decimal gigabyte', () {
      // 1 GiB = 1073741824 B = 1.07 decimal GB; the binary formatter that the
      // chrome used before 115.49 printed `1.0 GB` for this value.
      expect(
        AccountCenterLocalizationFormatting.storageUnits(1073741824),
        '1.07 GB',
      );
      expect(
        AccountCenterLocalizationFormatting.storageUnits(2147483648),
        '2.15 GB',
      );
      expect(
        AccountCenterLocalizationFormatting.storageUnits(1073741824),
        isNot('1.0 GB'),
      );
    });

    test('unit constants are the decimal ones the spec names', () {
      expect(AccountCenterLocalizationFormatting.kilobyte, 1000);
      expect(AccountCenterLocalizationFormatting.gigabyte, 1000000000);
      expect(AccountCenterLocalizationFormatting.terabyte, 1000000000000);
    });
  });

  group('115.49 percentages', () {
    test('computes shares fail-closed', () {
      expect(AccountCenterLocalizationFormatting.sharePercent(3072, 4096), 75);
      expect(AccountCenterLocalizationFormatting.sharePercent(1024, 4096), 25);
      expect(AccountCenterLocalizationFormatting.sharePercent(1, 3), 33);
      expect(AccountCenterLocalizationFormatting.sharePercent(0, 100), 0);
      expect(
        () => AccountCenterLocalizationFormatting.sharePercent(1, 0),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.sharePercent(-1, 100),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.sharePercent(101, 100),
        throwsArgumentError,
      );
    });

    test('labels percentages inside the valid range only', () {
      expect(AccountCenterLocalizationFormatting.percentLabel(0), '0%');
      expect(AccountCenterLocalizationFormatting.percentLabel(75), '75%');
      expect(AccountCenterLocalizationFormatting.percentLabel(100), '100%');
      expect(
        () => AccountCenterLocalizationFormatting.percentLabel(-1),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.percentLabel(101),
        throwsArgumentError,
      );
    });

    test('groups integers the way the chrome already renders them', () {
      expect(AccountCenterLocalizationFormatting.groupedInteger(0), '0');
      expect(AccountCenterLocalizationFormatting.groupedInteger(1540), '1,540');
      expect(
        AccountCenterLocalizationFormatting.groupedInteger(1234567),
        '1,234,567',
      );
    });
  });

  group('115.49 currencies', () {
    test('money keeps the two decimal places the chrome renders', () {
      expect(AccountCenterLocalizationFormatting.formatMoney(1.25), '1.25');
      expect(AccountCenterLocalizationFormatting.formatMoney(2), '2.00');
      expect(AccountCenterLocalizationFormatting.formatMoney(-0.5), '-0.50');
      expect(
        AccountCenterLocalizationFormatting.formatMoney(double.nan),
        'unavailable',
      );
    });

    test('currency codes must be ISO 4217 and keep their case', () {
      expect(
        AccountCenterLocalizationFormatting.normalizeCurrencyCode(' usd '),
        'usd',
      );
      expect(
        AccountCenterLocalizationFormatting.normalizeCurrencyCode('USD'),
        'USD',
      );
      expect(
        () => AccountCenterLocalizationFormatting.normalizeCurrencyCode('US'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.normalizeCurrencyCode('USDX'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.normalizeCurrencyCode('u d'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.normalizeCurrencyCode(''),
        throwsArgumentError,
      );
    });

    test('amounts never invent precision', () {
      expect(AccountCenterLocalizationFormatting.formatAmount(12), '12');
      expect(AccountCenterLocalizationFormatting.formatAmount(1.25), '1.25');
      expect(
        AccountCenterLocalizationFormatting.formatAmount(0.0001),
        '0.0001',
      );
      expect(
        AccountCenterLocalizationFormatting.formatAmount(double.infinity),
        'unavailable',
      );
    });

    test('a currency string always carries an explicit code', () {
      expect(
        AccountCenterLocalizationFormatting.formatCurrency(
          amount: 12.5,
          currencyCode: 'usd',
        ),
        '12.5 usd',
      );
      expect(
        AccountCenterLocalizationFormatting.formatCurrency(
          amount: 12,
          currencyCode: 'USD',
        ),
        '12 USD',
      );
      expect(
        () => AccountCenterLocalizationFormatting.formatCurrency(
          amount: 12,
          currencyCode: r'$',
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.49 dates', () {
    test('renders UTC dates as yyyy-MM-dd', () {
      expect(
        AccountCenterLocalizationFormatting.utcDate(DateTime.utc(2026, 4, 1)),
        '2026-04-01',
      );
      expect(
        AccountCenterLocalizationFormatting.utcDate(DateTime.utc(2026, 12, 31)),
        '2026-12-31',
      );
    });

    test('a local timestamp renders through its UTC value', () {
      final local = DateTime(2026, 4, 1, 17, 30);
      expect(
        AccountCenterLocalizationFormatting.utcDate(local),
        AccountCenterLocalizationFormatting.utcDate(local.toUtc()),
      );
    });
  });

  group('115.49 relative_time', () {
    final now = DateTime.utc(2026, 9, 27, 12);

    test('buckets are deterministic and pluralized', () {
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(seconds: 10)),
        ),
        'just now',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(minutes: 1)),
        ),
        '1 minute ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(minutes: 5)),
        ),
        '5 minutes ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(hours: 1)),
        ),
        '1 hour ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(hours: 3)),
        ),
        '3 hours ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(days: 1)),
        ),
        '1 day ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(days: 6)),
        ),
        '6 days ago',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(days: 30)),
        ),
        'on 2026-08-28',
      );
    });

    test('the boundary between "just now" and a minute is 60 seconds', () {
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(seconds: 59)),
        ),
        'just now',
      );
      expect(
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.subtract(const Duration(seconds: 60)),
        ),
        '1 minute ago',
      );
    });

    test('a future timestamp is rejected instead of rendered backwards', () {
      expect(
        () => AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.add(const Duration(seconds: 1)),
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.49 rtl', () {
    test('right-to-left scripts resolve to RTL', () {
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('ar'),
        TextDirection.rtl,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('ar-SA'),
        TextDirection.rtl,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('he-IL'),
        TextDirection.rtl,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('fa'),
        TextDirection.rtl,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('ur'),
        TextDirection.rtl,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('ckb'),
        TextDirection.rtl,
      );
    });

    test('everything else resolves to LTR and empty tags are rejected', () {
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('en'),
        TextDirection.ltr,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('en-US'),
        TextDirection.ltr,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor('id'),
        TextDirection.ltr,
      );
      expect(
        AccountCenterLocalizationFormatting.textDirectionFor(' DE '),
        TextDirection.ltr,
      );
      expect(
        () => AccountCenterLocalizationFormatting.textDirectionFor(''),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.textDirectionFor('   '),
        throwsArgumentError,
      );
    });
  });

  group('115.49 tax', () {
    test('canonical tax tokens render as readable text', () {
      expect(
        AccountCenterLocalizationFormatting.taxDisplay('not_applicable'),
        'Not applicable',
      );
      expect(
        AccountCenterLocalizationFormatting.taxDisplay('unavailable'),
        'Tax unavailable',
      );
      expect(
        AccountCenterLocalizationFormatting.taxDisplay('VAT 20.00% (GB)'),
        'VAT 20.00% (GB)',
      );
      expect(
        AccountCenterLocalizationFormatting.taxDisplay('  VAT 10.00% (US-CA) '),
        'VAT 10.00% (US-CA)',
      );
    });

    test('an unknown tax token fails closed instead of rendering verbatim', () {
      expect(
        () => AccountCenterLocalizationFormatting.taxDisplay(''),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.taxDisplay('  '),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.taxDisplay('taxed'),
        throwsArgumentError,
      );
      expect(
        () =>
            AccountCenterLocalizationFormatting.taxDisplay('20 percent maybe'),
        throwsArgumentError,
      );
    });
  });

  group('115.49 provider names', () {
    test('display names are trimmed and whitespace-collapsed', () {
      expect(
        AccountCenterLocalizationFormatting.providerDisplayName(
          '  Google Drive  ',
        ),
        'Google Drive',
      );
      expect(
        AccountCenterLocalizationFormatting.providerDisplayName('Open  AI'),
        'Open AI',
      );
    });

    test('blank names are rejected', () {
      expect(
        () => AccountCenterLocalizationFormatting.providerDisplayName(''),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.providerDisplayName('   '),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.providerDisplayName('\t\n'),
        throwsArgumentError,
      );
    });
  });

  group('115.49 provider names — inventory', () {
    test('every canonical provider name is already contract-normalized', () {
      final names = <String>[
        for (final entry in ProviderConnectorManifest.standard.all)
          entry.displayName,
        for (final icon in ProviderIconRegistry.standard.all) icon.displayName,
      ];
      expect(names, isNotEmpty);
      for (final name in names) {
        expect(name.trim(), name, reason: '"$name" belum trim.');
        expect(
          AccountCenterLocalizationFormatting.providerDisplayName(name),
          name,
          reason: '"$name" tidak idempoten di bawah normalisasi kontrak.',
        );
      }
    });
  });

  group('115.49 text_expansion', () {
    test('wrappable text rejects characters that break line breaking', () {
      expect(
        AccountCenterLocalizationFormatting.requireWrappable('4.1 KB indexed'),
        '4.1 KB indexed',
      );
      expect(
        () => AccountCenterLocalizationFormatting.requireWrappable(
          '16\u00A0GB indexed',
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.requireWrappable('1\u202FGB'),
        throwsArgumentError,
      );
      expect(
        () =>
            AccountCenterLocalizationFormatting.requireWrappable('item\u200B'),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterLocalizationFormatting.requireWrappable(''),
        throwsArgumentError,
      );
    });
  });
}
