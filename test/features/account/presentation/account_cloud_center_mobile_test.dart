import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_mobile_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.47 — bukti live screen Account & Cloud Center pada tier `mobile`
/// (<600px): satu kolom, detail provider sebagai sheet layar penuh, action
/// bar menempel di bawah yang menghormati safe area OS, target sentuh 44px,
/// dan alternatif teks chart yang terlihat.
///
/// Kunci yang dipakai (semua di presentation, bukan tebakan):
/// `account-center-mobile-layout`, `account-center-mobile-action-bar`,
/// `account-center-mobile-action-<slug>`, `account-center-provider-details`,
/// `account-center-provider-details-close`.
void main() {
  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    EdgeInsets viewPadding = EdgeInsets.zero,
    ProviderConnectorManifest? providerManifest,
    ValueChanged<ProviderConnectorEntry>? onConnectProvider,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    // `viewPadding`, BUKAN `padding`: action bar dijejak di luar area konten
    // dan tidak boleh menyusut saat keyboard muncul, jadi ia membaca
    // `MediaQuery.viewPadding` (kontrak 115.47, `safeAreaBottom`). Probed:
    // mengisi `view.padding` saja TIDAK mengubah `viewPadding`.
    tester.view.viewPadding = FakeViewPadding(
      top: viewPadding.top,
      bottom: viewPadding.bottom,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AccountCloudCenterScreen(
            providerManifest: providerManifest,
            onConnectProvider: onConnectProvider,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Manifest dengan tepat satu entry `available`, jadi `isConnectable`
  /// tidak kosong. Sisanya tetap `UNVERIFIED` seperti standard manifest.
  ///
  /// Dibangun dengan [`ProviderConnectorManifest.fromJsonString`] dari
  /// `toJson()` standard lalu availability satu entry dinaikkan, supaya test
  /// memakai API produksi yang sama dan bukan konstruktor tiruan.
  ProviderConnectorManifest connectableManifest() {
    final base = ProviderConnectorManifest.standard;
    final json = <String, Object?>{
      'schema_version': 1,
      'entries': [
        for (final entry in base.all)
          <String, Object?>{
            ...entry.toJson(),
            if (entry.providerId == 'google_drive')
              'availability': ProviderConnectorAvailability.available.wireName,
          },
      ],
    };
    final manifest = ProviderConnectorManifest.fromJsonString(jsonEncode(json));
    expect(
      manifest.all.where((entry) => entry.isConnectable).length,
      1,
      reason: 'hanya google_drive yang boleh connectable',
    );
    return manifest;
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  group('115.47 single_column live', () {
    testWidgets('mobile: satu kolom penuh tanpa chrome tier lain', (
      tester,
    ) async {
      await pumpCenter(tester);

      expect(byKey('account-center-mobile-layout'), findsOneWidget);
      // Chrome tier lain tidak boleh ikut hidup di bawah 600px.
      expect(byKey('account-center-desktop-left-navigation'), findsNothing);
      expect(byKey('account-center-collapsed-rail'), findsNothing);
      expect(byKey('account-center-top-navigation'), findsNothing);
      expect(byKey('account-center-left-navigation'), findsNothing);
      expect(byKey('account-center-drawer-toggle'), findsNothing);
      expect(byKey('account-center-summary-drawer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kartu overview turun satu per baris', (tester) async {
      await pumpCenter(tester);

      final plan = AccountCenterResponsiveGrid.resolve(390);
      expect(plan.tier, AccountCenterLayoutTier.mobile);
      final contract = AccountCenterMobileAdaptation.resolve(
        viewportWidth: 390,
        viewportHeight: 844,
      )!;
      final auth = tester.getRect(
        byKey('account-overview-card-authentication'),
      );
      final quick = tester.getRect(
        byKey('account-overview-card-quick-connect'),
      );
      final storage = tester.getRect(byKey('account-overview-card-storage'));

      // Satu kolom: kartu berikutnya SELALU di bawah, tidak pernah samping.
      expect(quick.top, greaterThan(auth.bottom - 0.5));
      expect(storage.top, greaterThan(quick.bottom - 0.5));
      // Lebar kartu = lebar konten penuh dari kontrak.
      expect(auth.width, moreOrLessEquals(contract.contentWidth, epsilon: 0.5));
      expect(
        quick.width,
        moreOrLessEquals(contract.contentWidth, epsilon: 0.5),
        reason: 'satu kolom mengisi lebar konten',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('115.47 provider_sheet live', () {
    testWidgets('detail provider membuka sebagai sheet layar penuh', (
      tester,
    ) async {
      await pumpCenter(tester);

      // Tertutup secara default: tidak ada sheet yang menggantung.
      expect(byKey('account-center-provider-details'), findsNothing);

      await tester.ensureVisible(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();

      final sheet = byKey('account-center-provider-details');
      expect(sheet, findsOneWidget);
      final rect = tester.getRect(sheet);
      // Spec: "provider details open as full-screen sheet".
      expect(rect.width, moreOrLessEquals(390, epsilon: 0.5));
      expect(rect.height, moreOrLessEquals(844, epsilon: 0.5));
      // Isi sheet memakai entry yang sama (bukan ringkasan provider kedua).
      expect(
        find.descendant(of: sheet, matching: find.text('Google Drive')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol tutup menutup sheet kembali', (tester) async {
      await pumpCenter(tester);
      await tester.ensureVisible(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();
      expect(byKey('account-center-provider-details'), findsOneWidget);

      await tester.tap(byKey('account-center-provider-details-close'));
      await tester.pumpAndSettle();
      expect(byKey('account-center-provider-details'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sheet tetap layar penuh pada viewport 320px', (tester) async {
      await pumpCenter(tester, size: const Size(320, 568));

      await tester.ensureVisible(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();

      final rect = tester.getRect(byKey('account-center-provider-details'));
      expect(rect.width, moreOrLessEquals(320, epsilon: 0.5));
      expect(rect.height, moreOrLessEquals(568, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('115.47 safe_actions live', () {
    testWidgets('action bar menempel di bawah isi scroll', (tester) async {
      await pumpCenter(tester);

      final bar = byKey('account-center-mobile-action-bar');
      expect(bar, findsOneWidget);
      final barRect = tester.getRect(bar);
      final contract = AccountCenterMobileAdaptation.resolve(
        viewportWidth: 390,
        viewportHeight: 844,
      )!;
      expect(
        barRect.height,
        moreOrLessEquals(contract.actionBarTotalHeight, epsilon: 0.5),
      );
      // Bar menempel di tepi bawah viewport, bukan ikut tergulir.
      expect(barRect.bottom, moreOrLessEquals(844, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('safe area OS menambah tinggi bar dan dicadangkan', (
      tester,
    ) async {
      await pumpCenter(tester, viewPadding: const EdgeInsets.only(bottom: 34));

      final barRect = tester.getRect(byKey('account-center-mobile-action-bar'));
      final contract = AccountCenterMobileAdaptation.resolve(
        viewportWidth: 390,
        viewportHeight: 844,
        safeAreaBottom: 34,
      )!;
      expect(barRect.height, moreOrLessEquals(86, epsilon: 0.5));
      expect(
        barRect.height,
        moreOrLessEquals(contract.actionBarTotalHeight, epsilon: 0.5),
      );
      // Area konten berhenti di atas bar supaya kartu terakhir tidak
      // tertutup (no_clipped_content).
      final content = tester.getRect(byKey('account-center-mobile-content'));
      expect(
        content.bottom,
        lessThanOrEqualTo(barRect.top + 0.5),
        reason: 'area konten tidak boleh berakhir di bawah action bar',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('115.47 44px_targets live', () {
    testWidgets('setiap aksi di action bar >= 44x44', (tester) async {
      await pumpCenter(tester);

      final contract = AccountCenterMobileAdaptation.resolve(
        viewportWidth: 390,
        viewportHeight: 844,
      )!;
      final actions = <String>[
        'account-center-mobile-action-overview',
        'account-center-mobile-action-search',
        'account-center-mobile-action-connect',
      ];
      for (final key in actions) {
        final finder = byKey(key);
        expect(finder, findsOneWidget, reason: key);
        expect(
          AccountCenterAccessibility.meetsTouchTarget(tester.getSize(finder)),
          isTrue,
          reason: '$key ${tester.getSize(finder)} < 44x44',
        );
        expect(
          tester.getSize(finder).height,
          moreOrLessEquals(contract.actionTargetHeight, epsilon: 0.5),
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'aksi ketiga tidak boleh mati saat tidak ada yang connectable',
      (tester) async {
        // Standard manifest 115.9 menyatakan seluruh entry `UNVERIFIED`, jadi
        // `isConnectable` kosong. Aksi 'connect' pada bar TIDAK boleh tetap
        // dirender sebagai tombol aktif yang tidak melakukan apa-apa — komentar
        // kontrak pada wiring slice sendiri menyatakan "tidak ada aksi yang
        // mati di tier ini".
        await pumpCenter(tester);

        final connect = byKey('account-center-mobile-action-connect');
        expect(connect, findsOneWidget, reason: 'bar tetap punya tiga slot');
        expect(
          tester
              .widget<IconButton>(
                find.descendant(of: connect, matching: find.byType(IconButton)),
              )
              .onPressed,
          isNull,
          reason: 'tanpa entry connectable aksi harus non-interaktif',
        );
      },
    );

    testWidgets('aksi ketiga hidup bila ada entry connectable', (tester) async {
      await pumpCenter(
        tester,
        providerManifest: connectableManifest(),
        onConnectProvider: (_) {},
      );

      final connect = byKey('account-center-mobile-action-connect');
      expect(connect, findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: connect, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNotNull,
        reason: 'ada provider connectable -> aksi harus bisa dipakai',
      );

      // Dan aksi itu benar-benar membuka sheet, bukan tombol hampa.
      await tester.tap(connect);
      await tester.pumpAndSettle();
      expect(byKey('account-center-provider-details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol tutup sheet juga >= 44x44', (tester) async {
      await pumpCenter(tester);
      await tester.ensureVisible(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('quick-connect-provider-google_drive'));
      await tester.pumpAndSettle();

      final close = byKey('account-center-provider-details-close');
      expect(
        AccountCenterAccessibility.meetsTouchTarget(tester.getSize(close)),
        isTrue,
        reason: 'close sheet ${tester.getSize(close)}',
      );
    });
  });

  group('115.47 text_alternatives live', () {
    testWidgets('chart tetap punya alternatif teks di tier mobile', (
      tester,
    ) async {
      await pumpCenter(tester);

      // Alternatif teks chart adalah acceptance 115.7; 115.47 mewajibkannya
      // di tier mobile secara spesifik, jadi keduanya harus benar-benar hidup.
      expect(find.bySemanticsLabel('AI USAGE THIS MONTH'), findsOneWidget);
      expect(find.bySemanticsLabel('STORAGE DISTRIBUTION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('115.47 no_clipped_content live', () {
    for (final size in <({String name, Size size})>[
      (name: '320x568', size: const Size(320, 568)),
      (name: '360x640', size: const Size(360, 640)),
      (name: '390x844', size: const Size(390, 844)),
      (name: '480x800', size: const Size(480, 800)),
      (name: '599x900', size: const Size(599, 900)),
    ]) {
      testWidgets('${size.name}: tanpa overflow dan konten utuh', (
        tester,
      ) async {
        await pumpCenter(tester, size: size.size);
        expect(tester.takeException(), isNull, reason: size.name);
        expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
        // Judul kartu terakhir harus tetap bisa dicapai (tidak terpotong bar).
        await tester.ensureVisible(
          byKey('account-overview-card-security-center'),
        );
        await tester.pumpAndSettle();
        expect(
          byKey('account-overview-card-security-center'),
          findsOneWidget,
          reason: 'kartu terakhir tidak boleh hilang pada ${size.name}',
        );
        expect(tester.takeException(), isNull, reason: size.name);
      });
    }
  });
}
