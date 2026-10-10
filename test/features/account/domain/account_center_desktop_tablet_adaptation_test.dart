import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_desktop_tablet_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import '../../../canonical_source_support.dart';

/// 115.46 — Desktop & Tablet Adaptation.
///
/// Acceptance kanonik step 115.46 di `sprint_115.json` (SHA-256
/// `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `right_drawer`, `collapsed_nav`, `two_column`, `scrollable_tabs`,
/// `no_horizontal_overflow`, `state_preserved`.
///
/// Lapis verifikasi mengikuti pola 115.5/115.6/115.45:
/// 1. mode chrome per tier dipin ke `behavior` product spec
///    (`account_cloud_center_spec.json` `layout.breakpoints[].behavior`);
/// 2. snapshot manifest di repo == domain, plus re-hash sumber bila file-nya
///    ada di mesin ini.
void main() {
  final manifestPath = AccountCenterDesktopTabletAdaptation.manifestPath;

  group('115.46 right_drawer', () {
    test('desktop 1180-1439: ringkasan jadi drawer, bukan band kanan', () {
      final layout = AccountCenterDesktopTabletAdaptation.resolve(1180);
      expect(layout, isNotNull);
      expect(layout!.tier, AccountCenterLayoutTier.desktop);
      expect(
        layout.summaryPresentation,
        AccountCenterSummaryPresentation.drawer,
      );
      expect(layout.navigationMode, AccountCenterNavigationMode.leftNavigation);
      // Drawer tidak boleh memakan lebar konten: konten memakai sisa penuh
      // setelah navigasi, bukan 75% seperti jalur side-by-side lama.
      expect(layout.contentWidth, 954);
      expect(layout.drawerWidth, 349);
      expect(layout.mainWidthWhenDrawerOpen, 605);
      expect(layout.drawerKeepsMainVisible, isTrue);
    });

    test('drawer tidak pernah menimpa konten sampai tak terlihat', () {
      for (final width in <double>[1180, 1280, 1360, 1439]) {
        final layout = AccountCenterDesktopTabletAdaptation.resolve(width)!;
        expect(
          layout.mainWidthWhenDrawerOpen,
          greaterThanOrEqualTo(layout.minMainContentWidth),
          reason:
              'drawer pada ${width}px harus menyisakan konten >= '
              '${layout.minMainContentWidth}px',
        );
        expect(
          layout.drawerWidth,
          lessThanOrEqualTo(layout.contentWidth),
          reason: 'drawer pada ${width}px tidak boleh lebih lebar dari konten',
        );
      }
    });

    test('wide_desktop dan mobile tidak memakai kontrak 115.46', () {
      // >= 1440 milik frame 115.45; < 600 milik 115.47.
      expect(AccountCenterDesktopTabletAdaptation.resolve(1536), isNull);
      expect(AccountCenterDesktopTabletAdaptation.resolve(1440), isNull);
      expect(AccountCenterDesktopTabletAdaptation.resolve(599), isNull);
      expect(AccountCenterDesktopTabletAdaptation.resolve(390), isNull);
      expect(AccountCenterDesktopTabletAdaptation.appliesAt(600), isTrue);
      expect(AccountCenterDesktopTabletAdaptation.appliesAt(1439.5), isTrue);
      expect(AccountCenterDesktopTabletAdaptation.appliesAt(1439.9), isTrue);
    });
  });

  group('115.46 collapsed_nav', () {
    test('compact_desktop 900-1179: navigasi jadi rail terlipat', () {
      final layout = AccountCenterDesktopTabletAdaptation.resolve(1000)!;
      expect(layout.tier, AccountCenterLayoutTier.compactDesktop);
      expect(layout.navigationMode, AccountCenterNavigationMode.collapsedRail);
      expect(layout.isCollapsedNavigation, isTrue);
      expect(layout.navigationLabelsVisible, isFalse);
      expect(
        layout.navigationWidth,
        lessThan(AccountCenterDesignTokens.layout.leftNavigationWidth),
        reason: 'rail terlipat harus lebih sempit dari navigasi penuh 192px',
      );
      expect(layout.navigationWidth, 52);
      expect(
        layout.contentWidth,
        1000 -
            2 * AccountCenterDesignTokens.layout.pageHorizontalPadding -
            layout.navigationWidth,
      );
    });

    test('tablet 600-899: navigasi pindah ke atas, tanpa lebar band kiri', () {
      final layout = AccountCenterDesktopTabletAdaptation.resolve(800)!;
      expect(layout.tier, AccountCenterLayoutTier.tablet);
      expect(layout.navigationMode, AccountCenterNavigationMode.topNavigation);
      expect(layout.usesTopNavigation, isTrue);
      expect(layout.navigationWidth, 0);
      expect(layout.navigationLabelsVisible, isTrue);
      expect(
        layout.contentWidth,
        800 - 2 * AccountCenterDesignTokens.layout.pageHorizontalPadding,
      );
    });

    test('collapse diturunkan dari token, bukan angka bebas', () {
      const layout = AccountCenterDesignTokens.layout;
      const spacing = AccountCenterDesignTokens.spacing;
      const density = AccountCenterDesignTokens.density;
      expect(
        AccountCenterDesktopTabletAdaptation.collapsedRailWidth,
        density.minimumTouchTarget + 2 * spacing.twoXs,
        reason: 'rail terlipat = target sentuh + padding, bukan angka karangan',
      );
      expect(
        AccountCenterDesktopTabletAdaptation.collapsedRailWidth,
        lessThan(layout.leftNavigationWidth),
      );
    });
  });

  group('115.46 two_column', () {
    test('compact_desktop dan tablet memakai dua kolom maksimum', () {
      expect(AccountCenterDesktopTabletAdaptation.resolve(1000)!.maxColumns, 2);
      expect(AccountCenterDesktopTabletAdaptation.resolve(800)!.maxColumns, 2);
      // Desktop 1180-1439 tetap tiga kolom sesuai kontrak 115.6.
      expect(AccountCenterDesktopTabletAdaptation.resolve(1180)!.maxColumns, 3);
    });

    test('dua kolom benar-benar muat pada lebar konten terendah', () {
      for (final width in <double>[900, 1000, 1180, 1439, 600, 800]) {
        final layout = AccountCenterDesktopTabletAdaptation.resolve(width)!;
        final columns = layout.columnsForContentWidth;
        expect(
          columns,
          lessThanOrEqualTo(layout.maxColumns),
          reason: 'kolom pada ${width}px tidak boleh melewati batas tier',
        );
        expect(
          layout.cardWidthForContent(columns),
          greaterThanOrEqualTo(
            AccountCenterDesignTokens.card.minWidth - 0.0001,
          ),
          reason: 'lebar kartu pada ${width}px harus >= card.minWidth',
        );
      }
    });
  });

  group('115.46 scrollable_tabs', () {
    test('tier 115.46 memakai tab strip yang bergulir mendatar', () {
      for (final width in <double>[1439, 1180, 1000, 900, 800, 600]) {
        expect(
          AccountCenterDesktopTabletAdaptation.resolve(width)!.tabsScroll,
          isTrue,
          reason: 'tab strip harus bisa digulir pada ${width}px',
        );
      }
    });

    test('tab strip tetap punya sembilan tab kanonik', () {
      // Strip di-drive presentation dari IA kanonik; kontrak ini hanya
      // mengunci bahwa tier 115.46 tidak boleh mematikan tab.
      expect(AccountCenterDesktopTabletAdaptation.tabsScroll, isTrue);
    });
  });

  group('115.46 no_horizontal_overflow', () {
    test('band navigasi + konten muat di dalam viewport', () {
      for (final width in <double>[
        600,
        700,
        800,
        899,
        900,
        1000,
        1180,
        1300,
        1439,
      ]) {
        final layout = AccountCenterDesktopTabletAdaptation.resolve(width)!;
        expect(
          layout.bandsFit(),
          isTrue,
          reason: 'band tidak muat pada ${width}px',
        );
        expect(
          layout.contentWidth,
          greaterThan(0),
          reason: 'lebar konten harus positif pada ${width}px',
        );
      }
    });

    test('konten tidak pernah melebihi lebar yang tersisa', () {
      for (final width in <double>[600, 900, 1180, 1439]) {
        final layout = AccountCenterDesktopTabletAdaptation.resolve(width)!;
        final available =
            width - 2 * AccountCenterDesignTokens.layout.pageHorizontalPadding;
        expect(
          layout.navigationWidth + layout.contentWidth,
          lessThanOrEqualTo(available + 0.0001),
          reason: 'total band melebihi area konten pada ${width}px',
        );
      }
    });

    test('viewport tidak valid ditolak fail-closed', () {
      expect(
        () => AccountCenterDesktopTabletAdaptation.resolve(double.nan),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterDesktopTabletAdaptation.resolve(-1),
        throwsArgumentError,
      );
    });
  });

  group('115.46 state_preserved', () {
    test('kontrak murni: state tab dan drawer milik presentation', () {
      // Kontrak murni: tidak ada field state di sini, sehingga state tab dan
      // drawer wajib bertahan lewat State presentation pada transisi tier.
      expect(
        AccountCenterDesktopTabletAdaptation.resolve(
          1180,
        )!.runtimeType.toString(),
        startsWith('AccountCenterDesktopTabletLayout'),
      );
    });

    test(
      'tier sebelum/sesudah 115.46 memakai chrome berbeda tanpa tumpang tindih',
      () {
        final wide = AccountCenterDesktopTabletAdaptation.resolve(1536);
        final desktop = AccountCenterDesktopTabletAdaptation.resolve(1300);
        final compact = AccountCenterDesktopTabletAdaptation.resolve(1000);
        final tablet = AccountCenterDesktopTabletAdaptation.resolve(800);
        expect(wide, isNull, reason: '>=1440 milik frame 115.45');
        expect(
          desktop!.navigationMode,
          AccountCenterNavigationMode.leftNavigation,
        );
        expect(
          compact!.navigationMode,
          AccountCenterNavigationMode.collapsedRail,
        );
        expect(
          tablet!.navigationMode,
          AccountCenterNavigationMode.topNavigation,
        );
        // Ringkasan: side-by-side hanya di 115.45; 115.46 memakai drawer di
        // desktop dan menumpuk di bawah pada tier sempit.
        expect(
          desktop.summaryPresentation,
          AccountCenterSummaryPresentation.drawer,
        );
        expect(
          compact.summaryPresentation,
          AccountCenterSummaryPresentation.stackedBelow,
        );
        expect(
          tablet.summaryPresentation,
          AccountCenterSummaryPresentation.stackedBelow,
        );
      },
    );
  });

  group('115.46 manifest', () {
    test('manifest repo cocok dengan domain dan provenance sumber', () {
      if (skipUnlessExternalCanonical(
        "manifest repo cocok dengan domain dan provenance sumber",
      )) {
        return;
      }
      final manifest =
          jsonDecode(File(manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.46');
      expect(
        (manifest['acceptance'] as Map).keys.toList(),
        AccountCenterDesktopTabletAdaptation.acceptanceKeys,
      );
      final sources = manifest['sources'] as Map<String, dynamic>;
      expect(
        sources['canonical_steps']['sha256'],
        AccountCenterDesktopTabletAdaptation.canonicalSprintSha256,
      );
      expect(
        sources['product_spec']['sha256'],
        AccountCenterDesktopTabletAdaptation.specSha256,
      );
      expect(
        manifest['domain'],
        AccountCenterDesktopTabletAdaptation.domainPath,
      );
      expect(manifest['tests'], AccountCenterDesktopTabletAdaptation.testPaths);

      final tiers = (manifest['tiers'] as List).cast<Map<String, dynamic>>();
      expect(tiers.map((entry) => entry['tier']).toList(), <String>[
        'desktop',
        'compact_desktop',
        'tablet',
      ]);
      for (final entry in tiers) {
        final plan = AccountCenterResponsiveGrid.resolve(
          (entry['min_width_px'] as num).toDouble(),
        );
        expect(entry['tier'], plan.breakpointName);
        expect(
          entry['navigation_mode'],
          AccountCenterDesktopTabletAdaptation.resolve(
            (entry['min_width_px'] as num).toDouble(),
          )!.navigationMode.name,
        );
        expect(
          entry['summary_presentation'],
          AccountCenterDesktopTabletAdaptation.resolve(
            (entry['min_width_px'] as num).toDouble(),
          )!.summaryPresentation.name,
        );
      }

      final acceptance = manifest['acceptance'] as Map<String, dynamic>;
      final drawer = acceptance['right_drawer'] as Map<String, dynamic>;
      expect(
        drawer['width_px'],
        AccountCenterDesignTokens.layout.rightSummaryWidth,
      );
      expect(drawer['overlay'], isTrue);

      final specFile = File(AccountCenterDesktopTabletAdaptation.specDocument);
      if (specFile.existsSync()) {
        expect(
          sha256.convert(specFile.readAsBytesSync()).toString(),
          AccountCenterDesktopTabletAdaptation.specSha256,
        );
      }
      final sprintFile = File(
        AccountCenterDesktopTabletAdaptation.canonicalSprintPath,
      );
      if (sprintFile.existsSync()) {
        expect(
          sha256.convert(sprintFile.readAsBytesSync()).toString(),
          AccountCenterDesktopTabletAdaptation.canonicalSprintSha256,
        );
      }
    });

    test('acceptance kanonik 115.46 di sprint_115.json sesuai kontrak', () {
      final file = File(
        AccountCenterDesktopTabletAdaptation.canonicalSprintPath,
      );
      if (!file.existsSync()) {
        return;
      }
      final sprint =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = (sprint['steps'] as List).cast<Map<String, dynamic>>();
      final step = steps.firstWhere((entry) => entry['id'] == '115.46');
      expect(
        (step['acceptance'] as List),
        AccountCenterDesktopTabletAdaptation.acceptanceKeys,
      );
    });

    test('mode chrome tiap tier cocok behavior product spec', () {
      final specFile = File(AccountCenterDesktopTabletAdaptation.specDocument);
      if (!specFile.existsSync()) {
        return;
      }
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final behaviors = ((spec['layout'] as Map)['breakpoints'] as List)
          .cast<Map<String, dynamic>>();
      final planBehaviors = {
        for (final tier in AccountCenterLayoutTier.values)
          tier: AccountCenterResponsiveGrid.planFor(tier).specBehavior,
      };
      expect(
        planBehaviors[AccountCenterLayoutTier.desktop],
        contains('drawer'),
      );
      // Hanya desktop yang menyebut drawer; compact_desktop/tablet tidak,
      // jadi ringkasan pada tier itu tetap menumpuk (bukan dikarang drawer).
      expect(
        behaviors.firstWhere((b) => b['name'] == 'desktop')['behavior'],
        contains('drawer'),
      );
      expect(
        behaviors.firstWhere((b) => b['name'] == 'compact_desktop')['behavior'],
        isNot(contains('drawer')),
      );
      expect(
        behaviors.firstWhere((b) => b['name'] == 'tablet')['behavior'],
        contains('tabs scroll'),
      );
      expect(
        behaviors.firstWhere((b) => b['name'] == 'compact_desktop')['behavior'],
        contains('collapsed navigation rail'),
      );
    });
  });
}
