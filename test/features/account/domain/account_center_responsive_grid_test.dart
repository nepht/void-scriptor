/// 115.6 — Responsive Grid System.
///
/// Dua lapis verifikasi:
/// 1. kontrak grid dipasak ke acceptance kanonik `sprint_115.json` step 115.6
///    (enam viewport) dan ke `spec.layout.breakpoints` product spec
///    (behavior + bounds, SHA-256 sumber sama dengan 115.5);
/// 2. snapshot manifest `sprint_115_responsive_grid_system.json` == domain,
///    plus provenance SHA-256 yang di-hash ulang bila file ada di mesin ini.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';

void main() {
  group('115.6 acceptance viewports', () {
    test('reference viewport and the six canonical acceptance names', () {
      expect(AccountCenterResponsiveGrid.referenceViewport.width, 1536);
      expect(AccountCenterResponsiveGrid.referenceViewport.height, 1024);
      expect(AccountCenterResponsiveGrid.acceptanceViewports, <String>[
        '1536x1024_reference',
        '1440_plus',
        '1180_to_1439',
        '900_to_1179',
        '600_to_899',
        'under_600',
      ]);
    });

    test('acceptance names match the canonical sprint step 115.6', () {
      final canonical = File(AccountCenterResponsiveGrid.canonicalSprintPath);
      if (!canonical.existsSync()) {
        // Sumber kanonik ada di mesin pengembangan; di checkout lain
        // manifest snapshot tetap jadi otoritas.
        return;
      }
      expect(
        sha256.convert(canonical.readAsBytesSync()).toString(),
        AccountCenterResponsiveGrid.canonicalSprintSha256,
        reason: 'sprint_115.json berubah — perbarui kontrak 115.6 sadar',
      );
      final sprint =
          jsonDecode(canonical.readAsStringSync()) as Map<String, dynamic>;
      final steps = sprint['steps'] as List<dynamic>;
      final step =
          steps.firstWhere(
                (item) => (item as Map<String, dynamic>)['id'] == '115.6',
                orElse: () =>
                    throw StateError('step 115.6 hilang dari sprint_115.json'),
              )
              as Map<String, dynamic>;
      expect(step['title'], 'Responsive Grid System');
      expect(
        step['acceptance'],
        AccountCenterResponsiveGrid.acceptanceViewports,
      );
    });

    test('integer boundaries resolve to the bracket that contains them', () {
      AccountCenterLayoutTier tierOf(double width) =>
          AccountCenterResponsiveGrid.resolve(width).tier;

      expect(tierOf(1536), AccountCenterLayoutTier.wideDesktop);
      expect(tierOf(1440), AccountCenterLayoutTier.wideDesktop);
      expect(tierOf(1920), AccountCenterLayoutTier.wideDesktop);
      expect(tierOf(1439), AccountCenterLayoutTier.desktop);
      expect(tierOf(1180), AccountCenterLayoutTier.desktop);
      expect(tierOf(1179), AccountCenterLayoutTier.compactDesktop);
      expect(tierOf(900), AccountCenterLayoutTier.compactDesktop);
      expect(tierOf(899), AccountCenterLayoutTier.tablet);
      expect(tierOf(600), AccountCenterLayoutTier.tablet);
      expect(tierOf(599), AccountCenterLayoutTier.mobile);
      expect(tierOf(390), AccountCenterLayoutTier.mobile);
      expect(tierOf(0), AccountCenterLayoutTier.mobile);
    });

    test('fractional widths settle into the bracket below the next step', () {
      AccountCenterLayoutTier tierOf(double width) =>
          AccountCenterResponsiveGrid.resolve(width).tier;

      expect(tierOf(1439.5), AccountCenterLayoutTier.desktop);
      expect(tierOf(1179.9), AccountCenterLayoutTier.compactDesktop);
      expect(tierOf(899.5), AccountCenterLayoutTier.tablet);
      expect(tierOf(599.9), AccountCenterLayoutTier.mobile);
    });

    test('non-finite or negative viewport fails closed', () {
      expect(
        () => AccountCenterResponsiveGrid.resolve(double.infinity),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterResponsiveGrid.resolve(-1),
        throwsArgumentError,
      );
    });
  });

  group('115.6 grid plan per tier', () {
    test('breakpoint names and bounds mirror the spec token breakpoints', () {
      final tokens = AccountCenterDesignTokens.layout.breakpoints;
      expect(tokens.map((item) => item.name), <String>[
        'wide_desktop',
        'desktop',
        'compact_desktop',
        'tablet',
        'mobile',
      ]);
      for (final tier in AccountCenterLayoutTier.values) {
        final plan = AccountCenterResponsiveGrid.planFor(tier);
        final token = tokens[tier.index];
        expect(plan.breakpointName, token.name, reason: '$tier');
        expect(plan.minWidth, token.minWidth, reason: '$tier');
        expect(plan.maxWidth, token.maxWidth, reason: '$tier');
      }
    });

    test('spec behavior strings are transcribed verbatim per tier', () {
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.wideDesktop,
        ).specBehavior,
        'left navigation + main content + persistent right summary',
      );
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.desktop,
        ).specBehavior,
        'left navigation + main content; right summary becomes drawer',
      );
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.compactDesktop,
        ).specBehavior,
        'collapsed navigation rail; overview cards use two columns',
      );
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.tablet,
        ).specBehavior,
        'top navigation; tabs scroll; cards use one or two columns',
      );
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.mobile,
        ).specBehavior,
        'single column; provider details open as full-screen sheet; '
        'charts provide text alternative',
      );
    });

    test('column caps follow the spec column rules', () {
      int columnsOf(AccountCenterLayoutTier tier) =>
          AccountCenterResponsiveGrid.planFor(tier).columnsFor(4000);

      expect(columnsOf(AccountCenterLayoutTier.wideDesktop), 3);
      expect(columnsOf(AccountCenterLayoutTier.desktop), 3);
      expect(columnsOf(AccountCenterLayoutTier.compactDesktop), 2);
      expect(columnsOf(AccountCenterLayoutTier.tablet), 2);
      expect(columnsOf(AccountCenterLayoutTier.mobile), 1);
    });

    test('fit rule never squeezes a card below card.minWidth at any width', () {
      const minCard = 220.0; // AccountCenterDesignTokens.card.minWidth
      for (var width = 120.0; width <= 2560; width += 4) {
        final plan = AccountCenterResponsiveGrid.resolve(width);
        final columns = plan.columnsFor(width);
        final cardWidth = plan.cardWidthFor(width);
        expect(
          columns == 1 || cardWidth >= minCard,
          isTrue,
          reason:
              'width=$width tier=${plan.tier} columns=$columns '
              'cardWidth=$cardWidth',
        );
        expect(columns, lessThanOrEqualTo(plan.maxColumns));
        expect(columns, greaterThanOrEqualTo(1));
      }
    });

    test('each in-range acceptance bracket renders its spec column count', () {
      const pagePadding = 16.0; // layout.pageHorizontalPadding * 2 terpakai
      double contentOf(double viewport) => viewport - pagePadding * 2;

      // Lebar konten tersedia (rail menumpuk atau tidak) minimal sebesar
      // ini pada tiap batas bawah bracket — grid harus muat tanpa overflow.
      expect(
        AccountCenterResponsiveGrid.resolve(1536).columnsFor(contentOf(1536)),
        3,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(1440).columnsFor(contentOf(1440)),
        3,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(1180).columnsFor(contentOf(1180)),
        3,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(900).columnsFor(contentOf(900)),
        2,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(600).columnsFor(contentOf(600)),
        2,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(390).columnsFor(contentOf(390)),
        1,
      );
    });

    test('right summary sits beside the main grid only on wide desktop', () {
      expect(
        AccountCenterResponsiveGrid.resolve(1536).summaryIsSideBySide,
        isTrue,
      );
      expect(
        AccountCenterResponsiveGrid.resolve(1440).summaryIsSideBySide,
        isTrue,
      );
      for (final width in [1439.0, 1180.0, 900.0, 600.0, 390.0]) {
        expect(
          AccountCenterResponsiveGrid.resolve(width).summaryIsSideBySide,
          isFalse,
          reason: 'width=$width',
        );
      }
    });
  });

  group('115.6 manifest provenance', () {
    test('manifest binds step 115.6 to canonical sprint and spec snapshot', () {
      final manifest = _readManifest();
      expect(manifest['canonical_step'], '115.6');
      expect(manifest['document_role'], 'SPRINT_115_RESPONSIVE_GRID_MANIFEST');
      expect(manifest['title'], 'Responsive Grid System');
      expect(
        manifest['acceptance_viewports'],
        AccountCenterResponsiveGrid.acceptanceViewports,
      );
      expect(manifest['domain'], AccountCenterResponsiveGrid.domainPath);
      expect(manifest['tests'], AccountCenterResponsiveGrid.testPaths);
      final sources = _asObject(manifest['sources']);
      final spec = _asObject(sources['product_spec']);
      expect(spec['sha256'], AccountCenterResponsiveGrid.specSha256);
      expect(spec['path'], AccountCenterResponsiveGrid.specDocument);
      final canonical = _asObject(sources['canonical_steps']);
      expect(
        canonical['sha256'],
        AccountCenterResponsiveGrid.canonicalSprintSha256,
      );
      expect(
        canonical['path'],
        AccountCenterResponsiveGrid.canonicalSprintPath,
      );
      final reference = _asObject(manifest['reference_viewport']);
      expect(_num(reference['width_px']), 1536);
      expect(_num(reference['height_px']), 1024);
    });

    test('manifest grid_plan snapshot equals the domain plans', () {
      final plan = _readManifest()['grid_plan'] as List<dynamic>;
      expect(plan, hasLength(AccountCenterLayoutTier.values.length));
      for (final tier in AccountCenterLayoutTier.values) {
        final record = _asObject(plan[tier.index]);
        final domain = AccountCenterResponsiveGrid.planFor(tier);
        expect(record['tier'], domain.breakpointName);
        expect(_num(record['max_columns']), domain.maxColumns.toDouble());
        expect(
          record['summary'],
          domain.summaryIsSideBySide ? 'side' : 'stacked',
        );
        expect(record['behavior'], domain.specBehavior);
        expect(_numOrNull(record['min_width_px']), domain.minWidth);
        expect(
          record['max_width_px'] == null ? null : _num(record['max_width_px']),
          domain.maxWidth,
        );
      }
      final fit = _asObject(_readManifest()['fit_rule']);
      expect(
        _num(fit['min_card_width_px']),
        AccountCenterDesignTokens.card.minWidth,
      );
      expect(
        _num(fit['card_gap_px']),
        AccountCenterDesignTokens.layout.cardGap,
      );
    });

    test('live spec file hashes to the recorded source when present', () {
      final specFile = File(AccountCenterResponsiveGrid.specDocument);
      if (!specFile.existsSync()) {
        return;
      }
      final digest = sha256.convert(specFile.readAsBytesSync()).toString();
      expect(digest, AccountCenterResponsiveGrid.specSha256);
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final layout = _asObject(spec['layout']);
      final breakpoints = (layout['breakpoints'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(breakpoints, hasLength(AccountCenterLayoutTier.values.length));
      for (final tier in AccountCenterLayoutTier.values) {
        final record = breakpoints[tier.index];
        final domain = AccountCenterResponsiveGrid.planFor(tier);
        expect(record['name'], domain.breakpointName);
        expect(record['behavior'], domain.specBehavior);
        expect(_numOrNull(record['min_width_px']), domain.minWidth);
        expect(_numOrNull(record['max_width_px']), domain.maxWidth);
      }
    });
  });
}

Map<String, dynamic> _readManifest() {
  final manifestFile = File(AccountCenterResponsiveGrid.manifestPath);
  expect(
    manifestFile.existsSync(),
    isTrue,
    reason: '115.6 responsive grid manifest must exist',
  );
  return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _asObject(Object? value) {
  expect(value, isA<Map<String, dynamic>>(), reason: '$value');
  return value as Map<String, dynamic>;
}

double _num(Object? value) {
  expect(value, isA<num>(), reason: '$value');
  return (value as num).toDouble();
}

double? _numOrNull(Object? value) => value == null ? null : _num(value);
