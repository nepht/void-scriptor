/// 115.6 — Responsive Grid System.
///
/// Kontrak tunggal resolusi tier + perencanaan kolom grid Account & Cloud
/// Center. Sumber otoritatif perilaku breakpoint:
/// `account_cloud_center_spec.json` `spec.layout.breakpoints`
/// (name/min/max/behavior), SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`
/// (identik dengan `AccountCenterDesignTokens.specSha256`).
///
/// Acceptance kanonik step 115.6 di `sprint_115.json` (enam viewport):
/// `1536x1024_reference`, `1440_plus`, `1180_to_1439`, `900_to_1179`,
/// `600_to_899`, `under_600`. Snapshot manifest di repo:
/// `docs/planning/v1.2/sprint_115_responsive_grid_system.json`.
///
/// Langkah ini MENJADIKAN LIVE token `layout.breakpoints` dan
/// `card.minWidth` yang pada 115.5 masih `token_only_no_live_widget`.
/// Perilaku chrome per tier (left navigation, drawer summary, collapsed
/// rail, top navigation, full-sheet) tetap di langkah 115.45/115.46/115.47;
/// kontrak ini hanya mengikat grid: resolusi tier, jumlah kolom, peletakan
/// ringkasan kanan, dan jaminan tanpa overflow.
library;

import 'account_center_design_tokens.dart';

/// Lima tier layout sesuai urutan `spec.layout.breakpoints` (min_width menurun).
enum AccountCenterLayoutTier {
  wideDesktop,
  desktop,
  compactDesktop,
  tablet,
  mobile,
}

/// Rencana grid untuk satu tier breakpoint.
final class AccountCenterGridPlan {
  const AccountCenterGridPlan({
    required this.tier,
    required this.breakpointName,
    required this.minWidth,
    required this.maxWidth,
    required this.specBehavior,
    required this.maxColumns,
    required this.summaryIsSideBySide,
  });

  final AccountCenterLayoutTier tier;

  /// Nama breakpoint pada product spec (`wide_desktop` .. `mobile`).
  final String breakpointName;

  /// Batas bawah/atas bracket spec (null saat spec tidak menyebutnya).
  final double? minWidth;
  final double? maxWidth;

  /// Teks `behavior` product spec, ditranskripsikan verbatim.
  final String specBehavior;

  /// Batas jumlah kolom grid kartu untuk tier ini.
  final int maxColumns;

  /// Ringkasan kanan berdampingan HANYA pada `wide_desktop` (spec:
  /// "persistent right summary"). Tier lain menumpuk; perilaku drawer
  /// dirilis langkah 115.46.
  final bool summaryIsSideBySide;

  /// Jumlah kolom untuk lebar konten tersedia.
  ///
  /// Aturan fit: kolom dikurangi sampai lebar kartu
  /// `>= card.minWidth` (220); tidak pernah di bawah 1. Lebar tak-hingga
  /// atau tak-positif aman (1 kolom penuh — OverflowBox-free).
  int columnsFor(double availableWidth) {
    if (!availableWidth.isFinite || availableWidth <= 0) {
      return 1;
    }
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final minCard = AccountCenterDesignTokens.card.minWidth;
    var columns = maxColumns;
    while (columns > 1 &&
        (availableWidth - gap * (columns - 1)) / columns < minCard) {
      columns--;
    }
    return columns;
  }

  /// Lebar kartu hasil [columnsFor] pada lebar konten tersedia.
  double cardWidthFor(double availableWidth) {
    final columns = columnsFor(availableWidth);
    final gap = AccountCenterDesignTokens.layout.cardGap;
    return (availableWidth - gap * (columns - 1)) / columns;
  }
}

/// Registry tunggal grid responsif Account & Cloud Center (115.6).
abstract final class AccountCenterResponsiveGrid {
  /// Path snapshot manifest bukti 115.6 (di dalam repo).
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_responsive_grid_system.json';

  /// Path domain & test slice (untuk manifest `domain`/`tests`).
  static const String domainPath =
      'lib/features/account/domain/account_center_responsive_grid.dart';
  static const List<String> testPaths = <String>[
    'test/features/account/domain/account_center_responsive_grid_test.dart',
    'test/features/account/presentation/'
        'account_cloud_center_responsive_grid_test.dart',
  ];

  /// Sumber product spec (identik dengan kontrak 115.5).
  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;

  /// Sumber sprint kanonik (dipakai test untuk memaku acceptance 115.6).
  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Viewport referensi acceptance `1536x1024_reference`.
  static const ({double height, double width}) referenceViewport = (
    width: 1536,
    height: 1024,
  );

  /// Enam acceptance viewport step 115.6, urutan kanonik.
  static const List<String> acceptanceViewports = <String>[
    '1536x1024_reference',
    '1440_plus',
    '1180_to_1439',
    '900_to_1179',
    '600_to_899',
    'under_600',
  ];

  /// Rencana grid tetap untuk [tier].
  ///
  /// `maxColumns` mengikuti kolom eksplisit spec (compact_desktop=2,
  /// tablet=1-2 -> cap 2, mobile=1); wide_desktop/desktop tidak menyebut
  /// batas sehingga grid 3 kolom implementasi dipertahankan dan dikendalikan
  /// aturan fit `card.minWidth`.
  static AccountCenterGridPlan planFor(AccountCenterLayoutTier tier) {
    final breakpoint = AccountCenterDesignTokens.layout.breakpoints[tier.index];
    return AccountCenterGridPlan(
      tier: tier,
      breakpointName: breakpoint.name,
      minWidth: breakpoint.minWidth,
      maxWidth: breakpoint.maxWidth,
      specBehavior: behaviorFor(tier),
      maxColumns: maxColumnsFor(tier),
      summaryIsSideBySide: tier == AccountCenterLayoutTier.wideDesktop,
    );
  }

  /// Resolusi tier dari lebar viewport.
  ///
  /// Tier = breakpoint dengan `minWidth` terbesar yang masih `<= width`
  /// (urutan list spec menurun; `mobile` tanpa minWidth menangkap sisanya).
  /// Lebar pecahan di antara dua bracket (mis. 1439.5) jatuh ke bracket di
  /// bawah langkah berikutnya sehingga tidak ada celah render.
  static AccountCenterGridPlan resolve(double viewportWidth) {
    if (!viewportWidth.isFinite || viewportWidth < 0) {
      throw ArgumentError.value(
        viewportWidth,
        'viewportWidth',
        'must be a finite viewport width',
      );
    }
    final breakpoints = AccountCenterDesignTokens.layout.breakpoints;
    for (var index = 0; index < breakpoints.length; index++) {
      final minWidth = breakpoints[index].minWidth;
      if (minWidth == null || viewportWidth >= minWidth) {
        return planFor(AccountCenterLayoutTier.values[index]);
      }
    }
    // Tak tercapai: breakpoint terakhir (mobile) minWidth null selalu cocok.
    throw StateError('no breakpoint matched viewport width $viewportWidth');
  }

  /// Batas kolom per tier (lihat doc [planFor]).
  static int maxColumnsFor(AccountCenterLayoutTier tier) => switch (tier) {
    AccountCenterLayoutTier.wideDesktop => 3,
    AccountCenterLayoutTier.desktop => 3,
    AccountCenterLayoutTier.compactDesktop => 2,
    AccountCenterLayoutTier.tablet => 2,
    AccountCenterLayoutTier.mobile => 1,
  };

  /// `spec.layout.breakpoints[].behavior` — ditranskripsikan verbatim.
  static String behaviorFor(AccountCenterLayoutTier tier) => switch (tier) {
    AccountCenterLayoutTier.wideDesktop =>
      'left navigation + main content + persistent right summary',
    AccountCenterLayoutTier.desktop =>
      'left navigation + main content; right summary becomes drawer',
    AccountCenterLayoutTier.compactDesktop =>
      'collapsed navigation rail; overview cards use two columns',
    AccountCenterLayoutTier.tablet =>
      'top navigation; tabs scroll; cards use one or two columns',
    AccountCenterLayoutTier.mobile =>
      'single column; provider details open as full-screen sheet; '
          'charts provide text alternative',
  };
}
