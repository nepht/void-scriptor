/// 115.46 — Desktop & Tablet Adaptation.
///
/// Kontrak chrome adaptif Account & Cloud Center untuk tier di bawah
/// `wide_desktop`: ringkasan kanan menjadi drawer, navigasi terlipat pada
/// `compact_desktop`, navigasi pindah ke atas pada `tablet`, kartu overview
/// dua kolom, dan tab strip tetap bisa digulir.
///
/// Enam acceptance kanonik step 115.46 di `sprint_115.json` (SHA-256
/// `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `right_drawer`, `collapsed_nav`, `two_column`, `scrollable_tabs`,
/// `no_horizontal_overflow`, `state_preserved`.
///
/// Sumber angka: product spec `account_cloud_center_spec.json` (SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`)
/// `layout.breakpoints[].behavior`, yang sudah ditranskripsikan di
/// [AccountCenterResponsiveGrid.behaviorFor] (115.6), dan nilai ukuran yang
/// dipakai lewat [AccountCenterDesignTokens] (115.5).
///
/// Cakupan: 600..1439 saja. `>= 1440` milik frame 115.45 dan `< 600` milik
/// 115.47; di luar rentang itu [resolve] mengembalikan `null` sehingga jalur
/// yang sudah ada tidak dipaksa. Murni Dart tanpa dependensi Flutter supaya
/// domain test bisa memvalidasi manifest
/// `docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json`.
library;

import 'account_center_design_tokens.dart';
import 'account_center_responsive_grid.dart';

/// Cara navigasi utama ditampilkan pada tier adaptif.
enum AccountCenterNavigationMode {
  /// Navigasi kiri penuh (192px) seperti `wide_desktop`.
  leftNavigation,

  /// Rail terlipat: ikon saja, tanpa label.
  collapsedRail,

  /// Navigasi pindah ke baris atas konten.
  topNavigation,
}

/// Cara ringkasan akun ditampilkan pada tier adaptif.
enum AccountCenterSummaryPresentation {
  /// Ringkasan menjadi drawer di sisi kanan.
  drawer,

  /// Ringkasan tetap menumpuk di bawah konten utama.
  stackedBelow,
}

/// Geometri chrome untuk satu viewport pada rentang 600..1439.
final class AccountCenterDesktopTabletLayout {
  const AccountCenterDesktopTabletLayout({
    required this.tier,
    required this.breakpointName,
    required this.viewportWidth,
    required this.navigationMode,
    required this.summaryPresentation,
    required this.navigationWidth,
    required this.contentWidth,
    required this.drawerWidth,
    required this.maxColumns,
  });

  final AccountCenterLayoutTier tier;

  /// Nama breakpoint spec yang menghasilkan [tier].
  final String breakpointName;

  final double viewportWidth;

  final AccountCenterNavigationMode navigationMode;
  final AccountCenterSummaryPresentation summaryPresentation;

  /// Lebar band navigasi kiri. Nol pada [AccountCenterNavigationMode
  /// .topNavigation] karena tidak ada band kiri di tier tablet.
  final double navigationWidth;

  /// Lebar area konten SETELAH band navigasi dan padding halaman. Ini yang
  /// dipakai grid; bukan 75% seperti jalur side-by-side lama.
  final double contentWidth;

  /// Lebar ringkasan bila disajikan sebagai drawer.
  final double drawerWidth;

  /// Batas kolom grid untuk tier ini (dari kontrak 115.6).
  final int maxColumns;

  /// Lebar konten utama ketika drawer dibuka.
  ///
  /// Drawer memakai lebar token ringkasan, bukan persen, supaya lebarnya
  /// sama di semua viewport dan tidak ikut bergeser dengan jalur UI lain.
  double get mainWidthWhenDrawerOpen =>
      summaryPresentation == AccountCenterSummaryPresentation.drawer
      ? contentWidth - drawerWidth
      : contentWidth;

  /// Lebar minimum konten utama yang masih layak: satu kartu pada
  /// [AccountCenterDesignTokens.card.minWidth].
  ///
  /// Kalau drawer lebih lebar dari yang tersisa, konten utama hilang
  /// seluruhnya — itu yang forbidden oleh `right_drawer`.
  double get minMainContentWidth => AccountCenterDesignTokens.card.minWidth;

  /// True bila navigasi terlapit (label disembunyikan).
  bool get isCollapsedNavigation =>
      navigationMode == AccountCenterNavigationMode.collapsedRail;

  /// True bila label navigasi boleh dirender.
  bool get navigationLabelsVisible =>
      navigationMode != AccountCenterNavigationMode.collapsedRail;

  /// True bila navigasi berada di baris atas, bukan band kiri.
  bool get usesTopNavigation =>
      navigationMode == AccountCenterNavigationMode.topNavigation;

  /// `right_drawer`: drawer tidak boleh menghapus konten utama.
  bool get drawerKeepsMainVisible =>
      mainWidthWhenDrawerOpen >= minMainContentWidth - 0.0001;

  /// `scrollable_tabs`: tab strip bergulir mendatar pada semua tier ini.
  ///
  /// Sembilan tab kanonik tidak muat pada lebar 600-1439, jadi strip harus
  /// bisa bergulir. Yang dikunci kontrak ini adalah ketersediaan
  /// scrollability-nya, bukan isi strip: isi strip tetap milik information
  /// architecture 115.3.
  bool get tabsScroll => true;

  /// Jumlah kolom hasil aturan fit untuk [contentWidth].
  int get columnsForContentWidth => _columnsFor(contentWidth);

  /// Jumlah kolom untuk lebar konten tertentu, memakai aturan fit
  /// `card.minWidth` yang sama dengan kontrak 115.6 dan dibatasi
  /// [maxColumns] tier.
  int _columnsFor(double available) {
    if (!available.isFinite || available <= 0) {
      return 1;
    }
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final minCard = AccountCenterDesignTokens.card.minWidth;
    var columns = maxColumns;
    while (columns > 1 &&
        (available - gap * (columns - 1)) / columns < minCard) {
      columns--;
    }
    return columns;
  }

  /// Lebar kartu untuk [columns] pada [contentWidth].
  double cardWidthForContent(int columns) {
    if (columns < 1) {
      throw ArgumentError.value(columns, 'columns', 'must be at least 1');
    }
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final width = (contentWidth - gap * (columns - 1)) / columns;
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        contentWidth,
        'contentWidth',
        'must produce a positive card width',
      );
    }
    return width;
  }

  /// `no_horizontal_overflow`: band navigasi + konten muat di dalam lebar
  /// yang tersisa setelah padding halaman.
  bool bandsFit() {
    const layout = AccountCenterDesignTokens.layout;
    final available = viewportWidth - 2 * layout.pageHorizontalPadding;
    return contentWidth > 0 &&
        navigationWidth + contentWidth <= available + 0.0001;
  }
}

/// Registry tunggal adaptasi desktop & tablet (115.46).
abstract final class AccountCenterDesktopTabletAdaptation {
  /// Path snapshot manifest bukti 115.46 (di dalam repo).
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json';

  /// Path domain & test slice.
  static const String domainPath =
      'lib/features/account/domain/account_center_desktop_tablet_adaptation.dart';
  static const List<String> testPaths = <String>[
    'test/features/account/domain/account_center_desktop_tablet_adaptation_test.dart',
    'test/features/account/presentation/'
        'account_cloud_center_desktop_tablet_test.dart',
  ];

  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;

  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Enam acceptance kanonik step 115.46, urutan `sprint_115.json`.
  static const List<String> acceptanceKeys = <String>[
    'right_drawer',
    'collapsed_nav',
    'two_column',
    'scrollable_tabs',
    'no_horizontal_overflow',
    'state_preserved',
  ];

  /// Lebar rail terlipat = target sentuh minimum + padding kiri/kanan.
  ///
  /// Diturunkan dari token (115.5) supaya collapse tidak punya angka
  /// karangan sendiri dan tetap memenuhi target sentuh 44px.
  ///
  /// `final`, bukan `const`: pembacaan field instan token tidak diizinkan
  /// dalam ekspresi konstanta Dart — pola yang sama dipakai kontrak 115.5
  /// (`wideDesktopMinWidth` di frame 115.45).
  static final double collapsedRailWidth =
      AccountCenterDesignTokens.density.minimumTouchTarget +
      2 * AccountCenterDesignTokens.spacing.twoXs;

  /// Tab strip bergulir pada seluruh tier adaptif.
  static const bool tabsScroll = true;

  /// Rentang viewport yang ditangani kontrak ini: 600 (batas bawah tier
  /// `tablet`) sampai 1439.9 (satu langkah di bawah 1440).
  static const double minWidth = 600;
  static const double maxWidthExclusive = 1440;

  /// True bila kontrak ini berlaku pada [viewportWidth].
  static bool appliesAt(double viewportWidth) =>
      viewportWidth.isFinite &&
      viewportWidth >= minWidth &&
      viewportWidth < maxWidthExclusive;

  /// Geometri chrome untuk [viewportWidth], atau `null` di luar 600..1439.
  ///
  /// Lebar tak-hingga, NaN, atau negatif melempar [ArgumentError]
  /// (fail-closed) alih-alih menghasilkan band negatif.
  static AccountCenterDesktopTabletLayout? resolve(double viewportWidth) {
    if (!viewportWidth.isFinite || viewportWidth < 0) {
      throw ArgumentError.value(
        viewportWidth,
        'viewportWidth',
        'must be a finite non-negative viewport width',
      );
    }
    if (!appliesAt(viewportWidth)) {
      return null;
    }
    const layout = AccountCenterDesignTokens.layout;
    final plan = AccountCenterResponsiveGrid.resolve(viewportWidth);
    final navigationMode = switch (plan.tier) {
      AccountCenterLayoutTier.desktop =>
        AccountCenterNavigationMode.leftNavigation,
      AccountCenterLayoutTier.compactDesktop =>
        AccountCenterNavigationMode.collapsedRail,
      AccountCenterLayoutTier.tablet || AccountCenterLayoutTier.mobile =>
        AccountCenterNavigationMode.topNavigation,
      // `wide_desktop` tidak pernah mencapai sini: `appliesAt` menolak >= 1440.
      AccountCenterLayoutTier.wideDesktop =>
        AccountCenterNavigationMode.leftNavigation,
    };
    final navigationWidth =
        navigationMode == AccountCenterNavigationMode.leftNavigation
        ? layout.leftNavigationWidth
        : navigationMode == AccountCenterNavigationMode.collapsedRail
        ? collapsedRailWidth
        : 0.0;
    final contentWidth =
        (viewportWidth - 2 * layout.pageHorizontalPadding - navigationWidth)
            .clamp(0.0, viewportWidth);
    return AccountCenterDesktopTabletLayout(
      tier: plan.tier,
      breakpointName: plan.breakpointName,
      viewportWidth: viewportWidth,
      navigationMode: navigationMode,
      // Hanya `desktop` menyebut drawer di spec. `compact_desktop` dan
      // `tablet` tidak, jadi ringkasan pada tier itu tetap menumpuk di bawah
      // — drawer tidak dikarang di luar spec.
      summaryPresentation: plan.tier == AccountCenterLayoutTier.desktop
          ? AccountCenterSummaryPresentation.drawer
          : AccountCenterSummaryPresentation.stackedBelow,
      navigationWidth: navigationWidth,
      contentWidth: contentWidth,
      drawerWidth: layout.rightSummaryWidth,
      maxColumns: plan.maxColumns,
    );
  }
}
