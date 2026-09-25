import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_responsive_grid.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.6 — bukti screen Account & Cloud Center MEMAKAI responsive grid
/// contract pada enam acceptance viewport dan tidak menghasilkan overflow
/// pada salah satunya.
///
/// Klaim per viewport:
/// - tanpa exception layout (RenderFlex overflow = gagal);
/// - tier resolusi sesuai breakpoint spec;
/// - jumlah kolom grid overview sesuai rencana tier (dibuktikan dari
///   posisi kartu baris pertama: AUTHENTICATION / QUICK CONNECT /
///   CLOUD STORAGE USAGE);
/// - ringkasan kanan berdampingan hanya pada tier wide_desktop.
void main() {
  const cases =
      <
        ({
          bool sideBySide,
          AccountCenterLayoutTier tier,
          int columns,
          String name,
          Size size,
        })
      >[
        (
          name: '1536x1024_reference',
          size: Size(1536, 1024),
          tier: AccountCenterLayoutTier.wideDesktop,
          columns: 3,
          sideBySide: true,
        ),
        (
          name: '1440_plus',
          size: Size(1440, 900),
          tier: AccountCenterLayoutTier.wideDesktop,
          columns: 3,
          sideBySide: true,
        ),
        (
          name: '1180_to_1439',
          size: Size(1180, 900),
          tier: AccountCenterLayoutTier.desktop,
          columns: 3,
          sideBySide: false,
        ),
        (
          name: '900_to_1179',
          size: Size(900, 900),
          tier: AccountCenterLayoutTier.compactDesktop,
          columns: 2,
          sideBySide: false,
        ),
        (
          name: '600_to_899',
          size: Size(600, 900),
          tier: AccountCenterLayoutTier.tablet,
          columns: 2,
          sideBySide: false,
        ),
        (
          name: 'under_600',
          size: Size(390, 844),
          tier: AccountCenterLayoutTier.mobile,
          columns: 1,
          sideBySide: false,
        ),
      ];

  for (final testCase in cases) {
    testWidgets('${testCase.name}: tier ${testCase.tier.name} renders '
        '${testCase.columns} columns without overflow', (tester) async {
      tester.view.physicalSize = testCase.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AccountCloudCenterScreen()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: testCase.name);
      expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);

      final plan = AccountCenterResponsiveGrid.resolve(testCase.size.width);
      expect(plan.tier, testCase.tier, reason: '${testCase.name} tier');
      expect(plan.summaryIsSideBySide, testCase.sideBySide);

      // tiga kartu baris pertama grid overview
      final dyAuth = tester.getTopLeft(find.text('AUTHENTICATION')).dy;
      final dyQuick = tester.getTopLeft(find.text('QUICK CONNECT')).dy;
      final dyStorage = tester.getTopLeft(find.text('CLOUD STORAGE USAGE')).dy;
      switch (testCase.columns) {
        case 3:
          expect(dyQuick, dyAuth, reason: '${testCase.name} kolom 3');
          expect(dyStorage, dyAuth, reason: '${testCase.name} kolom 3');
        case 2:
          expect(dyQuick, dyAuth, reason: '${testCase.name} kolom 2 baris 1');
          expect(
            dyStorage,
            greaterThan(dyAuth),
            reason: '${testCase.name} kartu ketiga turun baris',
          );
        case 1:
          expect(
            dyQuick,
            greaterThan(dyAuth),
            reason: '${testCase.name} kolom 1',
          );
          expect(
            dyStorage,
            greaterThan(dyQuick),
            reason: '${testCase.name} kolom 1',
          );
      }

      // ringkasan kanan: sisi (wide desktop) vs menumpuk — acuannya
      // tepi kiri konten halaman (breadcrumb), bukan teks judul yang
      // ter-indents badge ikon.
      final dxMain = tester
          .getTopLeft(find.byKey(const ValueKey('account-center-breadcrumb')))
          .dx;
      final dxRail = tester.getTopLeft(find.text('ACCOUNT SUMMARY')).dx;
      if (testCase.sideBySide) {
        expect(
          dxRail,
          greaterThan(dxMain),
          reason: '${testCase.name} right summary berdampingan',
        );
      } else {
        expect(
          dxRail,
          dxMain,
          reason: '${testCase.name} right summary menumpuk',
        );
      }
      expect(tester.takeException(), isNull, reason: testCase.name);
    });
  }
}
