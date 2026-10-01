import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/application/account_operational_metrics.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_invoice_history.dart';
import 'package:void_scriptor/features/account/domain/account_center_localization_formatting.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/account/presentation/storage_usage_card.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_localization_formatting_validation.dart';

/// 117.26 — drill Localization & Formatting.
///
/// Mengukur delapan area `required_evidence` kanonik (`rtl`,
/// `text_expansion`, `relative_time`, `storage_units`, `percentages`,
/// `currency`, `tax`, `provider_names`) langsung pada teks yang benar-benar
/// dirender dan pada nilai yang benar-benar dihitung kode yang di-ship,
/// lalu menyerahkan faktanya ke gate gagal-tertutup
/// [Sprint117LocalizationValidation].
///
/// Semua cek berdasar nilai yang diukur, bukan deklarasi token. Tidak ada
/// wall clock: setiap waktu yang dihitung berasal dari jam injeksi.

const String _manifestPath =
    'docs/evidence/sprint-117-26-manifest-20261001.json';

final AccountCloudSnapshot _guest = AccountCloudSnapshot.localOnly(
  session: const AuthSession.guest(),
);

const AccountOperationalMetrics _metrics = AccountOperationalMetrics(
  promptTokens: 1200,
  completionTokens: 340,
  estimatedCost: 1.25,
  totalStorageBytes: 4096,
  storageBytesByCategory: {'Images': 3072, 'Database': 1024},
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
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
              snapshot: _guest,
              operationalMetrics: withMetrics ? _metrics : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _drain(WidgetTester tester) {
  final collected = <String>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    collected.add(error.toString().split('\n').first);
  }
  return collected.isEmpty ? 'none' : collected.join(' | ');
}

List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .toList();

Sprint117LocalizationCheck _boolCheck({
  required String area,
  required String check,
  required bool ok,
  required String declared,
  required String observed,
  String note = '',
}) => ok
    ? Sprint117LocalizationCheck.pass(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      )
    : Sprint117LocalizationCheck.violation(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      );

/// Bentuk yang harus dicetak kontrak, apa adanya.
Sprint117LocalizationCheck _shapeCheck({
  required String area,
  required String check,
  required String rendered,
  required String pattern,
  String note = '',
}) => _boolCheck(
  area: area,
  check: check,
  ok: RegExp(pattern).hasMatch(rendered),
  declared: 'teks cocok $pattern',
  observed: rendered.isEmpty ? 'tidak ada teks' : rendered,
  note: note,
);

void main() {
  group('117.26 localization & formatting validation', () {
    testWidgets('gate passes on facts measured from the shipped screen', (
      tester,
    ) async {
      final checks = <Sprint117LocalizationCheck>[];

      // ============================================================
      // 1. RTL
      // ============================================================
      await _pump(tester, const Size(1536, 1024));
      final ltrNav = tester.getRect(
        find.byKey(const ValueKey('account-center-left-navigation')),
      );
      final ltrGrid = tester.getRect(
        find.byKey(const ValueKey('account-center-main-grid')),
      );
      final ltrRail = tester.getRect(
        find.byKey(const ValueKey('account-center-right-rail')),
      );
      await _pump(tester, const Size(1536, 1024), direction: TextDirection.rtl);
      final rtlException = _drain(tester);
      final rtlNav = tester.getRect(
        find.byKey(const ValueKey('account-center-left-navigation')),
      );
      final rtlGrid = tester.getRect(
        find.byKey(const ValueKey('account-center-main-grid')),
      );
      final rtlRail = tester.getRect(
        find.byKey(const ValueKey('account-center-right-rail')),
      );

      checks.add(
        _boolCheck(
          area: 'rtl',
          check: 'bands_mirror_on_ambient_rtl',
          ok:
              ltrNav.left < ltrGrid.left &&
              ltrRail.left > ltrGrid.left &&
              rtlNav.left > rtlGrid.left &&
              rtlRail.left < rtlGrid.left,
          declared:
              'nav+rail bertukar sisi pada ambient RTL tanpa crash (exc=$rtlException)',
          observed:
              'LTR nav=${ltrNav.left.toStringAsFixed(1)} grid=${ltrGrid.left.toStringAsFixed(1)} rail=${ltrRail.left.toStringAsFixed(1)} | '
              'RTL nav=${rtlNav.left.toStringAsFixed(1)} grid=${rtlGrid.left.toStringAsFixed(1)} rail=${rtlRail.left.toStringAsFixed(1)}',
          note: '115.49 ambient Directionality mirroring',
        ),
      );

      checks.add(
        _boolCheck(
          area: 'rtl',
          check: 'outer_edges_mirror_symmetrically',
          ok:
              (rtlNav.right - tester.view.physicalSize.width + ltrNav.left)
                      .abs() <
                  0.01 &&
              (rtlRail.left - tester.view.physicalSize.width + ltrRail.right)
                      .abs() <
                  0.01,
          declared:
              'tepi luar nav dan rail mencerminkan LTR dengan padding yang sama',
          observed:
              'navOff=${(rtlNav.right - tester.view.physicalSize.width + ltrNav.left).toStringAsFixed(2)} '
              'railOff=${(rtlRail.left - tester.view.physicalSize.width + ltrRail.right).toStringAsFixed(2)}',
        ),
      );

      // ============================================================
      // 2. TEXT_EXPANSION
      // ============================================================
      final expansionSamples = <String>[];
      var expansionCrashes = 0;
      for (final size in const <Size>[Size(1536, 1024), Size(390, 844)]) {
        await _pump(tester, size, textScale: 2.0, withMetrics: true);
        final exception = _drain(tester);
        if (exception != 'none') expansionCrashes++;
        final rendered = _renderedText(tester);
        expansionSamples.add(
          '${size.width.toInt()}x${size.height.toInt()}:${rendered.length} teks',
        );
        final missing = <String>[
          for (final tab in AccountCenterInformationArchitecture.tabs)
            if (find.text(tab.label, skipOffstage: false).evaluate().isEmpty)
              tab.label,
        ];
        checks.add(
          _boolCheck(
            area: 'text_expansion',
            check: 'tab_labels_survive_200_percent_${size.width.toInt()}',
            ok: missing.isEmpty && exception == 'none',
            declared:
                'seluruh label tab tetap dirender pada teks 200% tanpa crash',
            observed: missing.isEmpty
                ? '${AccountCenterInformationArchitecture.tabs.length}/${AccountCenterInformationArchitecture.tabs.length} label utuh (exc=$exception)'
                : 'hilang: ${missing.join(', ')} (exc=$exception)',
            note: 'WCAG 1.4.4',
          ),
        );
        // Setiap string yang benar-benar dirender harus bebas karakter
        // non-wrappable; karakter itu menahan baris sehingga teks panjang
        // terpotong alih-alih membungkus.
        var nonWrappable = <String>[];
        for (final value in rendered) {
          try {
            AccountCenterLocalizationFormatting.requireWrappable(value);
          } on ArgumentError catch (error) {
            nonWrappable.add(error.message.toString());
          }
        }
        checks.add(
          _boolCheck(
            area: 'text_expansion',
            check: 'rendered_text_wrappable_${size.width.toInt()}',
            ok: nonWrappable.isEmpty,
            declared: 'semua teks yang dirender bebas karakter non-wrappable',
            observed: nonWrappable.isEmpty
                ? '${rendered.length} teks bersih'
                : '${nonWrappable.length} bermasalah: ${nonWrappable.take(3).join(' | ')}',
            note: '115.49 text_expansion contract',
          ),
        );
      }

      checks.add(
        _boolCheck(
          area: 'text_expansion',
          check: 'no_unhandled_crash_under_200_percent',
          ok: expansionCrashes == 0,
          declared: 'nol crash unhandled pada kedua viewport pada teks 200%',
          observed: '$expansionCrashes/2 viewport crash',
          note: expansionSamples.join(' '),
        ),
      );

      // ============================================================
      // 3. RELATIVE_TIME
      // ============================================================
      final now = DateTime.utc(2026, 10, 1, 12);
      final relative = <String, String>{
        for (final offset in const <Duration>[
          Duration(seconds: 30),
          Duration(minutes: 1),
          Duration(minutes: 59),
          Duration(hours: 1),
          Duration(hours: 23),
          Duration(days: 1),
          Duration(days: 6),
          Duration(days: 7),
          Duration(days: 400),
        ])
          '${offset.inSeconds}s':
              AccountCenterLocalizationFormatting.relativeTime(
                now: now,
                moment: now.subtract(offset),
              ),
      };

      // Batas menit: 60 detik pertama = "just now", bukan "0 minutes ago".
      // Menit ke-1 harus "1 minute ago" (tunggal), bukan jam/bulan.
      checks.add(
        _boolCheck(
          area: 'relative_time',
          check: 'sub_minute_is_just_now',
          ok: relative['30s'] == 'just now',
          declared: 'selisih di bawah 60 detik dirender "just now"',
          observed: relative['30s'] ?? 'tidak dihitung',
          note: '115.49 relative_time; jam injeksi, tanpa wall clock',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'relative_time',
          check: 'singular_plural_agrees',
          ok:
              relative['60s'] == '1 minute ago' &&
              relative['3540s'] == '59 minutes ago' &&
              relative['3600s'] == '1 hour ago' &&
              relative['82800s'] == '23 hours ago' &&
              relative['86400s'] == '1 day ago',
          declared: 'jam dan hari memakai bentuk tunggal jamur yang benar',
          observed: relative.entries
              .where((entry) => entry.key.endsWith('60s'))
              .map((entry) => '${entry.key}=${entry.value}')
              .join(' '),
          note: 'label relatif harus cocok dengan instantsa yang diukur',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'relative_time',
          check: 'beyond_week_falls_back_to_absolute_date',
          ok:
              relative['604800s'] == 'on 2026-09-24' &&
              relative['34560000s'] == 'on 2025-08-27',
          declared:
              'selisih di atas 7 hari jatuh ke tanggal absolut, bukan hari yang terus bertambah',
          observed: '7d=${relative['604800s']} 400d=${relative['34560000s']}',
          note: 'tidak boleh ada penghitung hari yang tumbuh tanpa batas',
        ),
      );
      var futureRejected = false;
      try {
        AccountCenterLocalizationFormatting.relativeTime(
          now: now,
          moment: now.add(const Duration(minutes: 1)),
        );
      } on ArgumentError {
        futureRejected = true;
      }
      checks.add(
        _boolCheck(
          area: 'relative_time',
          check: 'future_timestamp_rejected',
          ok: futureRejected,
          declared: 'timestamp masa depan ditolak, bukan dirender ke belakang',
          observed: futureRejected
              ? 'ArgumentError'
              : 'diterima sebagai masa lalu',
        ),
      );

      // ============================================================
      // 4. STORAGE_UNITS
      // ============================================================
      final storage = <int, String>{
        for (final bytes in const <int>[
          0,
          999,
          1000,
          1500,
          4096,
          999999,
          1000000,
          1500000000,
          1000000000000,
        ])
          bytes: AccountCenterLocalizationFormatting.storageUnits(bytes),
      };

      checks.add(
        _boolCheck(
          area: 'storage_units',
          check: 'decimal_units_not_binary',
          ok:
              storage[4096] == '4.1 KB' &&
              storage[1000000] == '1 MB' &&
              storage[1500000000] == '1.5 GB' &&
              storage[1000000000000] == '1 TB',
          declared: 'satuan desimal (1000), bukan biner (1024)',
          observed: storage.entries
              .where((entry) => entry.key >= 4096)
              .map((entry) => '${entry.key}B=${entry.value}')
              .join(' '),
          note: 'nilai biner di bawah label GB adalah kebohongan pembulatan',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'storage_units',
          check: 'no_invented_precision',
          ok:
              storage[1000] == '1 KB' &&
              storage[999] == '999 B' &&
              storage[1000000] == '1 MB',
          declared: 'nol nol di belakang yang mengarang presisi',
          observed:
              '999B=${storage[999]} 1000B=${storage[1000]} 1e6B=${storage[1000000]}',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'storage_units',
          check: 'negative_bytes_report_unavailable',
          ok:
              AccountCenterLocalizationFormatting.storageUnits(-1) ==
              'unavailable',
          declared:
              'ukuran negatif melaporkan "unavailable", bukan angka karangan',
          observed: AccountCenterLocalizationFormatting.storageUnits(-1),
        ),
      );

      // Widget kartu storage yang benar-benar dirender harus memakai satuan
      // kontrak yang sama — bukan formatter privat.
      //
      // Diperiksa pada widget-nya sendiri dengan data nyata, karena di layar
      // overview kartu itu dirender tanpa data (`data: null`) sehingga
      // formatter privatnya tidak pernah ikut dipanggil di sana.
      final cardData = StorageUsageCardData.fromBytes(
        providerId: 'google_drive',
        accountLabel: 'Choi Drive',
        usedBytes: 4096,
        quotaBytes: 8192,
        measuredAt: DateTime.utc(2026, 10, 1, 10),
        now: DateTime.utc(2026, 10, 1, 11),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: StorageUsageCard(data: cardData)),
          ),
        ),
      );
      await tester.pump();
      final renderedCardText = _renderedText(tester);
      final cardBytesLine = renderedCardText.firstWhere(
        (value) => value.endsWith(' used'),
        orElse: () => '',
      );
      checks.add(
        _boolCheck(
          area: 'storage_units',
          check: 'rendered_card_uses_contract_units',
          ok:
              renderedCardText.any((value) => value == '4.1 KB used') &&
              !renderedCardText.any((value) => value == '4 KB used'),
          declared:
              'kartu yang dirender memakai satuan desimal kontrak, bukan formatter privat 1024',
          observed: cardBytesLine.isEmpty
              ? 'baris "used" tidak dirender'
              : renderedCardText
                    .where((value) => value.contains('used'))
                    .join(' | '),
          note:
              'StorageUsageCard._formatBytes memakai 1024 di bawah label KB desimal',
        ),
      );

      // ============================================================
      // 5. PERCENTAGES
      // ============================================================
      await _pump(tester, const Size(1536, 1024), withMetrics: true);
      final renderedMetrics = _renderedText(tester);
      final renderedShares = renderedMetrics
          .where((value) => value.contains('%'))
          .toList();

      checks.add(
        _boolCheck(
          area: 'percentages',
          check: 'share_percent_is_rounded_whole_within_range',
          ok:
              AccountCenterLocalizationFormatting.sharePercent(1024, 4096) ==
                  25 &&
              AccountCenterLocalizationFormatting.sharePercent(3072, 4096) ==
                  75 &&
              AccountCenterLocalizationFormatting.sharePercent(1, 3) == 33,
          declared: 'bagian dihitung sebagai persen bulat di dalam 0..100',
          observed:
              '1024/4096=${AccountCenterLocalizationFormatting.sharePercent(1024, 4096)} '
              '3072/4096=${AccountCenterLocalizationFormatting.sharePercent(3072, 4096)} '
              '1/3=${AccountCenterLocalizationFormatting.sharePercent(1, 3)}',
        ),
      );
      var outOfRangeRejected = false;
      try {
        AccountCenterLocalizationFormatting.percentLabel(101);
      } on ArgumentError {
        outOfRangeRejected = true;
      }
      checks.add(
        _boolCheck(
          area: 'percentages',
          check: 'percent_label_rejects_out_of_range',
          ok: outOfRangeRejected,
          declared: 'label persen menolak nilai di luar 0..100',
          observed: outOfRangeRejected ? 'ArgumentError' : '101% diterima',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'percentages',
          check: 'rendered_shares_match_measured_data',
          ok:
              renderedShares.any((value) => value.contains('Images 75%')) &&
              renderedShares.any((value) => value.contains('Database 25%')),
          declared: 'persen yang tampil berasal dari data terukur (75% / 25%)',
          observed: renderedShares.isEmpty
              ? 'tidak ada teks persen yang dirender'
              : renderedShares.join(' | '),
        ),
      );
      checks.add(
        _boolCheck(
          area: 'percentages',
          check: 'progress_ratio_never_exceeds_one',
          ok: _progressRatioNeverExceedsOne(),
          declared:
              'rasio progress bar untuk setiap usage<=quota tetap di dalam 0..1',
          observed: _progressRatioNeverExceedsOne() ? '0..1' : 'di luar 0..1',
          note: 'LinearProgressIndicator menolak nilai di luar rentang',
        ),
      );

      // ============================================================
      // 6. CURRENCY
      // ============================================================
      final currencyFacts = <String>[];
      for (final entry in <({double amount, String code})>[
        (amount: 1.25, code: 'usd'),
        (amount: 0.5, code: 'EUR'),
        (amount: 1234.5, code: 'IDR'),
      ]) {
        currencyFacts.add(
          AccountCenterLocalizationFormatting.formatCurrency(
            amount: entry.amount,
            currencyCode: entry.code,
          ),
        );
      }
      checks.add(
        _boolCheck(
          area: 'currency',
          check: 'currency_string_carries_explicit_code',
          ok: currencyFacts.every(
            (value) => RegExp(r'^\S+ [A-Za-z]{3}$').hasMatch(value),
          ),
          declared: 'setiap string uang membawa kode tiga huruf yang eksplisit',
          observed: currencyFacts.join(' | '),
          note: 'simbol telanjang adalah klaim mata uang tanpa label',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'currency',
          check: 'amount_never_invents_precision',
          ok:
              AccountCenterLocalizationFormatting.formatAmount(2.0) == '2' &&
              AccountCenterLocalizationFormatting.formatAmount(1.25) ==
                  '1.25' &&
              AccountCenterLocalizationFormatting.formatMoney(1.25) == '1.25',
          declared:
              'jumlah bulat tanpa desimal, jumlah pecatan tanpa ekor nol karangan',
          observed:
              '2.0=${AccountCenterLocalizationFormatting.formatAmount(2.0)} '
              '1.25=${AccountCenterLocalizationFormatting.formatAmount(1.25)}',
        ),
      );

      // Letak yang benar-benar dirender: kartu AI Usage.
      //
      // Dipilih lewat baris yang memuat angka token, bukan teks pertama
      // yang memuat kata "estimated" — subtitle kartu juga memuatnya. Angka
      // yang diuji adalah angka SETELAH penanda mata uang, bukan angka
      // pertama di baris (itu jumlah token).
      final renderedCostLine = _renderedText(tester).firstWhere(
        (value) => value.contains('tokens') && value.contains('estimated'),
        orElse: () => '',
      );
      final costAmount = RegExp(
        r'(\$\s*([-\d.,]+)|([A-Z]{3})\s*([-\d.,]+))',
      ).firstMatch(renderedCostLine);
      checks.add(
        _boolCheck(
          area: 'currency',
          check: 'rendered_cost_carries_currency_marker',
          ok: costAmount != null,
          declared:
              'baris biaya yang dirender menyatakan penanda mata uang tepat sebelum angkanya',
          observed: renderedCostLine.isEmpty
              ? 'baris biaya tidak dirender'
              : renderedCostLine.replaceAll('\n', ' '),
          note:
              'penanda yang ditemukan: ${costAmount?.group(1) ?? 'tidak ada'}',
        ),
      );
      // Gap yang diukur, bukan violation: baris `AiUsageLog` tidak membawa
      // kolom mata uang, jadi penanda di chrome adalah asumsi, bukan
      // pembacaan. Dilaporkan terbuka supaya tidak dibaca sebagai fakta.
      checks.add(
        Sprint117LocalizationCheck.unmet(
          area: 'currency',
          check: 'cost_currency_measured_from_source_row',
          declared: 'kode mata uang biaya dibaca dari baris usage yang di-ship',
          observed:
              'kolom currency tidak ada di tabel ai_usage_logs; chrome hanya bisa menandai asumsi',
          note:
              'AiUsageLogs (lib/database/project/tables/ai_usage_logs.dart) punya cost tanpa currency',
        ),
      );

      // ============================================================
      // 7. TAX
      // ============================================================
      final taxableInvoice = Invoice(
        invoiceId: 'inv-1',
        number: 'INV-001',
        issuedAt: DateTime.utc(2026, 9, 1),
        currency: 'USD',
        lineItems: <InvoiceLineItem>[
          InvoiceLineItem(
            description: 'Workspace seat',
            quantity: 1,
            unitAmount: 100,
            currency: 'USD',
          ),
        ],
        tax: TaxStatus.applies,
        taxLine: InvoiceTaxLine(label: 'VAT', rate: 20, regionCode: 'GB'),
        status: InvoiceStatus.open,
        total: 120,
      );
      checks.add(
        _shapeCheck(
          area: 'tax',
          check: 'tax_line_keeps_region_and_rate',
          rendered: taxableInvoice.taxInformation,
          pattern: r'^VAT 20\.00% \(GB\)$',
          note: '115.49 taxDisplay menerima baris "<label> NN.NN% (<region>)"',
        ),
      );
      final taxTokens = <String, String>{
        for (final token in const <String>['not_applicable', 'unavailable'])
          token: AccountCenterLocalizationFormatting.taxDisplay(token),
      };
      checks.add(
        _boolCheck(
          area: 'tax',
          check: 'wire_tax_tokens_never_print_verbatim',
          ok:
              taxTokens['not_applicable'] == 'Not applicable' &&
              taxTokens['unavailable'] == 'Tax unavailable',
          declared: 'token kawat tidak pernah dicetak apa adanya ke UI',
          observed: taxTokens.entries
              .map((entry) => '${entry.key}="${entry.value}"')
              .join(' '),
        ),
      );
      var malformedTaxRejected = false;
      try {
        AccountCenterLocalizationFormatting.taxDisplay('20 percent maybe');
      } on ArgumentError {
        malformedTaxRejected = true;
      }
      checks.add(
        _boolCheck(
          area: 'tax',
          check: 'malformed_tax_line_rejected',
          ok: malformedTaxRejected,
          declared:
              'baris tax yang tidak berbentuk kanonik ditolak, bukan dirender bebas',
          observed: malformedTaxRejected
              ? 'ArgumentError'
              : 'diterima sebagai teks',
        ),
      );

      // ============================================================
      // 8. PROVIDER_NAMES
      // ============================================================
      await _pump(tester, const Size(1536, 1024));
      final manifest = ProviderConnectorManifest.standard;
      final visibleNames = _renderedText(tester).toSet();
      final manifestNames = manifest.all
          .map((entry) => entry.displayName)
          .toList(growable: false);
      final visibleManifestNames = manifestNames
          .where(visibleNames.contains)
          .toList(growable: false);

      checks.add(
        _boolCheck(
          area: 'provider_names',
          check: 'display_names_are_whitespace_normalized',
          ok:
              manifestNames.every((name) => name == name.trim()) &&
              manifestNames.every((name) => !RegExp(r'\s{2,}').hasMatch(name)),
          declared:
              'nama tampilan provider dinormalkan (dipangkas, spasi dalam dirapatkan)',
          observed:
              '${manifestNames.length} nama diperiksa, ${manifestNames.where((name) => name != name.trim() || RegExp(r'\s{2,}').hasMatch(name)).length} tidak normal',
          note: '115.49 providerDisplayName',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'provider_names',
          check: 'rendered_names_never_expose_raw_provider_id',
          ok:
              visibleNames.every(
                (name) => !RegExp(r'\b[a-z]+_[a-z_]+\b').hasMatch(name),
              ) &&
              manifest.all.every(
                (entry) => !visibleNames.contains(entry.providerId),
              ),
          declared:
              'nama yang dirender tidak pernah menampilkan id mentah provider',
          observed:
              '${visibleManifestNames.length} nama manifest tampil; '
              'id mentah yang bocor: '
              '${manifest.all.where((entry) => visibleNames.contains(entry.providerId)).map((entry) => entry.providerId).join(', ')}',
          note:
              'id mesin seperti openai_chat harus tampil sebagai nama, bukan slug',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'provider_names',
          check: 'blank_display_name_rejected',
          ok: _blankProviderNameRejected(),
          declared:
              'nama tampilan kosong ditolak di sumber, bukan dirender kosong',
          observed: _blankProviderNameRejected()
              ? 'ArgumentError'
              : 'nama kosong diterima',
        ),
      );

      // ============================================================
      // EVALUASI GATE
      // ============================================================
      final result = Sprint117LocalizationValidation.evaluate(checks);
      final dump = checks
          .map(
            (c) =>
                '${c.status.name} ${c.code} declared=${c.declared} '
                'observed=${c.observed}',
          )
          .join('\n');
      expect(result.pass, isTrue, reason: 'failures=${result.failures}\n$dump');
      expect(
        result.checks.map((c) => c.area).toSet(),
        Sprint117LocalizationValidation.requiredAreas.toSet(),
        reason: 'delapan area required_evidence harus terukur',
      );
      expect(
        result.violationCodes,
        isEmpty,
        reason: result.violationCodes.join(', '),
      );

      final writeManifest =
          Platform.environment['SPRINT_117_26_MANIFEST'] == '1';
      if (writeManifest) {
        File(_manifestPath).writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
        );
      }
    });

    test('gate fails closed on structural holes', () {
      List<Sprint117LocalizationCheck> minimal() => [
        for (final area in Sprint117LocalizationValidation.requiredAreas)
          Sprint117LocalizationCheck.pass(
            area: area,
            check: 'probe',
            declared: 'decl',
            observed: 'obs',
          ),
      ];

      expect(
        Sprint117LocalizationValidation.evaluate(const []).pass,
        isFalse,
        reason: 'no_checks',
      );
      expect(
        Sprint117LocalizationValidation.evaluate(minimal()).pass,
        isTrue,
        reason: 'minimal 8 pass',
      );

      final withoutTax = minimal().where((c) => c.area != 'tax').toList();
      final resMissing = Sprint117LocalizationValidation.evaluate(withoutTax);
      expect(resMissing.pass, isFalse);
      expect(resMissing.failures, contains('missing_area:tax'));

      final withUnknown = [
        ...minimal(),
        Sprint117LocalizationCheck.pass(
          area: 'color_contrast',
          check: 'foo',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resUnknown = Sprint117LocalizationValidation.evaluate(withUnknown);
      expect(resUnknown.pass, isFalse);
      expect(resUnknown.failures, contains('unknown_area:color_contrast'));

      final withDup = [
        ...minimal(),
        Sprint117LocalizationCheck.pass(
          area: 'rtl',
          check: 'probe',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resDup = Sprint117LocalizationValidation.evaluate(withDup);
      expect(resDup.pass, isFalse);
      expect(resDup.failures, contains('duplicate_check:rtl:probe'));

      final withVac = [
        for (final c in minimal())
          if (c.area == 'rtl')
            Sprint117LocalizationCheck.pass(
              area: 'rtl',
              check: 'probe',
              declared: '  ',
              observed: '',
            )
          else
            c,
      ];
      final resVac = Sprint117LocalizationValidation.evaluate(withVac);
      expect(resVac.pass, isFalse);
      expect(
        resVac.failures,
        containsAll(['vacuous_declared:rtl:probe', 'vacuous:rtl:probe']),
      );

      final withoutPass = [
        for (final c in minimal())
          if (c.area == 'rtl')
            Sprint117LocalizationCheck.unmet(
              area: 'rtl',
              check: 'probe',
              declared: 'd',
              observed: 'o',
            )
          else
            c,
      ];
      final resNoPass = Sprint117LocalizationValidation.evaluate(withoutPass);
      expect(resNoPass.pass, isFalse);
      expect(resNoPass.failures, contains('area_without_pass:rtl'));

      final withViolation = [
        ...minimal(),
        Sprint117LocalizationCheck.violation(
          area: 'rtl',
          check: 'bad',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resViol = Sprint117LocalizationValidation.evaluate(withViolation);
      expect(resViol.pass, isFalse);
      expect(resViol.failures, contains('violation:rtl:bad'));
    });
  });
}

bool _progressRatioNeverExceedsOne() {
  for (final pair in const <({int used, int quota})>[
    (used: 0, quota: 100),
    (used: 100, quota: 100),
    (used: 250, quota: 1000),
    (used: 1, quota: 3),
  ]) {
    final data = StorageUsageCardData.fromBytes(
      providerId: 'probe',
      accountLabel: 'Probe',
      usedBytes: pair.used,
      quotaBytes: pair.quota,
      measuredAt: DateTime.utc(2026, 10, 1, 10),
      now: DateTime.utc(2026, 10, 1, 11),
    );
    final ratio = data.percentage;
    if (ratio == null || ratio < 0 || ratio > 1) return false;
  }
  return true;
}

bool _blankProviderNameRejected() {
  try {
    ProviderConnectorEntry.fixture('probe_blank_name', displayName: '   ');
  } on ArgumentError {
    return true;
  }
  return false;
}
