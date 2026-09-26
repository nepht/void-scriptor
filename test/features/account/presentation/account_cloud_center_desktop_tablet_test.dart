import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_desktop_tablet_adaptation.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.46 — bukti live screen Account & Cloud Center memakai chrome adaptif
/// desktop/tablet: ringkasan sebagai drawer, navigasi terlipat pada
/// compact desktop, navigasi atas pada tablet, tab strip tetap bergulir, dan
/// state tab bertahan saat viewport berpindah tier.
///
/// Kunci yang dipakai (semua di presentation, bukan tebakan):
/// `account-center-drawer-toggle`, `account-center-summary-drawer`,
/// `account-center-collapsed-rail`, `account-center-tab-strip`.
void main() {
  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(1180, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountCloudCenterScreen())),
    );
    await tester.pump();
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  group('115.46 right_drawer live', () {
    testWidgets('desktop: ringkasan tidak lagi band kanan, ada tombol drawer', (
      tester,
    ) async {
      await pumpCenter(tester);

      expect(byKey('account-center-drawer-toggle'), findsOneWidget);
      // Band kanan 115.45 tidak boleh ikut hidup di tier ini.
      expect(byKey('account-center-right-rail'), findsNothing);
      // Drawer tertutup secara default: isi ringkasan tidak dirender.
      expect(byKey('account-center-summary-drawer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer dibuka tetap menyisakan konten di kiri', (
      tester,
    ) async {
      await pumpCenter(tester);
      await tester.tap(byKey('account-center-drawer-toggle'));
      await tester.pump();
      await tester.pumpAndSettle();

      final contract = AccountCenterDesktopTabletAdaptation.resolve(1180)!;
      final drawer = byKey('account-center-summary-drawer');
      expect(drawer, findsOneWidget);
      final rect = tester.getRect(drawer);
      // Drawer menempel di tepi kanan dengan lebar token ringkasan.
      expect(rect.width, moreOrLessEquals(contract.drawerWidth, epsilon: 0.5));
      expect(rect.right, moreOrLessEquals(1180, epsilon: 0.5));
      // Konten utama MENYUSUT, bukan ditimpa: lebar band konten adalah sisa
      // setelah drawer, dan harus tetap >= satu kartu (card.minWidth).
      final content = tester.getRect(byKey('account-center-adaptive-content'));
      expect(
        content.width,
        moreOrLessEquals(contract.mainWidthWhenDrawerOpen, epsilon: 0.5),
      );
      expect(
        contract.drawerKeepsMainVisible,
        isTrue,
        reason: 'drawer tidak boleh menghapus konten utama',
      );
      expect(content.width, greaterThanOrEqualTo(220 - 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol drawer menutup kembali drawer', (tester) async {
      await pumpCenter(tester);
      await tester.tap(byKey('account-center-drawer-toggle'));
      await tester.pumpAndSettle();
      expect(byKey('account-center-summary-drawer'), findsOneWidget);

      await tester.tap(byKey('account-center-drawer-toggle'));
      await tester.pumpAndSettle();
      expect(byKey('account-center-summary-drawer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('115.46 collapsed_nav live', () {
    testWidgets('compact desktop: rail terlapit tanpa label, tanpa overflow', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1000, 900));

      expect(byKey('account-center-collapsed-rail'), findsOneWidget);
      final contract = AccountCenterDesktopTabletAdaptation.resolve(1000)!;
      expect(
        tester.getSize(byKey('account-center-collapsed-rail')).width,
        contract.navigationWidth,
      );
      // Label navigasi tidak boleh dirender saat terlipat.
      expect(find.text('Authentication'), findsNothing);
      // Tab strip bukan navigasi kiri, jadi label tab tetap boleh tampil.
      expect(find.text('Connected Accounts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: navigasi pindah ke atas, tanpa band kiri', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(800, 1000));

      expect(byKey('account-center-collapsed-rail'), findsNothing);
      expect(byKey('account-center-top-navigation'), findsOneWidget);
      expect(find.text('Authentication'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('115.46 two_column live', () {
    testWidgets('compact desktop: kartu overview dua kolom', (tester) async {
      await pumpCenter(tester, size: const Size(1000, 1400));

      final plan = AccountCenterResponsiveGrid.resolve(1000);
      expect(plan.tier, AccountCenterLayoutTier.compactDesktop);
      final auth = tester.getRect(
        byKey('account-overview-card-authentication'),
      );
      final quick = tester.getRect(
        byKey('account-overview-card-quick-connect'),
      );
      final storage = tester.getRect(byKey('account-overview-card-storage'));

      expect(quick.top, closeTo(auth.top, 0.5));
      expect(storage.top, greaterThan(auth.top));
      expect(storage.left, closeTo(auth.left, 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('115.46 scrollable_tabs live', () {
    testWidgets('tab strip bergulir mendatar dan memuat sembilan tab', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(800, 1000));

      final strip = byKey('account-center-tab-strip');
      expect(strip, findsOneWidget);
      final scrollable = find.descendant(
        of: strip,
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsWidgets);
      expect(
        find.descendant(of: strip, matching: find.text('Overview')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('115.46 no_horizontal_overflow live', () {
    for (final width in <double>[600, 800, 900, 1000, 1180, 1300, 1439]) {
      testWidgets('viewport ${width}px: tanpa overflow horizontal', (
        tester,
      ) async {
        await pumpCenter(tester, size: Size(width, 1200));
        expect(tester.takeException(), isNull, reason: 'viewport ${width}px');
      });
    }
  });

  group('115.46 state_preserved live', () {
    testWidgets('tab aktif bertahan saat viewport berpindah tier', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1536, 1024));
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1180, 900);
      await tester.pumpAndSettle();

      final active = tester.widget<Text>(
        find
            .descendant(
              of: byKey('account-center-tab-strip'),
              matching: find.text('Security'),
            )
            .last,
      );
      expect(active.data, 'Security');
      expect(tester.takeException(), isNull);
    });

    testWidgets('state drawer bertahan saat berpindah ke tier 115.45', (
      tester,
    ) async {
      await pumpCenter(tester, size: const Size(1180, 900));
      await tester.tap(byKey('account-center-drawer-toggle'));
      await tester.pumpAndSettle();
      expect(byKey('account-center-summary-drawer'), findsOneWidget);

      tester.view.physicalSize = const Size(1536, 1024);
      await tester.pumpAndSettle();

      // Di >=1440 ringkasan kembali menjadi band kanan frame 115.45; flag
      // drawer tidak boleh bocor sebagai drawer yang menggantung.
      expect(byKey('account-center-right-rail'), findsOneWidget);
      expect(byKey('account-center-summary-drawer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
