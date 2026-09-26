import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_wide_desktop_frame.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.45 — bukti screen Account & Cloud Center MEMAKAI frame wide desktop:
/// left navigation, main grid, right summary, dan status bar pada viewport
/// referensi 1536x1024, tanpa overlap dan tanpa overflow.
///
/// Kunci yang dipakai (semua di domain frame, bukan tebakan):
/// `account-center-left-navigation`, `account-center-main-grid`,
/// `account-center-right-rail`, `account-center-status-bar`.
void main() {
  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(1536, 1024),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountCloudCenterScreen())),
    );
    await tester.pump();
  }

  Finder frame(String key) => find.byKey(ValueKey(key));

  group('115.45 frame wide desktop live', () {
    testWidgets('viewport referensi merender keempat band frame', (
      tester,
    ) async {
      await pumpCenter(tester);

      expect(frame('account-center-left-navigation'), findsOneWidget);
      expect(frame('account-center-main-grid'), findsOneWidget);
      expect(frame('account-center-right-rail'), findsOneWidget);
      expect(frame('account-center-status-bar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layout_dimensions: tinggi tiap band sama dengan kontrak', (
      tester,
    ) async {
      await pumpCenter(tester);
      final frameLayout = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;

      expect(
        tester.getSize(frame('account-center-left-navigation')).width,
        frameLayout.leftNavigationWidth,
      );
      expect(
        tester.getSize(frame('account-center-right-rail')).width,
        frameLayout.rightRailWidth,
      );
      expect(
        tester.getSize(frame('account-center-status-bar')).height,
        frameLayout.statusBarHeight,
      );
      expect(
        tester.getSize(frame('account-center-main-grid')).width,
        moreOrLessEquals(frameLayout.mainWidth, epsilon: 0.5),
      );
    });

    testWidgets('no_overlap: keempat band tidak saling menimpa', (
      tester,
    ) async {
      await pumpCenter(tester);

      final nav = tester.getRect(frame('account-center-left-navigation'));
      final main = tester.getRect(frame('account-center-main-grid'));
      final rail = tester.getRect(frame('account-center-right-rail'));
      final status = tester.getRect(frame('account-center-status-bar'));

      expect(nav.right, lessThanOrEqualTo(main.left + 0.5));
      expect(main.right, lessThanOrEqualTo(rail.left + 0.5));
      expect(rail.right, lessThanOrEqualTo(1536 + 0.5));
      expect(status.top, greaterThanOrEqualTo(main.bottom - 0.5));
      expect(status.bottom, lessThanOrEqualTo(1024 + 0.5));
    });

    testWidgets('right_rail: ringkasan tetap di band kanan, bukan di bawah', (
      tester,
    ) async {
      await pumpCenter(tester);

      final main = tester.getRect(frame('account-center-main-grid'));
      final rail = tester.getRect(frame('account-center-right-rail'));
      final summary = tester.getRect(find.text('ACCOUNT SUMMARY'));

      expect(
        rail.contains(summary.center),
        isTrue,
        reason: 'judul ringkasan harus berada DI DALAM band rail kanan',
      );
      expect(summary.left, greaterThan(main.right - 1));
    });

    testWidgets('status_bar: isi jujur dari snapshot, tanpa nilai fabrikasi', (
      tester,
    ) async {
      await pumpCenter(tester);

      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(
        find.text('Local data only'),
        findsOneWidget,
        reason: 'tanpa connector remote, status harus menyatakan cakupan lokal',
      );
    });

    testWidgets(
      'left navigation: sembilan entri overview_sections, unik, terurut vertikal',
      (tester) async {
        await pumpCenter(tester);

        final nav = frame('account-center-left-navigation');
        expect(nav, findsOneWidget);
        var previousDy = -1.0;
        for (final item in AccountCenterWideDesktopFrame.leftNavigation) {
          final text = find.descendant(
            of: nav,
            matching: find.text(item.label),
          );
          expect(text, findsOneWidget, reason: 'nav ${item.section}');
          final dy = tester.getTopLeft(text).dy;
          expect(dy, greaterThan(previousDy), reason: 'urutan ${item.section}');
          previousDy = dy;
        }
      },
    );

    testWidgets('consistent_cards: kartu satu baris sama lebar dan rata', (
      tester,
    ) async {
      await pumpCenter(tester);
      final frameLayout = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;

      // Baris pertama mockup: tiga kartu, lebar harus sama dan sesuai
      // cardWidthFor(3) dari kontrak frame.
      final row = ['authentication', 'quick-connect', 'storage'];
      final rects = <Rect>[
        for (final slug in row)
          tester.getRect(find.byKey(ValueKey('account-overview-card-$slug'))),
      ];
      for (final rect in rects) {
        expect(
          rect.width,
          moreOrLessEquals(frameLayout.cardWidthFor(3), epsilon: 0.5),
        );
        expect(rect.top, moreOrLessEquals(rects.first.top, epsilon: 0.5));
      }
      // Baris kedua mockup: LIMA kartu. Pada 1536 hanya EMPAT muat per baris
      // (aturan fit card.minWidth pada band main 961px), jadi lima kartu
      // membentuk 4 + 1 dan lebarnya mengikuti kolom hasil kontrak, bukan
      // angka mockup yang tidak mungkin berlaku.
      expect(frameLayout.rowColumns[1], 4);
      final row2 = [
        'connected-services',
        'api-providers',
        'developer-tools',
        'creative-tools',
        'payment-methods',
      ];
      final rects2 = <Rect>[
        for (final slug in row2)
          tester.getRect(find.byKey(ValueKey('account-overview-card-$slug'))),
      ];
      for (final rect in rects2) {
        expect(
          rect.width,
          moreOrLessEquals(frameLayout.cardWidthFor(4), epsilon: 0.5),
          reason: 'kelima kartu mockup dirender sesuai kolom hasil kontrak',
        );
      }
      // Empat kartu pertama sebaris; kartu kelima turun ke baris kedua.
      final firstFour = rects2.take(4).map((rect) => rect.top).toSet();
      expect(firstFour.length, 1, reason: 'empat kartu harus rata satu baris');
      expect(
        rects2[4].top,
        greaterThan(rects2.first.top),
        reason: 'kartu kelima tidak boleh dipaksa sebaris dan terpotong',
      );
    });

    testWidgets('scroll_containment: seluruh baris muat tanpa scroll halaman', (
      tester,
    ) async {
      await pumpCenter(tester);

      final frameLayout = AccountCenterWideDesktopFrame.resolve(
        width: 1536,
        height: 1024,
      )!;
      final status = tester.getRect(frame('account-center-status-bar'));
      for (final slug in const [
        'authentication',
        'quick-connect',
        'storage',
        'connected-services',
        'api-providers',
        'security-center',
      ]) {
        final rect = tester.getRect(
          find.byKey(ValueKey('account-overview-card-$slug')),
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(status.top + 0.5),
          reason: 'kartu $slug tidak boleh melewati band status bar',
        );
      }
      expect(
        tester.getSize(frame('account-center-main-grid')).height,
        lessThanOrEqualTo(frameLayout.gridHeight + 0.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('viewport lebar di atas referensi tetap memakai frame', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1920, 1200));

      expect(frame('account-center-left-navigation'), findsOneWidget);
      expect(frame('account-center-status-bar'), findsOneWidget);
      final frameLayout = AccountCenterWideDesktopFrame.resolve(
        width: 1920,
        height: 1200,
      )!;
      expect(frameLayout.bandsAreDisjoint(), isTrue);
      expect(
        tester.getSize(frame('account-center-right-rail')).width,
        frameLayout.rightRailWidth,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('di bawah 1440 frame tidak dipaksakan (tier 115.46/115.47)', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1180, 900));

      // Band-band frame 115.45 tidak boleh muncul di bawah 1440.
      expect(frame('account-center-left-navigation'), findsNothing);
      expect(frame('account-center-right-rail'), findsNothing);
      expect(frame('account-center-status-bar'), findsNothing);
      expect(frame('account-center-main-grid'), findsNothing);
      // Ringkasan pada tier `desktop` sejak 115.46 disajikan sebagai drawer
      // yang tertutup secara default — bukan band kanan, bukan kartu grid.
      // Riwayat: sebelum 115.46 jalur responsif menumpuk rail di bawah.
      expect(
        find.text('ACCOUNT SUMMARY'),
        findsNothing,
        reason: 'drawer 115.46 harus tertutup sampai tombol drawer ditekan',
      );
      expect(
        find.byKey(const ValueKey('account-center-drawer-toggle')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
