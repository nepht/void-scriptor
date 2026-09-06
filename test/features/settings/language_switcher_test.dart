import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/widgets/branding/brand_assets.dart';
import 'package:void_scriptor/features/settings/presentation/language_switcher.dart';

void main() {
  group('BrandAssets', () {
    test('path kategori konsisten dengan struktur assets', () {
      expect(BrandAssets.aiTech, 'assets/brands/ai_tech');
      expect(BrandAssets.flags, 'assets/brands/flags');
      expect(BrandAssets.paymentMethods, 'assets/brands/payment_methods');
      expect(BrandAssets.tech, 'assets/brands/tech');
    });

    test('path spesifik flag tersedia', () {
      expect(BrandAssets.flagIndonesia, 'assets/brands/flags/indonesia.svg');
      expect(BrandAssets.flagEnglish, 'assets/brands/flags/united_states.svg');
      expect(BrandAssets.flagJapan, 'assets/brands/flags/japan.svg');
    });

    test('path payment populer tersedia', () {
      expect(
        BrandAssets.paymentQris,
        'assets/brands/payment_methods/qris_0.webp',
      );
      expect(
        BrandAssets.paymentSeaBank,
        'assets/brands/payment_methods/seabank.webp',
      );
      expect(
        BrandAssets.paymentGoPay,
        'assets/brands/payment_methods/gopay.svg',
      );
    });
  });

  group('AppLanguages', () {
    test('mendukung bahasa utama', () {
      expect(AppLanguages.supported.length, greaterThanOrEqualTo(6));
      expect(AppLanguages.supported.first.code, 'id');
      expect(AppLanguages.supported.first.flagAsset, BrandAssets.flagIndonesia);
    });

    test('byCode mengembalikan bahasa yang tepat', () {
      expect(AppLanguages.byCode('en').name, 'English');
      expect(AppLanguages.byCode('ja').name, '日本語');
      expect(AppLanguages.byCode('ko').name, '한국어');
    });

    test('byCode fallback ke bahasa pertama untuk kode tidak dikenal', () {
      expect(AppLanguages.byCode('xx').code, 'id');
    });
  });

  group('LanguageSwitcher', () {
    testWidgets('compact mode menampilkan bendera saat ini', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSwitcher(
              currentCode: 'id',
              onChanged: (_) {},
              compact: true,
            ),
          ),
        ),
      );

      expect(find.byType(LanguageSwitcher), findsOneWidget);
    });

    testWidgets('full mode menampilkan semua pilihan bahasa', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSwitcher(
              currentCode: 'id',
              onChanged: (_) {},
              compact: false,
            ),
          ),
        ),
      );

      expect(
        find.byType(ChoiceChip),
        findsNWidgets(AppLanguages.supported.length),
      );
    });
  });
}
