import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';

/// 115.5 — Account Center Design Tokens.
///
/// Dua lapis verifikasi:
/// 1. nilai domain dipasak ke angka product spec (transkripsi eksplisit);
/// 2. snapshot manifest di repo == domain, plus provenance SHA-256 sumber
///    (file spec di-hash ulang bila path ada di mesin ini).
void main() {
  group('115.5 design tokens — layout', () {
    test('reference desktop sizes match the product spec', () {
      const layout = AccountCenterDesignTokens.layout;
      expect(layout.viewportMinWidth, 1440);
      expect(layout.topBarHeight, 56);
      expect(layout.leftNavigationWidth, 192);
      expect(layout.rightSummaryWidth, 272);
      expect(layout.bottomStatusHeight, 40);
      expect(layout.pageHorizontalPadding, 16);
      expect(layout.pageVerticalPadding, 12);
      expect(layout.columnGap, 12);
      expect(layout.cardGap, 10);
      expect(layout.centerContentMinWidth, 900);
      expect(layout.headerHeight, 76);
      expect(layout.tabBarHeight, 40);
    });

    test('breakpoints keep spec order, bounds, and nullable mobile min', () {
      final breakpoints = AccountCenterDesignTokens.layout.breakpoints;
      expect(breakpoints.map((item) => item.name), <String>[
        'wide_desktop',
        'desktop',
        'compact_desktop',
        'tablet',
        'mobile',
      ]);
      expect(breakpoints[0].minWidth, 1440);
      expect(breakpoints[0].maxWidth, isNull);
      expect(breakpoints[1].minWidth, 1180);
      expect(breakpoints[1].maxWidth, 1439);
      expect(breakpoints[2].minWidth, 900);
      expect(breakpoints[2].maxWidth, 1179);
      expect(breakpoints[3].minWidth, 600);
      expect(breakpoints[3].maxWidth, 899);
      expect(breakpoints[4].minWidth, isNull);
      expect(breakpoints[4].maxWidth, 599);
    });
  });

  group('115.5 design tokens — spacing, radius, typography', () {
    test('spacing scale is the exact seven-step spec scale', () {
      const spacing = AccountCenterDesignTokens.spacing;
      expect(spacing.twoXs, 4);
      expect(spacing.xs, 6);
      expect(spacing.sm, 8);
      expect(spacing.md, 12);
      expect(spacing.lg, 16);
      expect(spacing.xl, 24);
      expect(spacing.twoXl, 32);
    });

    test('radius roles match control/tile/card/dialog/pill', () {
      const radius = AccountCenterDesignTokens.radius;
      expect(radius.control, 6);
      expect(radius.tile, 8);
      expect(radius.card, 10);
      expect(radius.dialog, 12);
      expect(radius.pill, 999);
    });

    test('typography roles match page/section/body/caption/metric', () {
      const typography = AccountCenterDesignTokens.typography;
      expect(typography.pageTitle, 20);
      expect(typography.sectionTitle, 12);
      expect(typography.body, 13);
      expect(typography.caption, 11);
      expect(typography.metric, 18);
    });
  });

  group('115.5 design tokens — icon, avatar, progress, density', () {
    test('icon sizes cover nav/action/section/page plus tile/row/dot', () {
      const icons = AccountCenterDesignTokens.iconSizes;
      expect(icons.navigation, 20);
      expect(icons.action, 20);
      expect(icons.section, 24);
      expect(icons.page, 36);
      expect(icons.providerTile, 28);
      expect(icons.serviceRow, 24);
      expect(icons.statusDot, 8);
    });

    test('avatar sizes match image/ring/compact', () {
      const avatar = AccountCenterDesignTokens.avatarSizes;
      expect(avatar.image, 80);
      expect(avatar.ring, 96);
      expect(avatar.compact, 40);
    });

    test('progress bar height is the spec value', () {
      expect(AccountCenterDesignTokens.progressBar.height, 8);
    });

    test('density keeps default, supported set, and target sizes', () {
      const density = AccountCenterDesignTokens.density;
      expect(density.defaultDensity, 'COMFORTABLE');
      expect(density.supported, <String>['COMPACT', 'COMFORTABLE', 'SPACIOUS']);
      expect(density.minimumTouchTarget, 44);
      expect(density.minimumKeyboardTarget, 32);
    });

    test('supporting card/provider-tile/service-row sizes match spec', () {
      const card = AccountCenterDesignTokens.card;
      expect(card.minWidth, 220);
      expect(card.padding, 14);
      const tile = AccountCenterDesignTokens.providerTile;
      expect(tile.minHeight, 56);
      expect(tile.paddingX, 12);
      expect(tile.paddingY, 10);
      expect(tile.iconSize, 28);
      expect(tile.statusDot, 8);
      const row = AccountCenterDesignTokens.serviceRow;
      expect(row.minHeight, 44);
      expect(row.iconSize, 24);
      expect(row.gap, 10);
    });
  });

  group('115.5 design tokens — manifest provenance', () {
    test('manifest binds step 115.5 to the canonical spec snapshot', () {
      final manifest = _readManifest();
      expect(manifest['canonical_step'], '115.5');
      expect(manifest['document_role'], 'SPRINT_115_DESIGN_TOKENS_MANIFEST');
      expect(
        manifest['required_tokens'],
        AccountCenterDesignTokens.requiredTokenGroups,
      );
      expect(manifest['required_tokens'], <String>[
        'layout',
        'spacing',
        'radius',
        'typography',
        'icon_sizes',
        'avatar_sizes',
        'progress_bar',
        'density',
      ]);
      expect(
        manifest['domain'],
        'lib/features/account/domain/account_center_design_tokens.dart',
      );
      final sources = _asObject(manifest['sources']);
      final spec = _asObject(sources['product_spec']);
      expect(spec['sha256'], AccountCenterDesignTokens.specSha256);
      expect(spec['path'], AccountCenterDesignTokens.specDocument);
      final canonical = _asObject(sources['canonical_steps']);
      expect(
        canonical['sha256'],
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('manifest token snapshot equals the domain values', () {
      final tokens = _asObject(_readManifest()['tokens']);

      final layout = _asObject(tokens['layout']);
      final reference = _asObject(layout['reference_desktop']);
      const domainLayout = AccountCenterDesignTokens.layout;
      expect(
        _num(reference['viewport_min_width_px']),
        domainLayout.viewportMinWidth,
      );
      expect(_num(reference['top_bar_height_px']), domainLayout.topBarHeight);
      expect(
        _num(reference['left_navigation_width_px']),
        domainLayout.leftNavigationWidth,
      );
      expect(
        _num(reference['right_summary_width_px']),
        domainLayout.rightSummaryWidth,
      );
      expect(
        _num(reference['bottom_status_height_px']),
        domainLayout.bottomStatusHeight,
      );
      expect(
        _num(reference['page_horizontal_padding_px']),
        domainLayout.pageHorizontalPadding,
      );
      expect(
        _num(reference['page_vertical_padding_px']),
        domainLayout.pageVerticalPadding,
      );
      expect(_num(reference['column_gap_px']), domainLayout.columnGap);
      expect(_num(reference['card_gap_px']), domainLayout.cardGap);
      expect(
        _num(reference['center_content_min_width_px']),
        domainLayout.centerContentMinWidth,
      );
      expect(_num(reference['header_height_px']), domainLayout.headerHeight);
      expect(_num(reference['tab_bar_height_px']), domainLayout.tabBarHeight);
      final breakpoints = (layout['breakpoints'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(breakpoints.length, domainLayout.breakpoints.length);
      for (var index = 0; index < breakpoints.length; index++) {
        final manifestBreakpoint = breakpoints[index];
        final domainBreakpoint = domainLayout.breakpoints[index];
        expect(manifestBreakpoint['name'], domainBreakpoint.name);
        expect(
          manifestBreakpoint['min_width_px'] == null
              ? null
              : _num(manifestBreakpoint['min_width_px']),
          domainBreakpoint.minWidth,
        );
        expect(
          manifestBreakpoint['max_width_px'] == null
              ? null
              : _num(manifestBreakpoint['max_width_px']),
          domainBreakpoint.maxWidth,
        );
      }

      final spacing = _asObject(tokens['spacing']);
      const domainSpacing = AccountCenterDesignTokens.spacing;
      expect(_num(spacing['2xs']), domainSpacing.twoXs);
      expect(_num(spacing['xs']), domainSpacing.xs);
      expect(_num(spacing['sm']), domainSpacing.sm);
      expect(_num(spacing['md']), domainSpacing.md);
      expect(_num(spacing['lg']), domainSpacing.lg);
      expect(_num(spacing['xl']), domainSpacing.xl);
      expect(_num(spacing['2xl']), domainSpacing.twoXl);

      final radius = _asObject(tokens['radius']);
      const domainRadius = AccountCenterDesignTokens.radius;
      expect(_num(radius['control']), domainRadius.control);
      expect(_num(radius['tile']), domainRadius.tile);
      expect(_num(radius['card']), domainRadius.card);
      expect(_num(radius['dialog']), domainRadius.dialog);
      expect(_num(radius['pill']), domainRadius.pill);

      final typography = _asObject(tokens['typography']);
      const domainTypography = AccountCenterDesignTokens.typography;
      expect(_num(typography['page_title']), domainTypography.pageTitle);
      expect(_num(typography['section_title']), domainTypography.sectionTitle);
      expect(_num(typography['body']), domainTypography.body);
      expect(_num(typography['caption']), domainTypography.caption);
      expect(_num(typography['metric']), domainTypography.metric);

      final iconSizes = _asObject(tokens['icon_sizes']);
      const domainIcons = AccountCenterDesignTokens.iconSizes;
      expect(_num(iconSizes['navigation']), domainIcons.navigation);
      expect(_num(iconSizes['action']), domainIcons.action);
      expect(_num(iconSizes['section']), domainIcons.section);
      expect(_num(iconSizes['page']), domainIcons.page);
      expect(_num(iconSizes['provider_tile']), domainIcons.providerTile);
      expect(_num(iconSizes['service_row']), domainIcons.serviceRow);
      expect(_num(iconSizes['status_dot']), domainIcons.statusDot);

      final avatar = _asObject(tokens['avatar_sizes']);
      const domainAvatar = AccountCenterDesignTokens.avatarSizes;
      expect(_num(avatar['image']), domainAvatar.image);
      expect(_num(avatar['ring']), domainAvatar.ring);
      expect(_num(avatar['compact']), domainAvatar.compact);

      final progress = _asObject(tokens['progress_bar']);
      expect(
        _num(progress['height_px']),
        AccountCenterDesignTokens.progressBar.height,
      );

      final density = _asObject(tokens['density']);
      const domainDensity = AccountCenterDesignTokens.density;
      expect(density['default'], domainDensity.defaultDensity);
      expect(density['supported'], domainDensity.supported);
      expect(
        _num(density['minimum_touch_target_px']),
        domainDensity.minimumTouchTarget,
      );
      expect(
        _num(density['minimum_keyboard_target_px']),
        domainDensity.minimumKeyboardTarget,
      );

      final supporting = _asObject(tokens['supporting']);
      final supportingCard = _asObject(supporting['card']);
      expect(
        _num(supportingCard['minimum_width_px']),
        AccountCenterDesignTokens.card.minWidth,
      );
      expect(
        _num(supportingCard['padding_px']),
        AccountCenterDesignTokens.card.padding,
      );
      final serviceRow = _asObject(supporting['service_row']);
      expect(
        _num(serviceRow['min_height_px']),
        AccountCenterDesignTokens.serviceRow.minHeight,
      );
      expect(
        _num(serviceRow['icon_size_px']),
        AccountCenterDesignTokens.serviceRow.iconSize,
      );
      expect(
        _num(serviceRow['gap_px']),
        AccountCenterDesignTokens.serviceRow.gap,
      );
    });

    test('application map records live and token-only targets', () {
      final application = _asObject(_readManifest()['application']);
      final live = (application['live_targets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final tokenOnly =
          (application['token_only_no_live_widget'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(live, isNotEmpty);
      expect(tokenOnly, isNotEmpty);
      expect(
        live.map((item) => item['group']).toSet(),
        containsAll(<String>[
          'layout',
          'spacing',
          'radius',
          'typography',
          'icon_sizes',
          'avatar_sizes',
          'density',
        ]),
      );
      expect(
        tokenOnly.map((item) => item['group']).toSet(),
        contains('progress_bar'),
      );
      expect(application['live_targets'], isList);
      expect(application['token_only_no_live_widget'], isList);
    });

    test('live spec file hashes to the recorded source when present', () {
      final specFile = File(AccountCenterDesignTokens.specDocument);
      if (!specFile.existsSync()) {
        // Sumber canonical ada di mesin pengembangan; di checkout lain
        // snapshot manifest + entry gate 115.1 tetap jadi otoritas.
        return;
      }
      final digest = sha256.convert(specFile.readAsBytesSync()).toString();
      expect(digest, AccountCenterDesignTokens.specSha256);
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final visualTokens = _asObject(spec['visual_tokens']);
      final spacing = _asObject(visualTokens['spacing_px']);
      expect(_num(spacing['2xs']), AccountCenterDesignTokens.spacing.twoXs);
      expect(_num(spacing['2xl']), AccountCenterDesignTokens.spacing.twoXl);
      final typography = _asObject(visualTokens['typography_px']);
      expect(
        _num(typography['page_title']),
        AccountCenterDesignTokens.typography.pageTitle,
      );
      expect(
        _num(typography['metric']),
        AccountCenterDesignTokens.typography.metric,
      );
      // progress_bar_height_px adalah angka tunggal di spec.
      expect(
        _num(visualTokens['progress_bar_height_px']),
        AccountCenterDesignTokens.progressBar.height,
      );
      final layout = _asObject(spec['layout']);
      final density = _asObject(layout['density']);
      expect(
        density['default'],
        AccountCenterDesignTokens.density.defaultDensity,
      );
      expect(
        _num(density['minimum_touch_target_px']),
        AccountCenterDesignTokens.density.minimumTouchTarget,
      );
      expect(
        _num(density['minimum_keyboard_target_px']),
        AccountCenterDesignTokens.density.minimumKeyboardTarget,
      );
    });
  });
}

Map<String, dynamic> _readManifest() {
  final manifestFile = File(AccountCenterDesignTokens.manifestPath);
  expect(
    manifestFile.existsSync(),
    isTrue,
    reason: '115.5 design tokens manifest must exist',
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
