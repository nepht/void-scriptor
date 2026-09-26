/// 115.47 — Mobile Adaptation.
///
/// Kontrak chrome tier `mobile` (<600px) untuk Account & Cloud Center:
/// satu kolom, detail provider sebagai sheet layar penuh, action bar
/// menempel di bawah yang menghormati safe area OS, target aksi 44px, dan
/// kewajiban alternatif teks chart.
///
/// Enam acceptance kanonik step 115.47 di `sprint_115.json` (SHA-256
/// `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `single_column`, `provider_sheet`, `safe_actions`, `44px_targets`,
/// `text_alternatives`, `no_clipped_content`.
///
/// Sumber angka: product spec `account_cloud_center_spec.json` (SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`)
/// `layout.breakpoints[4].behavior` = "single column; provider details open as
/// full-screen sheet; charts provide text alternative", `layout.density`, dan
/// `accessibility.requirements`. Perilaku tier sudah ditranskripsikan di
/// [AccountCenterResponsiveGrid.behaviorFor] (115.6); ukuran yang dipakai
/// lewat [AccountCenterDesignTokens] (115.5).
///
/// Cakupan: <600 saja. 600-1439 milik kontrak 115.46 dan >=1440 milik frame
/// 115.45; di luar rentang itu [resolve] mengembalikan `null` sehingga jalur
/// yang sudah ada tidak dipaksa. Murni Dart tanpa dependensi Flutter supaya
/// domain test bisa memvalidasi manifest
/// `docs/planning/v1.2/sprint_115_mobile_adaptation.json`.
library;

import 'account_center_design_tokens.dart';
import 'account_center_responsive_grid.dart';

/// Cara detail provider ditampilkan pada tier mobile.
enum AccountCenterProviderDetailsPresentation {
  /// Sheet yang menutupi seluruh viewport (spec: "full-screen sheet").
  fullScreenSheet,
}

/// Geometri chrome mobile untuk satu viewport di bawah 600px.
final class AccountCenterMobileLayout {
  const AccountCenterMobileLayout({
    required this.tier,
    required this.breakpointName,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.safeAreaBottom,
    required this.contentWidth,
    required this.columns,
    required this.actionBarHeight,
    required this.actionTargetHeight,
  });

  final AccountCenterLayoutTier tier;

  /// Nama breakpoint spec yang menghasilkan [tier].
  final String breakpointName;

  final double viewportWidth;
  final double viewportHeight;

  /// Inset bawah ruang aman OS (dari `MediaQuery.viewPadding`).
  final double safeAreaBottom;

  /// Lebar area konten SETELAH padding halaman. Tier mobile tidak punya band
  /// navigasi, jadi seluruh lebar tersisa dipakai konten.
  final double contentWidth;

  /// Jumlah kolom grid: satu. Kartu memakai seluruh [contentWidth].
  final int columns;

  /// Tinggi bar aksi termasuk padding atas/bawah, TIDAK termasuk ruang aman.
  final double actionBarHeight;

  /// Tinggi target aksi di dalam bar.
  final double actionTargetHeight;

  /// Lebar sheet detail provider: seluruh viewport.
  double get providerSheetWidth => viewportWidth;

  /// Tinggi sheet detail provider: seluruh viewport.
  ///
  /// Sheet partial akan memotong baris detail terakhir, jadi kontrak memilih
  /// viewport penuh yang memang diminta spec.
  double get providerSheetHeight => viewportHeight;

  /// `single_column`: satu kolom penuh, tanpa navigasi kiri.
  bool get singleColumn => columns == 1;

  /// Batas kolom dari kontrak grid 115.6.
  int get maxColumns => columns;

  /// Lebar satu kartu = seluruh lebar konten.
  double get cardWidth => contentWidth;

  /// Lebar band navigasi. Tier mobile tidak punya band; nilainya nol
  /// sehingga tidak ada ruang yang terbuang.
  double get navigationWidth => 0;

  /// `provider_sheet`: detail provider sebagai sheet layar penuh.
  AccountCenterProviderDetailsPresentation get providerDetails =>
      AccountCenterProviderDetailsPresentation.fullScreenSheet;

  /// True bila sheet menutupi seluruh viewport (bukan panel sebagian).
  bool get providerSheetIsFullScreen =>
      providerSheetWidth >= viewportWidth - 0.0001 &&
      providerSheetHeight >= viewportHeight - 0.0001;

  /// `44px_targets`: tinggi minimum target aksi pada bar.
  double get minimumActionTarget => actionTargetHeight;

  /// `safe_actions`: tinggi action bar termasuk ruang aman OS.
  double get actionBarTotalHeight => actionBarHeight + safeAreaBottom;

  /// Cadangan tinggi di bawah konten: bar aksi + ruang aman.
  ///
  /// Area konten scroll berhenti tepat di atas nilai ini sehingga kartu
  /// terakhir tidak pernah tertutup bar.
  double get contentBottomInset => actionBarTotalHeight;

  /// `safe_actions`: ruang bawah konten dicadangkan penuh.
  bool get reservesActionBarSpace => contentBottomInset > 0;

  /// `text_alternatives`: tier mobile mewajibkan alternatif teks chart yang
  /// terlihat (bukan hanya semantics).
  bool get chartsRequireVisibleTextAlternative => true;

  /// Tinggi area konten = viewport dikurangi padding vertikal dan inset bawah.
  double get contentHeight {
    final height =
        viewportHeight -
        2 * AccountCenterDesignTokens.layout.pageVerticalPadding -
        contentBottomInset;
    return height < 0 ? 0 : height;
  }

  /// True bila area konten masih punya tinggi positif pada viewport ini.
  bool get contentAreaPositive => contentHeight > 0;

  /// `no_clipped_content`: apakah konten pada posisi [bottom] terpotong.
  ///
  /// [bottom] diukur relatif terhadap dasar viewport (0 = tepi bawah).
  /// konten hanya aman bila ruang yang tersisa sudah melebihi inset bawah.
  bool clipsContentAt(double bottom) => bottom < contentBottomInset;

  /// Alternatif teks chart yang boleh ditampilkan apa adanya.
  bool hasVisibleTextAlternative(String? alternative) =>
      AccountCenterMobileAdaptation.requireVisibleTextAlternativeOrNull(
        alternative,
      ) !=
      null;
}

/// Registry tunggal adaptasi mobile (115.47).
abstract final class AccountCenterMobileAdaptation {
  /// Path snapshot manifest bukti 115.47 (di dalam repo).
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_mobile_adaptation.json';

  /// Path domain & test slice.
  static const String domainPath =
      'lib/features/account/domain/account_center_mobile_adaptation.dart';
  static const List<String> testPaths = <String>[
    'test/features/account/domain/account_center_mobile_adaptation_test.dart',
    'test/features/account/presentation/account_cloud_center_mobile_test.dart',
  ];

  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;

  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Enam acceptance kanonik step 115.47, urutan `sprint_115.json`.
  static const List<String> acceptanceKeys = <String>[
    'single_column',
    'provider_sheet',
    'safe_actions',
    '44px_targets',
    'text_alternatives',
    'no_clipped_content',
  ];

  /// Target sentuh minimum spec (`layout.density.minimum_touch_target_px`).
  ///
  /// `final`, bukan `const`: `density` adalah token instan sehingga
  /// pembacaan field-nya tidak sah dalam ekspresi konstanta Dart — pola yang
  /// sama dipakai 115.5, 115.45, dan 115.46.
  static final double minimumActionTarget =
      AccountCenterDesignTokens.density.minimumTouchTarget;

  /// Tinggi action bar = target sentuh + padding atas/bawah.
  ///
  /// Diturunkan dari token (115.5) supaya bar tidak punya angka karangan dan
  /// tinggi target di dalam bar tepat sama dengan [minimumActionTarget].
  ///
  /// `final`, bukan `const`: pembacaan field instan token tidak diizinkan
  /// dalam ekspresi konstanta Dart — pola yang sama dipakai kontrak 115.5
  /// (`wideDesktopMinWidth` di frame 115.45) dan 115.46
  /// (`collapsedRailWidth`).
  static final double actionBarHeight =
      minimumActionTarget + 2 * AccountCenterDesignTokens.spacing.twoXs;

  /// Rentang viewport yang ditangani kontrak ini: lebih kecil dari 600
  /// (batas bawah tier `tablet` milik 115.46).
  static const double minWidth = 0;
  static const double maxWidthExclusive = 600;

  /// True bila kontrak ini berlaku pada [viewportWidth].
  static bool appliesAt(double viewportWidth) =>
      viewportWidth.isFinite &&
      viewportWidth >= minWidth &&
      viewportWidth < maxWidthExclusive;

  /// Geometri chrome mobile, atau `null` di luar rentang 0..599.
  ///
  /// Lebar/tinggi tak-hingga, NaN, negatif, atau tak menghasilkan area
  /// konten positif melempar [ArgumentError] (fail-closed) alih-alih
  /// menghasilkan geometri yang memotong isi.
  static AccountCenterMobileLayout? resolve({
    required double viewportWidth,
    required double viewportHeight,
    double safeAreaBottom = 0,
  }) {
    if (!viewportWidth.isFinite || viewportWidth < 0) {
      throw ArgumentError.value(
        viewportWidth,
        'viewportWidth',
        'must be a finite non-negative viewport width',
      );
    }
    if (!viewportHeight.isFinite || viewportHeight <= 0) {
      throw ArgumentError.value(
        viewportHeight,
        'viewportHeight',
        'must be a finite positive viewport height',
      );
    }
    if (!safeAreaBottom.isFinite || safeAreaBottom < 0) {
      throw ArgumentError.value(
        safeAreaBottom,
        'safeAreaBottom',
        'must be a finite non-negative safe area inset',
      );
    }
    if (!appliesAt(viewportWidth)) {
      return null;
    }
    const layout = AccountCenterDesignTokens.layout;
    final plan = AccountCenterResponsiveGrid.resolve(viewportWidth);
    if (plan.tier != AccountCenterLayoutTier.mobile) {
      // `appliesAt` sudah membatasi <600; ini menjaga agar tier yang
      // ter-resolve keliru tidak pernah memakai geometri mobile.
      throw StateError(
        'viewport $viewportWidth resolved to ${plan.breakpointName}, '
        'not the mobile tier',
      );
    }
    final contentWidth = viewportWidth - 2 * layout.pageHorizontalPadding;
    if (contentWidth <= 0) {
      throw ArgumentError.value(
        viewportWidth,
        'viewportWidth',
        'must leave room for page padding on both sides',
      );
    }
    final layoutResult = AccountCenterMobileLayout(
      tier: plan.tier,
      breakpointName: plan.breakpointName,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      safeAreaBottom: safeAreaBottom,
      contentWidth: contentWidth,
      // `maxColumns` tier mobile = 1 (kontrak 115.6).
      columns: plan.maxColumns,
      actionBarHeight: actionBarHeight,
      actionTargetHeight: minimumActionTarget,
    );
    if (!layoutResult.contentAreaPositive) {
      throw ArgumentError.value(
        viewportHeight,
        'viewportHeight',
        'must stay taller than the action bar plus page padding',
      );
    }
    return layoutResult;
  }

  /// Alternatif teks chart yang boleh dipakai apa adanya.
  ///
  /// String kosong/spasi penuh ditolak fail-closed supaya tier mobile tidak
  /// pernah mengklaim "text alternative tersedia" padahal yang dirender
  /// kosong.
  static String requireVisibleTextAlternative(String? alternative) {
    final normalized = requireVisibleTextAlternativeOrNull(alternative);
    if (normalized == null) {
      throw ArgumentError.value(
        alternative,
        'alternative',
        'must be a non-empty chart text alternative',
      );
    }
    return normalized;
  }

  /// Versi nullable dari [requireVisibleTextAlternative] untuk pemeriksa
  /// layar (bukan untuk deklarasi widget).
  static String? requireVisibleTextAlternativeOrNull(String? alternative) {
    final normalized = alternative?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
