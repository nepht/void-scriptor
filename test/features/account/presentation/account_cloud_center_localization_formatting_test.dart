import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/account_operational_metrics.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_localization_formatting.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// 115.49 — Localization & Formatting, bukti chrome.
///
/// Cakupan lokal: teks yang dirender tetap utuh dan dapat dibungkus saat
/// ekspansi 200%, layout memantul benar pada ambient RTL, dan angka yang
/// tampil memakai format kontrak (satuan desimal, persen, pengelompokan ribuan,
/// uang dua desimal). Sertifikasi locale penuh, IME, dan Intl/ICU tetap
/// DEFERRED-EXTERNAL.
void main() {
  const metrics = AccountOperationalMetrics(
    promptTokens: 1200,
    completionTokens: 340,
    estimatedCost: 1.25,
    totalStorageBytes: 4096,
    storageBytesByCategory: {'Images': 3072, 'Database': 1024},
  );

  Future<void> pumpCenter(
    WidgetTester tester, {
    Size size = const Size(1536, 1024),
    double textScale = 1.0,
    TextDirection direction = TextDirection.ltr,
    bool withMetrics = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Directionality(
              textDirection: direction,
              child: AccountCloudCenterScreen(
                operationalMetrics: withMetrics ? metrics : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('115.49 text_expansion', () {
    for (final entry in <({String name, Size size})>[
      (name: 'desktop 1536x1024', size: const Size(1536, 1024)),
      (name: 'mobile 390x844', size: const Size(390, 844)),
    ]) {
      testWidgets('${entry.name}: label tab tetap utuh pada 200%', (
        tester,
      ) async {
        await pumpCenter(
          tester,
          size: entry.size,
          textScale: AccountCenterAccessibility.maximumSupportedTextScale,
        );
        expect(tester.takeException(), isNull, reason: entry.name);
        for (final tab in AccountCenterInformationArchitecture.tabs) {
          expect(
            find.text(tab.label, skipOffstage: false),
            findsWidgets,
            reason:
                'Label "${tab.label}" hilang saat ekspansi 200% pada ${entry.name} — '
                'kehilangan label = kehilangan navigasi bagi pembaca yang '
                'membutuhkan teks besar.',
          );
        }
        expect(tester.takeException(), isNull, reason: entry.name);
      });
    }

    testWidgets('metrik yang dirender membungkus, bukan dipotong ellipsis', (
      tester,
    ) async {
      await pumpCenter(
        tester,
        withMetrics: true,
        textScale: AccountCenterAccessibility.maximumSupportedTextScale,
      );
      expect(tester.takeException(), isNull);
      final metric = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (text) => text.data?.contains('indexed') ?? false,
            orElse: () => const Text(''),
          );
      expect(metric.data, isNotEmpty, reason: 'Pesan storage harus dirender.');
      expect(
        metric.overflow,
        isNot(TextOverflow.ellipsis),
        reason:
            'Angka storage dipotong ellipsis saat ekspansi = angka hilang; '
            'pesan metrik wajib membungkus.',
      );
      expect(
        AccountCenterLocalizationFormatting.requireWrappable(metric.data!),
        metric.data,
      );
    });

    testWidgets('setiap string yang dirender bebas karakter non-wrappable', (
      tester,
    ) async {
      await pumpCenter(tester, withMetrics: true);
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      expect(
        rendered.length,
        greaterThan(15),
        reason: 'Scan kecil berarti scan salah.',
      );
      for (final value in rendered) {
        AccountCenterLocalizationFormatting.requireWrappable(
          value,
          field: 'rendered text',
        );
      }
    });
  });

  group('115.49 rtl', () {
    testWidgets('band navigasi, grid, dan rail memantul pada ambient RTL', (
      tester,
    ) async {
      await pumpCenter(tester, direction: TextDirection.ltr);
      final ltrNav = tester.getRect(
        find.byKey(const ValueKey('account-center-left-navigation')),
      );
      final ltrGrid = tester.getRect(
        find.byKey(const ValueKey('account-center-main-grid')),
      );
      final ltrRail = tester.getRect(
        find.byKey(const ValueKey('account-center-right-rail')),
      );
      expect(ltrNav.left, lessThan(ltrGrid.left));
      expect(ltrRail.left, greaterThan(ltrGrid.left));

      await pumpCenter(tester, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final rtlNav = tester.getRect(
        find.byKey(const ValueKey('account-center-left-navigation')),
      );
      final rtlGrid = tester.getRect(
        find.byKey(const ValueKey('account-center-main-grid')),
      );
      final rtlRail = tester.getRect(
        find.byKey(const ValueKey('account-center-right-rail')),
      );
      expect(
        rtlNav.left,
        greaterThan(rtlGrid.left),
        reason: 'Navigasi kiri harus berpindah ke sisi kanan pada RTL.',
      );
      expect(
        rtlRail.left,
        lessThan(rtlGrid.left),
        reason: 'Rail ringkasan harus berpindah ke sisi kiri pada RTL.',
      );
      // Cermin sejati: tepi luar tiap band bertukar sisi dengan padding yang
      // sama, bukan bertukar posisi dengan band lain yang lebarnya berbeda.
      expect(
        rtlNav.right,
        moreOrLessEquals(
          tester.view.physicalSize.width - ltrNav.left,
          epsilon: 0.01,
        ),
      );
      expect(
        rtlRail.left,
        moreOrLessEquals(
          tester.view.physicalSize.width - ltrRail.right,
          epsilon: 0.01,
        ),
      );
      for (final tab in AccountCenterInformationArchitecture.tabs) {
        expect(find.text(tab.label, skipOffstage: false), findsWidgets);
      }
    });
  });

  group('115.49 storage_units + percentages + currencies (live chrome)', () {
    testWidgets('angka yang tampil memakai format kontrak', (tester) async {
      await pumpCenter(tester, withMetrics: true);
      expect(tester.takeException(), isNull);
      // 4096 B = 4.1 KB desimal (bukan `4 KB` biner yang dihasilkan formatter
      // chrome sebelum 115.49).
      expect(find.textContaining('4.1 KB indexed'), findsOneWidget);
      expect(find.textContaining('Images 75%'), findsOneWidget);
      expect(find.textContaining('Database 25%'), findsOneWidget);
      expect(find.textContaining('1,540 tokens'), findsOneWidget);
      expect(find.textContaining(r'$1.25 estimated'), findsOneWidget);
    });

    testWidgets('tanpa metrics chrome tidak mengarang angka', (tester) async {
      await pumpCenter(tester);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('indexed'), findsNothing);
      expect(find.textContaining('GB of'), findsNothing);
    });
  });
}
