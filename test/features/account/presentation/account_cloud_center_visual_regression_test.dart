/// Sprint 115.52 — Visual Regression Matrix (presentation).
///
/// Runs the live Account & Cloud Center chrome through the canonical matrix
/// of step 115.52 and proves the defects the matrix is chartered to catch:
///
/// * every canonical reference viewport (1536x1024, 1440, 1180, 900, 600,
///   mobile) renders without an overflow or layout exception;
/// * every Void theme family repaints the chrome — the screen reads its ink
///   from `context.palette`, so a hardcoded dark colour would leave the
///   scaffold background on the default palette;
/// * 200% text expansion keeps the 44px touch target and does not overflow;
/// * long provider labels ellipsize instead of forcing a RenderFlex overflow;
/// * a provider id with no bundled mark falls back to a generic icon with a
///   spoken "icon unavailable" name instead of a broken image;
/// * loading and error states of the operational-metrics provider render real
///   text and never throw;
/// * a snapshot whose service list omits `email-sign-in` degrades to "not
///   connected" instead of throwing `StateError: Bad state: No element`.
///
/// PITFALL (measured on this step): `MaterialApp` animates a theme swap, so a
/// loop that pumps only once reads the PREVIOUS theme's scaffold background.
/// Every theme assertion here settles the frame first.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import 'package:void_scriptor/design_system/theme/void_theme.dart';
import 'package:void_scriptor/design_system/theme/void_theme_presets.dart';
import 'package:void_scriptor/features/account/application/account_operational_metrics.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/domain/account_center_accessibility.dart';
import 'package:void_scriptor/features/account/domain/account_center_design_tokens.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_visual_regression_matrix.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

void main() {
  final guest = AccountCloudSnapshot.localOnly(
    session: const AuthSession.guest(),
  );

  Finder byKey(String key) => find.byKey(ValueKey(key));

  Future<void> pumpCenter(
    WidgetTester tester, {
    required Size size,
    ThemeData? theme,
    TextScaler scaler = TextScaler.noScaling,
    AccountCloudSnapshot? snapshot,
    ProviderConnectorManifest? manifest,
    ValueChanged<ProviderConnectorEntry>? onConnectProvider,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme ?? VoidTheme.dark,
          // PITFALL yang diukur pada step ini: `scaler` yang hanya diterima
          // helper tetapi tidak dipasang ke pohon widget membuat sel
          // `200_percent_scale`assert pada skala 1.0 —.matrix jadi stempel
          // kosong. `MediaQuery`-lah satu-satunya cara menyuntikkan
          // `TextScaler` ke seluruh subtree tanpa menyentuh chrome.
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: AccountCloudCenterScreen(
              snapshot: snapshot ?? guest,
              providerManifest: manifest,
              onConnectProvider: onConnectProvider,
              operationalMetrics: const AccountOperationalMetrics(
                promptTokens: 1200,
                completionTokens: 340,
                estimatedCost: 1.25,
                totalStorageBytes: 4096,
                storageBytesByCategory: {'Manuscripts': 4096},
              ),
            ),
          ),
        ),
      ),
    );
    // Wajib: MaterialApp menganimasikan perpindahan tema, jadi satu `pump`
    // masih membaca tema SEBELUMNYA.
    await tester.pumpAndSettle();
  }

  group('115.52 reference viewports', () {
    testWidgets('every canonical viewport renders without an exception', (
      tester,
    ) async {
      for (final cell in AccountCenterVisualRegressionMatrix.sizeCells) {
        final size = AccountCenterVisualRegressionMatrix.viewportFor(cell);
        await pumpCenter(tester, size: size);
        expect(
          tester.takeException(),
          isNull,
          reason: 'cell $cell at $size must render without an exception',
        );
        expect(
          find.text('ACCOUNT & CLOUD CENTER'),
          findsWidgets,
          reason: 'cell $cell must still render the page',
        );
      }
    });

    testWidgets('each viewport keeps its own responsive chrome', (
      tester,
    ) async {
      // wide_desktop (>=1440) memakai frame 115.45; 600-1439 memakai chrome
      // adaptif 115.46; <600 memakai chrome mobile 115.47. Matriks visual
      // harus menjangkau keenam ukuran dan masing-masing memilih chrome-nya.
      const expectedChrome = <String, List<String>>{
        '1536x1024': ['account-center-left-navigation'],
        '1440': ['account-center-left-navigation'],
        '1180': ['account-center-desktop-left-navigation'],
        '900': ['account-center-collapsed-rail'],
        '600': ['account-center-top-navigation'],
        'mobile': ['account-center-mobile-layout'],
      };
      for (final entry in expectedChrome.entries) {
        final size = AccountCenterVisualRegressionMatrix.viewportFor(entry.key);
        await pumpCenter(tester, size: size);
        for (final key in entry.value) {
          expect(byKey(key), findsOneWidget, reason: '${entry.key} needs $key');
        }
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });
  });

  group('115.52 themes', () {
    testWidgets('every Void theme family repaints the chrome surface', (
      tester,
    ) async {
      final families = <(String, VoidPalette)>[
        ('ink', VoidThemePresets.darkInk),
        ('ink', VoidThemePresets.lightInk),
        ('ember', VoidThemePresets.darkEmber),
        ('ember', VoidThemePresets.lightEmber),
        ('sage', VoidThemePresets.darkSage),
        ('sage', VoidThemePresets.lightSage),
        ('rose', VoidThemePresets.darkRose),
        ('rose', VoidThemePresets.lightRose),
        ('ocean', VoidThemePresets.darkOcean),
        ('ocean', VoidThemePresets.lightOcean),
      ];
      for (final family in families) {
        final theme = family.$2 == VoidThemePresets.darkInk
            ? VoidTheme.buildDark(family.$2)
            : family.$2 == VoidThemePresets.lightInk
            ? VoidTheme.buildLight(family.$2)
            : _themeFor(family.$2);
        await pumpCenter(tester, size: const Size(1536, 1024), theme: theme);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(
          scaffold.backgroundColor,
          family.$2.background,
          reason:
              'tema ${family.$1} harus mewarnai Scaffold lewat '
              'context.palette, bukan palet default',
        );
        expect(tester.takeException(), isNull, reason: family.$1);
      }
    });
  });

  group('115.52 scaling and long text', () {
    testWidgets('200 percent text expansion keeps the touch target', (
      tester,
    ) async {
      await pumpCenter(
        tester,
        size: const Size(1536, 1024),
        scaler: const TextScaler.linear(2),
      );
      final button = find.widgetWithText(
        OutlinedButton,
        '+ Add Another Method',
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(
          AccountCenterDesignTokens.density.minimumTouchTarget,
        ),
        reason: 'target sentuh harus tetap 44px pada skala 200%',
      );
      expect(
        AccountCenterAccessibility.maximumSupportedTextScale,
        2.0,
        reason:
            'skala yang diuji adalah batas atas yang didukung kontrak 115.7',
      );
      // Penjaga: tanpa ini, sel ini tetap hijau walau `scaler` berhenti
      // diteruskan ke pohon widget — helper yang menerima parameter lalu
      // membuangnya menghasilkan matrix yang berbohong. Membaca
      // `MediaQuery` dari dalam subtree chrome membuktikan skala yang diuji
      // benar-benar yang berlaku saat render, bukan sekadar konstanta 2.0.
      final applied = MediaQuery.of(
        tester.element(find.text('ACCOUNT & CLOUD CENTER').first),
      );
      expect(
        applied.textScaler.scale(10),
        20,
        reason:
            'TextScaler.linear(2) harus benar-benar sampai ke subtree '
            'chrome; 10 * 2 = 20',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('long provider labels ellipsize instead of overflowing', (
      tester,
    ) async {
      final long = AccountCloudSnapshot(
        accountModeLabel:
            'Connected account with a very long session label that will not fit',
        accountDisplayName:
            'A. Very. Long. Display. Name. That. Should. Ellipsize. Gracefully',
        accountEmail:
            'a.very.long.address@an-extremely-long-domain.example.invalid',
        services: [
          for (final service in guest.services)
            AccountCloudService(
              id: service.id,
              label:
                  '${service.label} Enterprise Workspace Sync Connector Long',
              group: service.group,
              state: service.state,
              description:
                  'A deliberately long description that keeps going and going '
                  'so the tile must ellipsize instead of overflowing its row.',
            ),
        ],
      );
      for (final size in const [Size(1536, 1024), Size(390, 844)]) {
        await pumpCenter(tester, size: size, snapshot: long);
        expect(
          tester.takeException(),
          isNull,
          reason: 'teks panjang harus ellipsize pada $size',
        );
      }
    });
  });

  group('115.52 missing icon', () {
    testWidgets('an unbundled provider id falls back to a generic icon', (
      tester,
    ) async {
      // `mega` TERDAFTAR di registry ikon 115.8 tetapi mark-nya sengaja
      // TIDAK dibundel (generic), jadi kasus ini persis "official asset is
      // unavailable" yang diminta spec provider_icon_policy — bukan id asing
      // yang tidak dikenal sama sekali.
      const unbundledProviderId = 'mega';
      final icon = ProviderIconRegistry.standard.resolve(unbundledProviderId);
      expect(
        icon.hasBundledAsset,
        isFalse,
        reason:
            'prekondisi: mega terdaftar tanpa mark resmi yang boleh dipakai',
      );
      expect(
        icon.accessibleName,
        'Mega icon unavailable',
        reason: 'nama yang diucapkan harus jujur bahwa mark tidak dibundel',
      );

      final manifest = ProviderConnectorManifest.fromJsonString(
        jsonEncode(<String, Object?>{
          'schema_version': 1,
          'entries': [
            for (final entry in ProviderConnectorManifest.standard.all)
              <String, Object?>{
                ...entry.toJson(),
                // Entry tanpa mark resmi dinaikkan ke AVAILABLE supaya
                // tile-nya benar-benar dirender, bukan hanya ada di data.
                if (entry.providerId ==
                    unbundledProviderId) ...<String, Object?>{
                  'capabilities': ['storage'],
                  'availability': 'AVAILABLE',
                },
              },
          ],
        }),
      );
      await pumpCenter(
        tester,
        size: const Size(1536, 1024),
        manifest: manifest,
        onConnectProvider: (_) {},
      );

      // Node Semantics ikon memakai nama aksesibel yang sama, jadi pengguna
      // pembaca layar mendengar fallback, bukan logo yang gagal dimuat.
      expect(find.bySemanticsLabel('Mega icon unavailable'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('117.22 dark-surface brand legibility', () {
    // DIAG terukur pada slice ini: tile provider yang benar-benar dirender di
    // overview adalah lima entri cloud storage (Google Drive, OneDrive,
    // Dropbox, Mega, Local storage). Provider AI seperti Anthropic TIDAK
    // dirender di surface ini, jadi test memakai Dropbox sebagai bukti nyata
    // bahwa perilaku dark-surface benar-benar terjadi di widget.
    testWidgets('a light-ink mark still renders its real asset on dark', (
      tester,
    ) async {
      // dropbox_0.webp adalah 96.3% tinta terang (p50 luminansi 0.9401),
      // sehingga mark-nya tetap terbaca di surface gelap dan TIDAK boleh
      // digantikan glyph generik.
      final dropbox = ProviderIconRegistry.standard.require('dropbox');
      expect(dropbox.supportsDarkSurface, isTrue);
      expect(dropbox.themeVariants, <String>['light', 'dark']);
      expect(dropbox.intrinsicSize!.width, 768);
      expect(dropbox.intrinsicSize!.height, 768);

      await pumpCenter(
        tester,
        size: const Size(1536, 1024),
        theme: VoidTheme.dark,
      );

      // Di gelap: mark asli tetap dipakai, bukan fallback.
      expect(find.bySemanticsLabel('Dropbox icon'), findsWidgets);
      expect(find.bySemanticsLabel('Dropbox icon unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unbundled provider announces absence on the dark theme', (
      tester,
    ) async {
      // mega TIDAK punya mark resmi yang boleh dibundel, jadi pada KEDUA
      // theme nama aksesibelnya harus jujur berbunyi "icon unavailable".
      final mega = ProviderIconRegistry.standard.require('mega');
      expect(mega.hasBundledAsset, isFalse);

      await pumpCenter(
        tester,
        size: const Size(1536, 1024),
        theme: VoidTheme.dark,
      );
      expect(find.bySemanticsLabel('Mega icon unavailable'), findsWidgets);
      expect(find.bySemanticsLabel('Mega icon'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the same light-ink mark renders its asset on the light theme',
      (tester) async {
        // Resolve untuk surface terang tidak boleh menurunkan mark apa pun:
        // setiap mark minimal harus usable di surface terang.
        await pumpCenter(
          tester,
          size: const Size(1536, 1024),
          theme: VoidTheme.light,
        );
        expect(find.bySemanticsLabel('Dropbox icon'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('115.52 loading and error states', () {
    testWidgets('a pending metrics provider shows the loading copy', (
      tester,
    ) async {
      final pending = Completer<AccountOperationalMetrics?>();
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountOperationalMetricsProvider.overrideWith(
              (ref) => pending.future,
            ),
          ],
          child: MaterialApp(
            theme: VoidTheme.dark,
            home: const AccountCloudCenterScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Loading usage from the active project...'),
        findsOneWidget,
      );
      expect(
        find.text('Indexing storage for the active project...'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a failing metrics provider shows the error copy, not a crash',
      (tester) async {
        tester.view.physicalSize = const Size(1536, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              accountOperationalMetricsProvider.overrideWith(
                (ref) async => throw StateError('probe database unavailable'),
              ),
            ],
            child: MaterialApp(
              theme: VoidTheme.dark,
              home: const AccountCloudCenterScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.textContaining('Could not read active project metrics'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('115.52 degraded snapshot', () {
    testWidgets('a snapshot without email-sign-in renders as not connected', (
      tester,
    ) async {
      // TEMUAN slice ini: chrome menanyakan `snapshot.service('email-sign-in')`
      // di tiga tempat (kartu AUTHENTICATION, kartu rail, dan penentu plan)
      // memakai `firstWhere` tanpa `orElse`, jadi snapshot yang tidak memuat
      // entri itu melempar `StateError: Bad state: No element` dan seluruh
      // halaman hilang — bukan sekadar badge yang salah.
      final reduced = AccountCloudSnapshot(
        accountModeLabel: 'Guest mode',
        accountDisplayName: 'Local user',
        services: const [
          AccountCloudService(
            id: 'google-drive',
            label: 'Google Drive',
            group: AccountCloudServiceGroup.cloudStorage,
            state: AccountCloudConnectionState.notConnected,
            description: 'No Google Drive connection is configured.',
          ),
        ],
      );
      expect(
        reduced.serviceOrNull('email-sign-in'),
        isNull,
        reason: 'prekondisi: entri memang tidak ada di snapshot',
      );

      await pumpCenter(tester, size: const Size(1536, 1024), snapshot: reduced);
      expect(
        tester.takeException(),
        isNull,
        reason: 'snapshot tanpa email-sign-in tidak boleh menjatuhkan halaman',
      );
      expect(find.text('ACCOUNT & CLOUD CENTER'), findsWidgets);
      expect(
        reduced.connectionStateOf('email-sign-in'),
        AccountCloudConnectionState.notConnected,
        reason: 'entri yang tidak ada berarti belum terhubung, bukan error',
      );
    });
  });
}

/// Membangun tema dari palet selain pasangan Void Purple default.
ThemeData _themeFor(VoidPalette palette) =>
    palette.background.computeLuminance() < 0.5
    ? VoidTheme.buildDark(palette)
    : VoidTheme.buildLight(palette);
