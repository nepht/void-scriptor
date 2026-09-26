import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.5 — bukti bahwa screen Account & Cloud Center MEMAKAI token desain
/// product spec (bukan hanya menyimpannya di domain): ukuran halaman,
/// spacing, radius, tipografi, ikon, avatar, dan density diukur dari
/// widget yang dirender.
void main() {
  Future<void> pumpCenter(WidgetTester tester, {VoidCallback? onSignIn}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AccountCloudCenterScreen(onSignIn: onSignIn)),
        ),
      ),
    );
    await tester.pump();
  }

  group('115.5 design tokens applied — layout and spacing', () {
    testWidgets('page padding and wrap gaps follow layout tokens', (
      tester,
    ) async {
      await pumpCenter(tester);

      // 115.36: panel luar tidak lagi `SingleChildScrollView` (kontrak satu
      // panel tanpa scroll), jadi padding halaman dipasang pada `Padding`
      // biasa. Nilai token yang dikontrakkan tidak berubah.
      final pagePadding = tester
          .widgetList<Padding>(find.byType(Padding))
          .map((padding) => padding.padding)
          .firstWhere(
            (value) =>
                value ==
                EdgeInsets.symmetric(
                  horizontal:
                      AccountCenterDesignTokens.layout.pageHorizontalPadding,
                  vertical:
                      AccountCenterDesignTokens.layout.pageVerticalPadding,
                ),
          );
      expect(
        pagePadding,
        EdgeInsets.fromLTRB(
          AccountCenterDesignTokens.layout.pageHorizontalPadding,
          AccountCenterDesignTokens.layout.pageVerticalPadding,
          AccountCenterDesignTokens.layout.pageHorizontalPadding,
          AccountCenterDesignTokens.layout.pageVerticalPadding,
        ),
        reason: 'page padding harus 16 horizontal / 12 vertical (spec layout)',
      );

      // Baris mockup memakai Row, bukan Wrap: kartu mockup adalah baris
      // dengan tinggi terkunci, bukan grid yang mengalir.
      expect(
        find.byType(Row),
        findsWidgets,
        reason: 'baris mockup memakai Row',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('service row enforces the spec minimum height', (tester) async {
      await pumpCenter(tester);

      final row = find
          .ancestor(of: find.text('Google Drive'), matching: find.byType(Row))
          .first;
      final rowBox = tester.renderObject<RenderBox>(row);
      expect(
        rowBox.constraints.minHeight,
        AccountCenterDesignTokens.serviceRow.minHeight,
        reason: 'service_row min_height 44 dipasang sebagai constraint Row',
      );
      expect(
        rowBox.size.height,
        greaterThanOrEqualTo(AccountCenterDesignTokens.serviceRow.minHeight),
        reason: 'tinggi Row QUICK CONNECT >= 44 (spec service_row)',
      );
    });
  });

  group('115.5 design tokens applied — typography', () {
    testWidgets('page title, section titles, body, caption, metric', (
      tester,
    ) async {
      await pumpCenter(tester);

      double fontSizeOf(Finder finder) {
        final text = tester.widget<Text>(finder.first);
        expect(text.style, isNotNull, reason: '$finder tanpa style');
        return text.style!.fontSize!;
      }

      expect(
        fontSizeOf(find.text('ACCOUNT & CLOUD CENTER')),
        AccountCenterDesignTokens.typography.pageTitle,
      );
      expect(
        fontSizeOf(find.text('QUICK CONNECT')),
        AccountCenterDesignTokens.typography.sectionTitle,
      );
      expect(
        fontSizeOf(find.text('Manage your account access')),
        AccountCenterDesignTokens.typography.caption,
      );
      expect(
        fontSizeOf(
          find.text('Kelola akun, koneksi, cloud, dan integrasi layanan Anda'),
        ),
        AccountCenterDesignTokens.typography.body,
      );
      expect(
        fontSizeOf(find.byKey(const ValueKey('account-center-breadcrumb'))),
        AccountCenterDesignTokens.typography.caption,
        reason: 'breadcrumb memakai caption 11 (bukan literal 10)',
      );
      expect(
        fontSizeOf(find.text('Unavailable')),
        AccountCenterDesignTokens.typography.metric,
        reason: 'nilai _MetricTile memakai metric 18',
      );
    });
  });

  group('115.5 design tokens applied — icons, avatar, radius', () {
    testWidgets('icon sizes come from the icon token scale', (tester) async {
      await pumpCenter(tester);

      expect(
        tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).size,
        AccountCenterDesignTokens.iconSizes.page,
        reason: 'badge halaman header memakai page icon 36',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.hub_outlined)).size,
        AccountCenterDesignTokens.iconSizes.section,
        reason: 'ikon kartu kapabilitas memakai section icon 24',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.workspace_premium_outlined)).size,
        AccountCenterDesignTokens.iconSizes.section,
        reason: 'ikon PLAN memakai section icon 24',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.block_outlined)).size,
        AccountCenterDesignTokens.iconSizes.action,
        reason: 'ikon aksi baris memakai action icon 20',
      );
      expect(
        tester
            .widgetList<Icon>(find.byIcon(Icons.arrow_forward_ios))
            .first
            .size,
        AccountCenterDesignTokens.iconSizes.action,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.search)).size,
        AccountCenterDesignTokens.iconSizes.action,
        reason: 'tombol aksi header memakai action icon 20',
      );
    });

    testWidgets('avatar and card radius follow tokens', (tester) async {
      await pumpCenter(tester);

      // 115.36: kartu AUTHENTICATION menggantikan ringkasan akun terpisah, dan
      // `CircleAvatar` digantikan `_ProfileAvatar` (gambar/inisial/none) yang
      // bersudut radius.tile. Kontrak "avatar mengikuti token" tetap hidup,
      // hanya sekarang menunjuk token yang benar-benar dipakai surface itu —
      // `avatarSizes.image` 80px pada kartu utama mockup, bukan
      // `avatarSizes.compact` 40px milik ringkasan lama.
      final avatarBox = tester.getRect(
        find.byKey(const ValueKey('account-profile-avatar')),
      );
      expect(
        avatarBox.width,
        moreOrLessEquals(AccountCenterDesignTokens.avatarSizes.image, epsilon: 0.01),
        reason: 'avatar kartu authentication memakai image 80px',
      );
      expect(
        avatarBox.height,
        moreOrLessEquals(AccountCenterDesignTokens.avatarSizes.image, epsilon: 0.01),
      );

      final cardContainers = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('QUICK CONNECT'),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final cardRadii = <double>[
        for (final container in cardContainers)
          if (container.decoration is BoxDecoration)
            if (((container.decoration! as BoxDecoration).borderRadius
                    as BorderRadius?) !=
                null)
              ((container.decoration! as BoxDecoration).borderRadius!
                      as BorderRadius)
                  .topLeft
                  .x,
      ];
      expect(
        cardRadii,
        contains(AccountCenterDesignTokens.radius.card),
        reason: 'kartu dashboard memakai radius.card 10',
      );
      expect(
        cardRadii,
        isNot(contains(14.0)),
        reason: 'radius 14 lama harus hilang',
      );
    });

    testWidgets('search dialog uses the dialog radius token', (tester) async {
      await pumpCenter(tester);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.shape, isA<RoundedRectangleBorder>());
      final shape = dialog.shape! as RoundedRectangleBorder;
      expect(
        (shape.borderRadius as BorderRadius).topLeft.x,
        AccountCenterDesignTokens.radius.dialog,
        reason: 'dialog pencarian memakai radius.dialog 12',
      );
    });
  });

  group('115.5 design tokens applied — density', () {
    testWidgets('tab strip matches the layout tab bar height', (tester) async {
      await pumpCenter(tester);

      final tab = find
          .ancestor(of: find.text('Overview'), matching: find.byType(InkWell))
          .first;
      expect(
        tester.getSize(tab).height,
        AccountCenterDesignTokens.layout.tabBarHeight,
        reason: 'tab strip 40px (>= minimum keyboard target 32)',
      );
    });

    testWidgets('add-another-method keeps the minimum touch target', (
      tester,
    ) async {
      await pumpCenter(tester, onSignIn: () {});

      // 115.36: aksi kartu authentication adalah "+ Add Another Method"
      // (mockup), bukan lagi "Sign in or connect account".
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '+ Add Another Method'),
      );
      expect(
        button.style?.minimumSize?.resolve(const <WidgetState>{}),
        Size(0, AccountCenterDesignTokens.density.minimumTouchTarget),
        reason: 'minimum touch target 44 berasal dari token density',
      );
    });
  });
}
