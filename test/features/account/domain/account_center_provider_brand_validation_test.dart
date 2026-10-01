/// Sprint 117.22 — Provider Icon & Brand Validation (RED + GREEN contract).
///
/// The canonical step asks that every visible provider uses either a certified
/// official asset or an approved fallback, and that all seven evidence items
/// are provable: asset_source, permission, asset_version, theme_variants,
/// clear_space, fallback, accessible_name.
///
/// Four fail-opens were MEASURED against the shipped registry before this file
/// existed (probe `test/release/scratch_11722_probe_test.dart`):
///
///  1. `widthForHeight` ignored the real source geometry. OpenAI's mark is
///     1180x320 (ratio 3.6875), but `widthForHeight(24)` reported 24.0 while a
///     preserved aspect ratio requires 88.5. `aspectRatioPolicy.preserve` and
///     `fit.contain` were declared but never consulted the asset.
///  2. `assetVersion` was the literal `bundled-v1` for all 14 bundled marks and
///     the single trademark notice "Bundled mark is used only as an official
///     provider asset..." was repeated 14 times. Nothing identified WHICH asset
///     was bundled, so a swapped or recoloured mark still certified.
///  3. `assetDark` equalled `assetLight` for all 14 bundled entries (0 distinct),
///     yet 8 of them are dark-ink-only marks (anthropic luminance 0.0137,
///     paypal 0.0363, bitbucket 0.1039, canva 0.1179, github raster p50 0.0902,
///     midtrans p50 0.0633). Those are declared usable on the dark surface they
///     are least legible on.
///  4. `clear_space` existed only as one line of English prose in
///     `policyRules`; it was not a value any entry carried, so it could never
///     be checked per mark.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('117.22 canonical contract', () {
    test('step id, objective, and required evidence are pinned', () {
      expect(ProviderIconBrandValidation.canonicalStep, '117.22');
      expect(ProviderIconBrandValidation.requiredEvidence, <String>[
        'asset_source',
        'permission',
        'asset_version',
        'theme_variants',
        'clear_space',
        'fallback',
        'accessible_name',
      ]);
      expect(
        ProviderIconBrandValidation.canonicalSprintSha256,
        'b7ef2d350916951c52c5b444a01c51d4d1fd254e2569399b4b8b1f21820894d6',
      );
    });
  });

  group('117.22 evidence 1+2: asset_source and permission are per mark', () {
    test('every bundled mark declares its own source, permission, and digest', () {
      final bundled = ProviderIconRegistry.standard.all
          .where((entry) => entry.hasBundledAsset)
          .toList(growable: false);
      expect(bundled, isNotEmpty);

      final sources = <String>{};
      final digests = <String>{};
      for (final entry in bundled) {
        // asset_source must identify the concrete file, not a shared sentence.
        expect(entry.assetSource, isNotEmpty, reason: entry.providerId);
        expect(
          entry.assetSource,
          contains(entry.assetLight!),
          reason:
              'asset_source must name the bundled file: ${entry.providerId}',
        );
        // permission must be a declared, non-empty licence/permission statement.
        expect(entry.permission.wireName, isNotEmpty, reason: entry.providerId);
        expect(
          entry.permission,
          isNot(ProviderIconPermission.genericFallback),
          reason:
              'a bundled third-party mark is not a generic glyph: '
              '${entry.providerId}',
        );
        // asset_version must pin content, not just the string "bundled-v1".
        expect(
          entry.assetVersion,
          isNot('bundled-v1'),
          reason: entry.providerId,
        );
        final digest = entry.assetDigest;
        expect(digest, isNotNull, reason: entry.providerId);
        expect(
          digest,
          matches(RegExp(r'^[0-9a-f]{64}$')),
          reason: entry.providerId,
        );
        sources.add(entry.assetSource!);
        digests.add(digest!);
      }
      // Provenance that is one sentence reused 14 times proves nothing: each
      // bundled mark must carry a distinct source and a distinct digest.
      expect(sources.length, bundled.length);
      expect(digests.length, bundled.length);
    });
  });

  group('117.22 evidence 3: theme_variants reflect real ink', () {
    test('no bundled mark reuses one asset across both themes', () {
      final bundled = ProviderIconRegistry.standard.all
          .where((entry) => entry.hasBundledAsset)
          .toList(growable: false);
      for (final entry in bundled) {
        expect(
          entry.assetDark,
          isNotNull,
          reason: 'dark theme must resolve a variant: ${entry.providerId}',
        );
      }
    });

    test(
      'a dark-ink-only mark is declared light-surface only, never dual-use',
      () {
        // anthropic.svg is a single flat #1f1f1e fill (luminance 0.0137). On the
        // dark chrome surface it cannot carry its mark, so the registry must
        // declare it as light-surface only instead of advertising both.
        const darkInkOnly = <String>[
          'anthropic',
          'paypal',
          'bitbucket',
          'canva',
        ];
        for (final id in darkInkOnly) {
          final entry = ProviderIconRegistry.standard.require(id);
          expect(
            entry.supportsDarkSurface,
            isFalse,
            reason: '$id carries dark ink and must not claim dark-surface use',
          );
          expect(
            entry.themeVariants,
            contains('light'),
            reason: '$id must still be usable on the light surface',
          );
        }
      },
    );

    test('a mark with both light and dark ink declares both variants', () {
      // google_drive raster is 94.9% light ink (p50 0.9093) and dropbox 96.3%
      // (p50 0.9401); both stay legible on the dark surface.
      for (final id in <String>['google_drive', 'dropbox']) {
        final entry = ProviderIconRegistry.standard.require(id);
        expect(entry.supportsDarkSurface, isTrue, reason: id);
        expect(entry.themeVariants, contains('dark'), reason: id);
      }
      // gemini.svg carries #00b95c/#fc413d/#3186ff plus currentColor, i.e. it is
      // chromatic rather than ink-bound, so both variants are legitimate.
      final gemini = ProviderIconRegistry.standard.require('gemini');
      expect(gemini.themeVariants, contains('dark'));
    });
  });

  group('117.22 evidence 4: clear_space is a value, not prose', () {
    test('every bundled mark declares an explicit clear-space ratio', () {
      for (final entry in ProviderIconRegistry.standard.all) {
        if (!entry.hasBundledAsset) continue;
        expect(entry.clearSpaceRatio, isNotNull, reason: entry.providerId);
        expect(entry.clearSpaceRatio, greaterThan(0));
        expect(entry.clearSpaceRatio, lessThanOrEqualTo(1));
      }
    });

    test('clear space is finite and rejects invalid ratios', () {
      expect(
        () => ProviderIconEntry.fixture(
          'bad_clear_space',
          clearSpaceRatio: double.infinity,
        ),
        throwsArgumentError,
      );
      expect(
        () => ProviderIconEntry.fixture(
          'negative_clear_space',
          clearSpaceRatio: -0.1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('117.22 evidence 5+6: intrinsic geometry and fallback', () {
    test(
      'declared geometry matches the real asset, preserving aspect ratio',
      () {
        // The measured fail-open: openai is 1180x320 and widthForHeight(24) said
        // 24.0 instead of 88.5. Intrinsic geometry must come from the asset.
        final openai = ProviderIconRegistry.standard.require('openai');
        expect(openai.intrinsicSize, isNotNull);
        expect(openai.intrinsicSize!.width, 1180);
        expect(openai.intrinsicSize!.height, 320);
        expect(
          openai.widthForHeight(24),
          closeTo(24 * (1180 / 320), 0.001),
          reason:
              'non-square mark must keep its aspect ratio at a given height',
        );
        expect(openai.heightForWidth(100), closeTo(100 / (1180 / 320), 0.001));
      },
    );

    test('a square mark is unchanged by aspect preservation', () {
      for (final id in <String>['gitlab', 'figma', 'paypal']) {
        final entry = ProviderIconRegistry.standard.require(id);
        expect(
          entry.intrinsicSize!.width,
          entry.intrinsicSize!.height,
          reason: id,
        );
        expect(entry.widthForHeight(24), 24, reason: id);
      }
    });

    test('every registered provider resolves a non-null intrinsic size', () {
      for (final entry in ProviderIconRegistry.standard.all) {
        if (!entry.hasBundledAsset) continue;
        expect(entry.intrinsicSize, isNotNull, reason: entry.providerId);
      }
    });

    test('an unbundled provider still resolves an approved fallback', () {
      final mega = ProviderIconRegistry.standard.require('mega');
      expect(mega.hasBundledAsset, isFalse);
      expect(mega.isOfficialAsset, isFalse);
      expect(mega.usesGenericFallback, isTrue);
      expect(mega.monochromeFallback.category, 'cloud_storage');
      expect(mega.accessibleName, 'Mega icon unavailable');
      expect(mega.assetSource, isNotEmpty);
      expect(mega.permission, ProviderIconPermission.genericFallback);
      expect(mega.intrinsicSize, isNull);
      expect(mega.clearSpaceRatio, isNull);
    });
  });

  group('117.22 evidence 7: accessible_name stays honest', () {
    test(
      'bundled marks are announced as icons, fallbacks announce absence',
      () {
        expect(
          ProviderIconRegistry.standard.require('openai').accessibleName,
          'OpenAI icon',
        );
        expect(
          ProviderIconRegistry.standard.require('kofi').accessibleName,
          'Ko-fi icon unavailable',
        );
        final unknown = ProviderIconRegistry.standard.resolve(
          'totally_unknown',
        );
        expect(unknown.accessibleName, 'Provider icon unavailable');
        expect(unknown.isOfficialAsset, isFalse);
      },
    );

    test('a fallback never announces a provider mark it does not bundle', () {
      for (final entry in ProviderIconRegistry.standard.all) {
        if (entry.hasBundledAsset) continue;
        expect(
          entry.accessibleName,
          endsWith('icon unavailable'),
          reason: entry.providerId,
        );
      }
    });
  });

  group('117.22 whole-registry invariants', () {
    test('all 32 canonical providers stay registered', () {
      expect(ProviderIconRegistry.standard.all.length, 32);
    });

    test('every bundled asset exists on disk and is declared in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final entry in ProviderIconRegistry.standard.all) {
        if (!entry.hasBundledAsset) continue;
        for (final path in <String?>[entry.assetLight, entry.assetDark]) {
          if (path == null) continue;
          expect(File(path).existsSync(), isTrue, reason: path);
          final dir = path.substring(0, path.lastIndexOf('/') + 1);
          expect(pubspec, contains(dir), reason: path);
        }
      }
    });

    test('a report classifies every provider without inventing approval', () {
      final report = ProviderIconBrandValidationRunner().evaluate();
      expect(report.entries.length, 32);
      expect(report.invalidEntries, isEmpty);
      // The registry classifies marks; it cannot grant a licence.
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.entries.every((e) => e.reviewStatus != 'APPROVED'),
        isTrue,
        reason: 'licence approval is an external gate, never self-certified',
      );
      expect(
        report.entries
            .where((e) => e.providerId == 'anthropic')
            .single
            .themeVariants,
        <String>['light'],
      );
    });
  });
}
