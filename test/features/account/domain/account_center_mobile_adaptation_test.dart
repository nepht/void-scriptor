import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_mobile_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import '../../../canonical_source_support.dart';

/// 115.47 — Mobile Adaptation.
///
/// Acceptance kanonik step 115.47 di `sprint_115.json` (SHA-256
/// `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `single_column`, `provider_sheet`, `safe_actions`, `44px_targets`,
/// `text_alternatives`, `no_clipped_content`.
///
/// Lapis verifikasi mengikuti pola 115.5/115.6/115.45/115.46:
/// 1. geometri mobile dipin ke `behavior` product spec
///    (`account_cloud_center_spec.json` `layout.breakpoints[].behavior`);
/// 2. angka turunan (tinggi action bar, inset bawah) diturunkan dari token
///    115.5, bukan angka karangan;
/// 3. snapshot manifest di repo == domain, plus re-hash sumber bila file-nya
///    ada di mesin ini.
void main() {
  const manifestPath =
      'D:/VoidScriptor/void_scriptor_multiplatform/'
      '${AccountCenterMobileAdaptation.manifestPath}';

  AccountCenterMobileLayout at(
    double width, {
    double height = 844,
    double safeAreaBottom = 0,
  }) => AccountCenterMobileAdaptation.resolve(
    viewportWidth: width,
    viewportHeight: height,
    safeAreaBottom: safeAreaBottom,
  )!;

  group('115.47 single_column', () {
    test('mobile <600: satu kolom penuh, bukan grid tiga/dua kolom', () {
      final layout = at(390);
      expect(layout.tier, AccountCenterLayoutTier.mobile);
      expect(layout.breakpointName, 'mobile');
      expect(layout.columns, 1);
      expect(layout.singleColumn, isTrue);
      expect(layout.maxColumns, 1);
      // Kartu memakai seluruh lebar konten — tidak ada kolom kedua yang
      // membuat separuh lebar terbuang.
      expect(
        layout.cardWidth,
        layout.contentWidth,
        reason: 'satu kolom = kartu selebar konten',
      );
      expect(layout.contentWidth, 356);
    });

    test(
      'content width = viewport - 2 * page padding, tanpa band navigasi',
      () {
        for (final width in <double>[320, 360, 390, 414, 480, 599]) {
          final layout = at(width);
          expect(
            layout.contentWidth,
            width - 2 * AccountCenterDesignTokens.layout.pageHorizontalPadding,
            reason: 'lebar konten pada ${width}px',
          );
          expect(layout.contentWidth, greaterThan(0));
          // Tier mobile tidak punya band navigasi sama sekali (berbeda dengan
          // 115.46 yang menyisakan lebar rail/collapsed nav).
          expect(layout.navigationWidth, 0);
        }
      },
    );

    test('hanya tier mobile yang memakai kontrak 115.47', () {
      expect(AccountCenterMobileAdaptation.appliesAt(599.9), isTrue);
      expect(AccountCenterMobileAdaptation.appliesAt(600), isFalse);
      expect(AccountCenterMobileAdaptation.appliesAt(390), isTrue);
      // 600-1439 milik 115.46; >=1440 milik frame 115.45.
      expect(
        AccountCenterMobileAdaptation.resolve(
          viewportWidth: 600,
          viewportHeight: 900,
        ),
        isNull,
      );
      expect(
        AccountCenterMobileAdaptation.resolve(
          viewportWidth: 1180,
          viewportHeight: 900,
        ),
        isNull,
      );
      expect(
        AccountCenterMobileAdaptation.resolve(
          viewportWidth: 1536,
          viewportHeight: 1024,
        ),
        isNull,
      );
    });

    test('viewport tidak valid ditolak fail-closed', () {
      expect(
        () => AccountCenterMobileAdaptation.resolve(
          viewportWidth: double.nan,
          viewportHeight: 844,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterMobileAdaptation.resolve(
          viewportWidth: 0,
          viewportHeight: 844,
        ),
        throwsArgumentError,
        reason: 'lebar nol tidak menghasilkan konten',
      );
      expect(
        () => AccountCenterMobileAdaptation.resolve(
          viewportWidth: 390,
          viewportHeight: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterMobileAdaptation.resolve(
          viewportWidth: 390,
          viewportHeight: 844,
          safeAreaBottom: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('115.47 provider_sheet', () {
    test('detail provider membuka sebagai sheet layar penuh', () {
      for (final size in <({double height, double width})>[
        (width: 320, height: 568),
        (width: 390, height: 844),
        (width: 599, height: 900),
      ]) {
        final layout = at(size.width, height: size.height);
        expect(
          layout.providerDetails,
          AccountCenterProviderDetailsPresentation.fullScreenSheet,
          reason:
              'spec: provider details open as full-screen sheet '
              '(${size.width}px)',
        );
        expect(
          layout.providerSheetWidth,
          layout.viewportWidth,
          reason: 'sheet harus selebar viewport penuh pada ${size.width}px',
        );
        expect(
          layout.providerSheetHeight,
          layout.viewportHeight,
          reason: 'sheet harus setinggi viewport penuh pada ${size.width}px',
        );
        expect(layout.providerSheetIsFullScreen, isTrue);
      }
    });

    test('sheet tidak pernah lebih kecil dari viewport', () {
      // Sheet partial (tinggi < viewport) akan memotong baris detail terakhir
      // pada 115.48; kontrak menutupnya di sini.
      for (final width in <double>[320, 390, 480, 599]) {
        final layout = at(width);
        expect(
          layout.providerSheetHeight,
          greaterThanOrEqualTo(layout.viewportHeight),
        );
        expect(
          layout.providerSheetWidth,
          greaterThanOrEqualTo(layout.contentWidth),
        );
      }
    });
  });

  group('115.47 safe_actions', () {
    test('action bar menempel di bawah dan menghormati safe area OS', () {
      final layout = at(390, height: 844, safeAreaBottom: 34);
      expect(layout.actionBarHeight, 52);
      expect(layout.actionBarTotalHeight, 86);
      // Inset konten = bar + ruang aman, jadi kartu terakhir tidak tertutup.
      expect(layout.contentBottomInset, 86);
      expect(layout.reservesActionBarSpace, isTrue);
    });

    test('tinggi bar diturunkan dari token, bukan angka karangan', () {
      const density = AccountCenterDesignTokens.density;
      const spacing = AccountCenterDesignTokens.spacing;
      expect(
        AccountCenterMobileAdaptation.minimumActionTarget,
        density.minimumTouchTarget,
      );
      expect(
        AccountCenterMobileAdaptation.actionBarHeight,
        density.minimumTouchTarget + 2 * spacing.twoXs,
      );
      // Padding bar memakai spacing yang sama, jadi tinggi target di dalam bar
      // tepat sama dengan target sentuh minimum.
      expect(
        AccountCenterMobileAdaptation.actionBarHeight -
            2 * AccountCenterDesignTokens.spacing.twoXs,
        AccountCenterMobileAdaptation.minimumActionTarget,
      );
    });

    test('viewport pendek tetap menyisakan tinggi konten positif', () {
      for (final size in <({double height, double width})>[
        (width: 320, height: 568),
        (width: 360, height: 640),
        (width: 390, height: 844),
        (width: 599, height: 900),
      ]) {
        for (final safeArea in <double>[0, 34]) {
          final layout = at(
            size.width,
            height: size.height,
            safeAreaBottom: safeArea,
          );
          expect(
            layout.contentAreaPositive,
            isTrue,
            reason:
                'tinggi konten habis pada ${size.width}x${size.height} '
                'safeArea $safeArea',
          );
          expect(layout.contentBottomInset, lessThan(size.height.toDouble()));
        }
      }
    });
  });

  group('115.47 44px_targets', () {
    test('target aksi mobile tidak pernah di bawah 44px', () {
      expect(AccountCenterMobileAdaptation.minimumActionTarget, 44);
      expect(at(390).actionTargetHeight, 44);
      expect(
        at(390).actionTargetHeight,
        AccountCenterDesignTokens.density.minimumTouchTarget,
      );
      expect(at(320).actionTargetHeight, 44);
      expect(at(599).actionTargetHeight, 44);
    });
  });

  group('115.47 text_alternatives', () {
    test('tier mobile mewajibkan alternatif teks chart yang terlihat', () {
      expect(at(390).chartsRequireVisibleTextAlternative, isTrue);
      expect(at(320).hasVisibleTextAlternative('1,540 tokens'), isTrue);
      expect(at(390).hasVisibleTextAlternative('   '), isFalse);
      expect(at(390).hasVisibleTextAlternative(null), isFalse);
    });

    test('alternatif kosong ditolak fail-closed', () {
      expect(
        () => AccountCenterMobileAdaptation.requireVisibleTextAlternative(''),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterMobileAdaptation.requireVisibleTextAlternative('  '),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterMobileAdaptation.requireVisibleTextAlternative(null),
        throwsArgumentError,
      );
      expect(
        AccountCenterMobileAdaptation.requireVisibleTextAlternative(
          '  4 KB indexed  ',
        ),
        '4 KB indexed',
      );
    });
  });

  group('115.47 no_clipped_content', () {
    test('konten hanya aman bila inset bawah dicadangkan penuh', () {
      final layout = at(390, height: 844, safeAreaBottom: 34);
      expect(layout.clipsContentAt(0), isTrue);
      expect(layout.clipsContentAt(layout.actionBarHeight), isTrue);
      expect(layout.clipsContentAt(layout.contentBottomInset), isFalse);
      expect(
        layout.clipsContentAt(layout.contentBottomInset + 8),
        isFalse,
        reason: 'cadangan lebih dari yang dibutuhkan tetap aman',
      );
    });

    test('tinggi konten dihitung dari viewport, bukan angka tetap', () {
      final layout = at(390, height: 844, safeAreaBottom: 0);
      expect(
        layout.contentHeight,
        844 -
            2 * AccountCenterDesignTokens.layout.pageVerticalPadding -
            layout.contentBottomInset,
      );
      expect(layout.contentHeight, 768);
    });
  });

  group('115.47 manifest', () {
    test('manifest repo cocok dengan domain dan provenance sumber', () {
      if (skipUnlessExternalCanonical(
        "manifest repo cocok dengan domain dan provenance sumber",
      )) {
        return;
      }
      final manifest =
          jsonDecode(File(manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.47');
      expect(
        (manifest['acceptance'] as Map).keys.toList(),
        AccountCenterMobileAdaptation.acceptanceKeys,
      );
      final sources = manifest['sources'] as Map<String, dynamic>;
      expect(
        sources['canonical_steps']['sha256'],
        AccountCenterMobileAdaptation.canonicalSprintSha256,
      );
      expect(
        sources['product_spec']['sha256'],
        AccountCenterMobileAdaptation.specSha256,
      );
      expect(manifest['domain'], AccountCenterMobileAdaptation.domainPath);
      expect(manifest['tests'], AccountCenterMobileAdaptation.testPaths);

      final range = manifest['viewport_range_px'] as Map<String, dynamic>;
      expect(range['min'], 0);
      expect(range['max_exclusive'], 600);

      final acceptance = manifest['acceptance'] as Map<String, dynamic>;
      final safeActions = acceptance['safe_actions'] as Map<String, dynamic>;
      expect(
        safeActions['action_bar_height_px'],
        AccountCenterMobileAdaptation.actionBarHeight,
      );
      expect(
        safeActions['action_target_height_px'],
        AccountCenterMobileAdaptation.minimumActionTarget,
      );
      final sheet = acceptance['provider_sheet'] as Map<String, dynamic>;
      expect(sheet['width_rule'], 'viewport_width');
      expect(sheet['height_rule'], 'viewport_height');

      final specFile = File(AccountCenterMobileAdaptation.specDocument);
      if (specFile.existsSync()) {
        expect(
          sha256.convert(specFile.readAsBytesSync()).toString(),
          AccountCenterMobileAdaptation.specSha256,
        );
      }
      final sprintFile = File(
        AccountCenterMobileAdaptation.canonicalSprintPath,
      );
      if (sprintFile.existsSync()) {
        expect(
          sha256.convert(sprintFile.readAsBytesSync()).toString(),
          AccountCenterMobileAdaptation.canonicalSprintSha256,
        );
      }
    });

    test('acceptance kanonik 115.47 di sprint_115.json sesuai kontrak', () {
      final file = File(AccountCenterMobileAdaptation.canonicalSprintPath);
      if (!file.existsSync()) {
        return;
      }
      final sprint =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = (sprint['steps'] as List).cast<Map<String, dynamic>>();
      final step = steps.firstWhere((entry) => entry['id'] == '115.47');
      expect(
        (step['acceptance'] as List),
        AccountCenterMobileAdaptation.acceptanceKeys,
      );
    });

    test('mode chrome tier mobile cocok behavior product spec', () {
      final specFile = File(AccountCenterMobileAdaptation.specDocument);
      if (!specFile.existsSync()) {
        return;
      }
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final behaviors = ((spec['layout'] as Map)['breakpoints'] as List)
          .cast<Map<String, dynamic>>();
      final mobile = behaviors.firstWhere((b) => b['name'] == 'mobile');
      expect(mobile['behavior'], contains('single column'));
      expect(mobile['behavior'], contains('full-screen sheet'));
      expect(mobile['behavior'], contains('text alternative'));
      expect(
        AccountCenterResponsiveGrid.planFor(
          AccountCenterLayoutTier.mobile,
        ).specBehavior,
        mobile['behavior'],
      );
      // Sheet hanya disebut di tier mobile: tier lain tidak boleh dikarang
      // memakai perilaku yang sama.
      for (final name in <String>[
        'wide_desktop',
        'desktop',
        'compact_desktop',
        'tablet',
      ]) {
        expect(
          behaviors.firstWhere((b) => b['name'] == name)['behavior'],
          isNot(contains('full-screen sheet')),
          reason: 'sheet layar penuh hanya perilaku tier mobile ($name)',
        );
      }
      // Target sentuh 44px berasal dari spec, bukan angka karangan.
      expect(
        AccountCenterDesignTokens.density.minimumTouchTarget,
        (((spec['layout'] as Map)['density'] as Map)['minimum_touch_target_px']
                as num)
            .toDouble(),
      );
    });
  });
}
