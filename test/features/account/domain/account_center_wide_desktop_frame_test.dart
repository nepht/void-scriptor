import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_wide_desktop_frame.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import '../../../canonical_source_support.dart';

/// 115.45 — Wide Desktop Visual Implementation.
///
/// Dua lapis verifikasi, mengikuti pola 115.5/115.6:
/// 1. geometri frame dipasak ke angka mockup 1536x1024 yang sudah terukur
///    (transkripsi eksplisit di kontrak);
/// 2. snapshot manifest di repo == domain, plus provenance SHA-256 sumber
///    (file spec di-hash ulang bila path ada di mesin ini).
///
/// Enam acceptance kanonik dipetakan ke test:
/// `layout_dimensions` -> geometry; `no_overlap` -> bandsAreDisjoint;
/// `scroll_containment` -> heights clamp; `consistent_cards` -> cardWidthFor;
/// `right_rail` -> tier gating; `status_bar` -> statusBarItems.
void main() {
  const manifestPath =
      'D:/VoidScriptor/void_scriptor_multiplatform/'
      '${AccountCenterWideDesktopFrame.manifestPath}';

  group('115.45 layout_dimensions', () {
    test('frame reference 1536x1024 memakai angka mockup terukur', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      );
      expect(frame, isNotNull);
      expect(frame!.leftNavigationWidth, 192);
      expect(frame.rightRailWidth, 349);
      expect(frame.statusBarHeight, 40);
      expect(frame.pagePaddingHorizontal, 17);
      expect(frame.pagePaddingVertical, 12);
      // 1536 - 2*17 (padding) - 192 (nav) - 349 (rail) = 961? No: the
      // measured mockup grid band is x17..1170, i.e. the nav shares the
      // left padding band. The contract computes main as the remainder after
      // nav + rail, so assert the identity instead of a re-derived guess.
      expect(
        frame.mainWidth,
        1536 - 2 * frame.pagePaddingHorizontal - 192 - 349,
      );
      // 1024 - (40 status bar + 11 celah baris) - 2*12 padding = 949.
      expect(
        frame.gridHeight,
        1024 - 40 - AccountCenterWideDesktopFrame.rowGap - 2 * 12,
      );
      // Akun tinggi harus pas, tidak kurang dan tidak lebih.
      expect(
        2 * frame.pagePaddingVertical +
            frame.gridHeight +
            AccountCenterWideDesktopFrame.rowGap +
            frame.statusBarHeight,
        closeTo(1024, 0.0001),
      );
    });

    test('jumlah kartu dan bobot baris mengikuti mockup 3/5/5', () {
      expect(AccountCenterWideDesktopFrame.mockupRowColumns, <int>[3, 5, 5]);
      expect(AccountCenterWideDesktopFrame.rowCardCounts, <int>[3, 5, 5]);
      expect(AccountCenterWideDesktopFrame.rowWeights, <double>[351, 268, 265]);
      expect(AccountCenterWideDesktopFrame.rowGap, 11);
      // rowGap disalin ke konstanta supaya bisa dipakai dalam ekspresi const;
      // pemakuraan ini yang menjamin salinan itu tidak pernah menyimpang.
      expect(
        AccountCenterWideDesktopFrame.rowGap,
        AccountCenterDesignTokens.layout.cardGap,
      );
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      expect(frame.rowHeights.length, 3);
    });

    test('reference 1536: left navigation 192px membuat lima kolom tak muat, '
        'jadi kontrak melaporkan 3/4/4 — bukan memaksakan kolom mockup', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      // Band main = 1536 - 2*17 - 192 (nav) - 349 (rail) = 961px.
      expect(frame.mainWidth, 961);
      // Lima kartu pada 961px dengan gap 11 -> 183.4px < card.minWidth 220.
      expect(frame.rowColumns, <int>[3, 4, 4]);
      expect(
        frame.preservesMockupColumns,
        isFalse,
        reason:
            'kontrak harus jujur melaporkan mockup 3/5/5 tidak bisa '
            'dipakai setelah left navigation dibayar 192px',
      );
    });

    test('viewport cukup lebar mengembalikan mockup 3/5/5', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1920,
        height: 1200,
      )!;
      expect(frame.rowColumns, <int>[3, 5, 5]);
      expect(frame.preservesMockupColumns, isTrue);
    });

    test('minViewportWidthForColumns menandai ambang lima kolom', () {
      final threshold =
          AccountCenterWideDesktopFrame.minViewportWidthForColumns(5);
      // 5*220 (card.minWidth) + 4*11 (cardGap) + 2*17 (page padding)
      // + 349 (rail) + 192 (left nav) = 1719.
      expect(threshold, 1719);
      // Pada ambang itu band main tepat memuat lima kartu selebar 220px.
      final atThreshold = AccountCenterWideDesktopFrame.resolve(
        width: threshold,
        height: 1024,
      )!;
      expect(atThreshold.rowColumns, <int>[3, 5, 5]);
      expect(
        atThreshold.preservesMockupColumns,
        isTrue,
        reason: 'tepat di ambang, lima kolom harus sah',
      );
      expect(
        AccountCenterWideDesktopFrame.appliesAt(threshold - 1),
        isTrue,
        reason: 'tier wide_desktop masih berlaku di bawah ambang kolom',
      );
    });

    test('viewport di luar tier wide_desktop tidak dipaksa jadi frame', () {
      expect(AccountCenterWideDesktopFrame.appliesAt(1440), isTrue);
      // Sama seperti rowGap: konstanta salinan dipaku ke token aslinya.
      expect(
        AccountCenterWideDesktopFrame.wideDesktopMinWidth,
        AccountCenterDesignTokens.layout.viewportMinWidth,
      );
      expect(AccountCenterWideDesktopFrame.appliesAt(1439), isFalse);
      expect(
        AccountCenterWideDesktopFrame.resolve(width: 1180, height: 900),
        isNull,
        reason: '115.46/115.47 memiliki adaptasi sendiri di bawah 1440',
      );
      expect(
        AccountCenterWideDesktopFrame.resolve(width: 390, height: 844),
        isNull,
      );
    });

    test('viewport tak-hingga atau negatif fail-closed', () {
      expect(
        () => AccountCenterWideDesktopFrame.resolve(
          width: double.infinity,
          height: 1024,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterWideDesktopFrame.resolve(
          width: 1536,
          height: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterWideDesktopFrame.resolve(width: -1, height: 1024),
        throwsArgumentError,
      );
    });
  });

  group('115.45 no_overlap', () {
    test('band kiri/main/kanan dan status bar tidak saling menimpa', () {
      for (final size in const [
        (width: 1536.0, height: 1024.0),
        (width: 1440.0, height: 900.0),
        (width: 1920.0, height: 1200.0),
        (width: 2560.0, height: 1440.0),
      ]) {
        final frame = AccountCenterWideDesktopFrame.resolve(
          width: size.width,
          height: size.height,
        )!;
        expect(
          frame.bandsAreDisjoint(),
          isTrue,
          reason:
              'band overlap pada $size: '
              'nav=${frame.leftNavigationWidth} main=${frame.mainWidth} '
              'rail=${frame.rightRailWidth} grid=${frame.gridHeight} '
              'status=${frame.statusBarHeight}',
        );
      }
    });

    test('baris berjumlah tepat tinggi grid (tanpa ruang hilang)', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      final gaps =
          AccountCenterWideDesktopFrame.rowGap * (frame.rowHeights.length - 1);
      expect(frame.rowsTotal + gaps, closeTo(frame.gridHeight, 0.0001));
    });
  });

  group('115.45 scroll_containment', () {
    test('tinggi baris tidak pernah melampaui tinggi grid', () {
      for (final height in const [1024.0, 900.0, 768.0, 700.0, 600.0]) {
        final frame = AccountCenterWideDesktopFrame.resolve(
          width: 1536,
          height: height,
        )!;
        final gaps =
            AccountCenterWideDesktopFrame.rowGap *
            (frame.rowHeights.length - 1);
        expect(
          frame.rowsTotal + gaps,
          lessThanOrEqualTo(frame.gridHeight + 0.0001),
          reason: 'viewport $height: baris melampaui grid',
        );
        expect(frame.scrollableGridHeight, frame.gridHeight);
      }
    });

    test('viewport sangat pendek tidak menghasilkan baris negatif', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 120,
      )!;
      expect(frame.rowHeights.every((row) => row >= 0), isTrue);
      expect(frame.bandsAreDisjoint(), isTrue);
    });
  });

  group('115.45 consistent_cards', () {
    test('lebar kartu pada tiap kolom selalu positif dan pas di band main', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      for (final columns in frame.rowColumns) {
        final width = frame.cardWidthFor(columns);
        expect(width, greaterThan(0), reason: 'kolom $columns');
        final gap = AccountCenterDesignTokens.layout.cardGap;
        expect(
          columns * width + gap * (columns - 1),
          closeTo(frame.mainWidth, 0.0001),
          reason: 'N kartu + N-1 gap harus persis mengisi band main',
        );
      }
      // Kolom SETIAP baris hasil frame harus memenuhi minimum kartu token:
      // inilah yang membuat 3/4/4 pada 1536 sah dan 3/5/5 mustahil.
      for (final columns in frame.rowColumns) {
        expect(
          frame.cardWidthFor(columns),
          greaterThanOrEqualTo(AccountCenterDesignTokens.card.minWidth),
          reason: 'kolom $columns di bawah minimum kartu token',
        );
      }
      // Lima kolom hanya sah di viewport >= ambang yang dihitung kontrak.
      expect(
        frame.cardWidthFor(5),
        lessThan(AccountCenterDesignTokens.card.minWidth),
        reason: '1536 tidak boleh diklaim bisa lima kolom',
      );
    });

    test('kolom < 1 atau band tak-bermasalah fail-closed', () {
      final frame = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      expect(() => frame.cardWidthFor(0), throwsArgumentError);
      expect(
        () => AccountCenterWideDesktopFrame.resolve(
          width: 1440,
          height: 1024,
        )!.cardWidthFor(3),
        returnsNormally,
        reason: 'tier batas 1440 tetap punya band main positif',
      );
    });
  });

  group('115.45 right_rail', () {
    test('rail hanya berdampingan pada tier wide_desktop', () {
      expect(AccountCenterWideDesktopFrame.appliesAt(1536), isTrue);
      final wide = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      expect(wide.rightRailWidth, 349);
      // Tier di bawah 1440 tidak punya frame; rail jadi drawer (115.46).
      expect(AccountCenterWideDesktopFrame.appliesAt(1439), isFalse);
    });
  });

  group('115.45 status_bar', () {
    test('isi status bar diturunkan dari snapshot, tanpa nilai fabrikasi', () {
      final snapshot = AccountCloudSnapshot.localOnly(session: null);
      final items = AccountCenterWideDesktopFrame.statusBarItems(snapshot);
      expect(items.map((item) => item.label), <String>[
        'Mode',
        'Services',
        'Remote',
      ]);
      expect(items.first.value, snapshot.accountModeLabel);
      expect(
        items.any((item) => item.value.contains('Local data only')),
        isTrue,
        reason: 'tanpa connector remote, status harus jujur lokal',
      );
      // Koleksi immutable.
      expect(
        () =>
            items.add(const AccountCenterStatusBarItem(label: 'x', value: 'y')),
        throwsUnsupportedError,
      );
    });

    test('service terhubung dihitung dari state nyata, bukan asumsi', () {
      final snapshot = AccountCloudSnapshot(
        accountModeLabel: 'Connected account',
        accountDisplayName: 'Tester',
        services: [
          const AccountCloudService(
            id: 'dropbox',
            label: 'Dropbox',
            group: AccountCloudServiceGroup.cloudStorage,
            state: AccountCloudConnectionState.connected,
            description: 'Linked',
          ),
          const AccountCloudService(
            id: 'github',
            label: 'GitHub',
            group: AccountCloudServiceGroup.signIn,
            state: AccountCloudConnectionState.notConnected,
            description: 'Not linked',
          ),
        ],
      );
      final items = AccountCenterWideDesktopFrame.statusBarItems(snapshot);
      expect(
        items.firstWhere((item) => item.label == 'Services').value,
        '1 of 2 connected',
      );
      expect(
        items.firstWhere((item) => item.label == 'Remote').value,
        'Provider connected',
      );
    });
  });

  group('115.45 left navigation', () {
    test('sembilan entri_nav mengikuti urutan overview_sections spec', () {
      final spec = _readSpec();
      expect(
        AccountCenterWideDesktopFrame.leftNavigation
            .map((item) => item.section)
            .toList(),
        spec,
        reason:
            'urutan left nav harus identik spec.information_architecture'
            '.overview_sections',
      );
      expect(
        AccountCenterWideDesktopFrame.leftNavigation.map((item) => item.label),
        isNot(contains('API Keys')),
        reason: 'label navigasi kiri tidak boleh bentrok dengan tab strip',
      );
    });

    test('setiap entri punya ikon dan label yang bisa dibaca', () {
      for (final item in AccountCenterWideDesktopFrame.leftNavigation) {
        expect(item.label, isNotEmpty);
        expect(item.iconKey, isNotEmpty);
        expect(
          AccountCenterWideDesktopFrame.leftNavigation
              .where((other) => other.section == item.section)
              .length,
          1,
          reason: 'section ${item.section} harus unik',
        );
      }
    });
  });

  group('115.45 manifest', () {
    test('manifest repo cocok dengan domain dan provenance sumber', () {
      if (skipUnlessExternalCanonical(
        "manifest repo cocok dengan domain dan provenance sumber",
      )) {
        return;
      }
      final manifest =
          jsonDecode(File(manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.45');
      expect(
        (manifest['acceptance'] as Map).keys.toList(),
        AccountCenterWideDesktopFrame.acceptanceKeys,
      );
      final dims =
          manifest['acceptance']['layout_dimensions'] as Map<String, dynamic>;
      expect(dims['left_navigation_width_px'], 192);
      expect(dims['right_summary_width_px'], 349);
      expect(dims['bottom_status_height_px'], 40);
      expect(dims['row_columns'], <int>[3, 5, 5]);

      final sources = manifest['sources'] as Map<String, dynamic>;
      expect(
        sources['canonical_steps']['sha256'],
        AccountCenterWideDesktopFrame.canonicalSprintSha256,
      );
      expect(
        sources['product_spec']['sha256'],
        AccountCenterWideDesktopFrame.specSha256,
      );
      expect(manifest['domain'], AccountCenterWideDesktopFrame.domainPath);
      expect(manifest['tests'], AccountCenterWideDesktopFrame.testPaths);

      // Left navigation manifest == domain.
      final manifestNav = (manifest['left_navigation'] as List)
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['section'])
          .toList();
      expect(
        manifestNav,
        AccountCenterWideDesktopFrame.leftNavigation
            .map((item) => item.section)
            .toList(),
      );

      // Re-hash sumber bila file-nya ada di mesin ini.
      final specFile = File(AccountCenterWideDesktopFrame.specDocument);
      if (specFile.existsSync()) {
        expect(
          sha256.convert(specFile.readAsBytesSync()).toString(),
          AccountCenterWideDesktopFrame.specSha256,
        );
      }
      final sprintFile = File(
        AccountCenterWideDesktopFrame.canonicalSprintPath,
      );
      if (sprintFile.existsSync()) {
        expect(
          sha256.convert(sprintFile.readAsBytesSync()).toString(),
          AccountCenterWideDesktopFrame.canonicalSprintSha256,
        );
      }
    });

    test('acceptance kanonik 115.45 di sprint_115.json sesuai kontrak', () {
      final file = File(AccountCenterWideDesktopFrame.canonicalSprintPath);
      if (!file.existsSync()) {
        return;
      }
      final sprint =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = (sprint['steps'] as List).cast<Map<String, dynamic>>();
      final step = steps.firstWhere((entry) => entry['id'] == '115.45');
      expect(
        (step['acceptance'] as List),
        AccountCenterWideDesktopFrame.acceptanceKeys,
      );
    });
  });
}

List<String> _readSpec() {
  final file = File(AccountCenterWideDesktopFrame.specDocument);
  if (!file.existsSync()) {
    return const [
      'authentication',
      'quick_connect',
      'cloud_storage_usage',
      'connected_services',
      'api_keys_summary',
      'team_summary',
      'activity_log',
      'backup_sync_summary',
      'security_summary',
    ];
  }
  final spec = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ((spec['information_architecture'] as Map)['overview_sections']
          as List)
      .cast<String>();
}
