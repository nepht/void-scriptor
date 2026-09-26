/// 115.45 — Wide Desktop Visual Implementation.
///
/// Kontrak frame Account & Cloud Center pada viewport referensi 1536x1024:
/// left navigation, main grid, right summary, dan status bar. Enam
/// acceptance kanonik step 115.45 di `sprint_115.json` (SHA-256
/// `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`):
/// `layout_dimensions`, `no_overlap`, `scroll_containment`, `consistent_cards`,
/// `right_rail`, `status_bar`.
///
/// Sumber angka: product spec `account_cloud_center_spec.json` (SHA-256
/// `f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a`)
/// `layout.reference_desktop` dan `information_architecture.overview_sections`,
/// ditranskripsikan lewat `AccountCenterDesignTokens` (115.5) yang nilainya
/// sudah diukur ulang per-piksel dari mockup 1536x1024 (115.38).
///
/// Cakupan: frame TIER `wide_desktop` saja (>= 1440). Drawer rail, collapsed
/// nav, dan reflow tablet milik 115.46; single column mobile milik 115.47.
/// Di luar 1440, [resolve] mengembalikan `null` dan layar memakai jalur
/// responsif yang sudah ada — bukan frame yang dipaksakan.
///
/// Murni Dart tanpa dependensi Flutter supaya domain test bisa memvalidasi
/// manifest `docs/planning/v1.2/sprint_115_wide_desktop_visual_implementation.json`.
library;

import 'dart:math' show min;

import 'account_center_design_tokens.dart';
import 'account_cloud_snapshot.dart';

/// Satu entri left navigation, diturunkan dari
/// `spec.information_architecture.overview_sections`.
class AccountCenterLeftNavItem {
  const AccountCenterLeftNavItem({
    required this.section,
    required this.label,
    required this.iconKey,
  });

  /// Nilai mentah `overview_sections` pada product spec; inilah yang di-pin
  /// test ke spec, bukan ke label tampilan.
  final String section;

  /// Label yang dirender di navigasi kiri.
  final String label;

  /// Kunci ikon logis; pemetaan ke `IconData` milik presentation.
  final String iconKey;
}

/// Satu sel status bar. Nilai SELALU diturunkan dari snapshot lokal —
/// kontrak ini tidak pernah mengarang nilai yang tidak ada di
/// [AccountCloudSnapshot].
class AccountCenterStatusBarItem {
  const AccountCenterStatusBarItem({required this.label, required this.value});

  final String label;
  final String value;
}

/// Geometri frame yang sudah dihitung untuk satu viewport.
final class AccountCenterFrameLayout {
  const AccountCenterFrameLayout({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.leftNavigationWidth,
    required this.mainWidth,
    required this.rightRailWidth,
    required this.statusBarHeight,
    required this.pagePaddingHorizontal,
    required this.pagePaddingVertical,
    required this.gridHeight,
    required this.rowHeights,
  });

  final double viewportWidth;
  final double viewportHeight;

  /// Lebar band left navigation (token `leftNavigationWidth`).
  final double leftNavigationWidth;

  /// Lebar band main grid — sisa setelah nav + rail + padding.
  final double mainWidth;

  /// Lebar band right summary (token `rightSummaryWidth`).
  final double rightRailWidth;

  /// Tinggi band status bar di tepi bawah (token `bottomStatusHeight`).
  final double statusBarHeight;

  final double pagePaddingHorizontal;
  final double pagePaddingVertical;

  /// Tinggi band main grid (chrome + kartu) setelah dikurangi padding
  /// vertikal, celah status bar, dan tinggi status bar.
  ///
  /// Akun tinggi: `2 * pagePaddingVertical + gridHeight + rowGap +
  /// statusBarHeight == viewportHeight`. Status bar adalah band terpisah,
  /// jadi tinggi grid TIDAK boleh menghitung status bar sebagai ruang kosong.
  final double gridHeight;

  /// Tinggi tiap baris grid mockup; jumlahnya persis [gridHeight].
  final List<double> rowHeights;

  /// Jumlah kolom per baris pada frame ini.
  ///
  /// Diturunkan dari [AccountCenterWideDesktopFrame.columnsForRow]: jumlah
  /// kartu pada baris, dibatasi aturan fit `card.minWidth` dari kontrak 115.6
  /// terhadap band main frame. Baris mockup 3/5/5 hanya bertahan bila band
  /// main cukup lebar — lihat [preservesMockupColumns].
  List<int> get rowColumns => <int>[
    for (var index = 0; index < rowHeights.length; index++)
      AccountCenterWideDesktopFrame.columnsForRow(
        mainWidth: mainWidth,
        cardCount: AccountCenterWideDesktopFrame.rowCardCounts[index],
      ),
  ];

  /// True bila kolom frame masih identik mockup (3/5/5).
  ///
  /// Penting untuk laporan: pada viewport referensi 1536, band main setelah
  /// left navigation hanya 961px, sehingga lima kolom selebar 213px tidak muat
  /// dan aturan fit 115.6 menurunkan baris 2/3 menjadi empat kolom.
  bool get preservesMockupColumns =>
      _listEquals(rowColumns, AccountCenterWideDesktopFrame.mockupRowColumns);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  /// Tinggi total baris + celah antar baris; sama dengan [gridHeight].
  double get rowsTotal =>
      rowHeights.fold<double>(0, (sum, height) => sum + height);

  /// Lebar satu kartu untuk [columns] kolom pada band main.
  ///
  /// Fail-closed: jumlah kolom < 1 atau lebar tak-hingga melempar
  /// [ArgumentError] sehingga tidak pernah menghasilkan lebar negatif.
  double cardWidthFor(int columns) {
    if (columns < 1) {
      throw ArgumentError.value(columns, 'columns', 'must be at least 1');
    }
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final width = (mainWidth - gap * (columns - 1)) / columns;
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        mainWidth,
        'mainWidth',
        'must produce a positive card width',
      );
    }
    return width;
  }

  /// `no_overlap`: ketiga band horizontal berdampingan DAN band status bar
  /// terpisah dari area konten, seluruhnya dihitung ulang dari angka frame.
  ///
  /// Mengembalikan `false` (bukan melempar) supaya widget test bisa
  /// melaporkan geometries yang muncul, bukan hanya exception.
  bool bandsAreDisjoint() {
    final horizontalFits =
        leftNavigationWidth + rightRailWidth + mainWidth <=
        viewportWidth - 2 * pagePaddingHorizontal + 0.0001;
    final railIsRightAligned = rightRailWidth > 0;
    // Band main + celah + status bar + padding TEPAT memuat viewport; tidak
    // boleh kurang (ada ruang mati) dan tidak boleh lebih (overflow).
    final chromeBelow = AccountCenterWideDesktopFrame.rowGap + statusBarHeight;
    final contentSitsAboveStatusBar =
        gridHeight + 2 * pagePaddingVertical + chromeBelow <=
        viewportHeight + 0.0001;
    // `rowHeights` adalah tinggi tiap baris; total tinggi yang dipakai grid
    // adalah jumlah baris PLUS celah di antaranya.
    final rowGaps =
        AccountCenterWideDesktopFrame.rowGap * (rowHeights.length - 1);
    final rowsFillGrid =
        (rowsTotal + rowGaps - gridHeight).abs() <= 0.0001 &&
        rowHeights.every((height) => height > 0);
    return horizontalFits &&
        railIsRightAligned &&
        contentSitsAboveStatusBar &&
        rowsFillGrid;
  }

  /// `scroll_containment`: tinggi konten yang boleh dipakai grid sudah
  /// terkunci viewport, sehingga kartu menggulir DI DALAM frame dan halaman
  /// luar tidak pernah memanjang.
  double get scrollableGridHeight => gridHeight;
}

/// Registry tunggal frame `wide_desktop` (115.45).
abstract final class AccountCenterWideDesktopFrame {
  /// Path snapshot manifest bukti 115.45 (di dalam repo).
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_wide_desktop_visual_implementation.json';

  /// Path domain & test slice.
  static const String domainPath =
      'lib/features/account/domain/account_center_wide_desktop_frame.dart';
  static const List<String> testPaths = <String>[
    'test/features/account/domain/account_center_wide_desktop_frame_test.dart',
    'test/features/account/presentation/'
        'account_cloud_center_wide_desktop_test.dart',
  ];

  static const String specDocument = AccountCenterDesignTokens.specDocument;
  static const String specSha256 = AccountCenterDesignTokens.specSha256;
  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// Viewport referensi acceptance `1536x1024_reference`.
  static const double referenceWidth = 1536;
  static const double referenceHeight = 1024;

  /// Lebar minimum tier `wide_desktop` (`spec.layout.breakpoints[0].min_width_px`).
  ///
  /// Bukan `const`: pembacaan field instan `AccountCenterDesignTokens.layout`
  /// tidak diizinkan dalam ekspresi konstanta Dart (pola yang sama dipakai
  /// 115.5 saat token diakses di luar konteks `const`).
  static const double wideDesktopMinWidth = 1440;

  /// Enam acceptance kanonik step 115.45, urutan `sprint_115.json`.
  static const List<String> acceptanceKeys = <String>[
    'layout_dimensions',
    'no_overlap',
    'scroll_containment',
    'consistent_cards',
    'right_rail',
    'status_bar',
  ];

  /// Baris mockup 1536x1024 memakai 3 / 5 / 5 kolom.
  static const List<int> mockupRowColumns = <int>[3, 5, 5];

  /// Jumlah kartu per baris grid mockup, urutan baris 115.36.
  static const List<int> rowCardCounts = <int>[3, 5, 5];

  /// Jumlah kolom hasil aturan fit untuk satu baris.
  ///
  /// Mulai dari jumlah kartu baris itu, lalu dikurangi sampai lebar kartu
  /// `>= card.minWidth` — aturan yang sama dengan kontrak 115.6, jadi frame
  /// tidak pernah memaksakan kolom yang hanya muat karena ambang mockup
  /// lokal. Tidak pernah di bawah 1.
  static int columnsForRow({
    required double mainWidth,
    required int cardCount,
  }) {
    if (cardCount < 1) {
      throw ArgumentError.value(cardCount, 'cardCount', 'must be at least 1');
    }
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final minCard = AccountCenterDesignTokens.card.minWidth;
    var columns = cardCount;
    while (columns > 1 &&
        (mainWidth - gap * (columns - 1)) / columns < minCard) {
      columns--;
    }
    return columns;
  }

  /// Lebar viewport terlebar tempat band main masih memuat [columns] kartu
  /// pada lebar minimum token `card.minWidth`.
  static double minViewportWidthForColumns(int columns) {
    if (columns < 1) {
      throw ArgumentError.value(columns, 'columns', 'must be at least 1');
    }
    const layout = AccountCenterDesignTokens.layout;
    final gap = layout.cardGap;
    final minCard = AccountCenterDesignTokens.card.minWidth;
    final required = columns * minCard + gap * (columns - 1);
    return 2 * layout.pageHorizontalPadding +
        layout.rightSummaryWidth +
        layout.leftNavigationWidth +
        required;
  }

  /// Proporsi tinggi baris terukur dari mockup (351 / 268 / 265 px).
  static const List<double> rowWeights = <double>[351, 268, 265];

  /// Celah antar baris = token `cardGap` (jarak mockup y455 -> y466).
  ///
  /// Nilai disalin dari token supaya bisa dipakai dalam ekspresi konstanta;
  /// test memaku keduanya agar tidak pernah menyimpang.
  static const double rowGap = 11;

  /// Lantai baris pertama: kartu AUTHENTICATION memuat lima baris metode
  /// sign-in dan butuh ruang; bila viewport tidak cukup, selisih diambil dari
  /// baris berikutnya (bukan menambah tinggi total).
  static const double minFirstRowHeight = 430;

  /// Lantai per baris setelah baris pertama. Dipakai hanya sebagai batas
  /// bawah saat memindahkan tinggi, TIDAK menambah tinggi total.
  static const double minRowFloor = 80;

  /// Sembilan entri left navigation dari
  /// `spec.information_architecture.overview_sections`, urutan spec.
  static const List<AccountCenterLeftNavItem> leftNavigation =
      <AccountCenterLeftNavItem>[
        AccountCenterLeftNavItem(
          section: 'authentication',
          label: 'Authentication',
          iconKey: 'badge',
        ),
        AccountCenterLeftNavItem(
          section: 'quick_connect',
          label: 'Quick connect',
          iconKey: 'bolt',
        ),
        AccountCenterLeftNavItem(
          section: 'cloud_storage_usage',
          label: 'Cloud storage usage',
          iconKey: 'cloud',
        ),
        AccountCenterLeftNavItem(
          section: 'connected_services',
          label: 'Connected services',
          iconKey: 'hub',
        ),
        AccountCenterLeftNavItem(
          section: 'api_keys_summary',
          label: 'API keys summary',
          iconKey: 'key',
        ),
        AccountCenterLeftNavItem(
          section: 'team_summary',
          label: 'Team summary',
          iconKey: 'groups',
        ),
        AccountCenterLeftNavItem(
          section: 'activity_log',
          label: 'Activity log',
          iconKey: 'history',
        ),
        AccountCenterLeftNavItem(
          section: 'backup_sync_summary',
          label: 'Backup & sync summary',
          iconKey: 'sync',
        ),
        AccountCenterLeftNavItem(
          section: 'security_summary',
          label: 'Security summary',
          iconKey: 'shield',
        ),
      ];

  /// Frame berlaku hanya pada tier `wide_desktop` (>= 1440). Di bawah itu
  /// `null` — 115.46/115.47 memiliki adaptasinya sendiri.
  static bool appliesAt(double viewportWidth) =>
      viewportWidth.isFinite && viewportWidth >= wideDesktopMinWidth;

  /// Geometri frame untuk viewport diberikan, atau `null` di luar tier
  /// `wide_desktop`.
  ///
  /// Lebar/tinggi tak-hingga atau negatif melempar [ArgumentError] (fail-closed)
  /// alih-alih menghasilkan frame dengan band negatif.
  static AccountCenterFrameLayout? resolve({
    required double width,
    required double height,
  }) {
    if (!width.isFinite || !height.isFinite || width < 0 || height < 0) {
      throw ArgumentError(
        'viewport must be finite and non-negative (got $width x $height)',
      );
    }
    if (!appliesAt(width)) {
      return null;
    }
    const layout = AccountCenterDesignTokens.layout;
    final nav = layout.leftNavigationWidth;
    final rail = layout.rightSummaryWidth;
    final statusBar = layout.bottomStatusHeight;
    final padding = layout.pageHorizontalPadding;
    final paddingV = layout.pageVerticalPadding;
    final inner = width - 2 * padding;
    // Band main adalah sisa; lebarnya dijaga >= 0 supaya frame tidak pernah
    // tidak pernah membuat band negatif ketika viewport hanya sedikit di
    // atas 1440.
    final main = (inner - nav - rail).clamp(0.0, inner);

    // Celah baris dikurangi dari anggaran tinggi yang sama dengan status bar:
    // keduanya adalah ruang yang benar-benar dipakai di luar band main.
    final chrome = statusBar + rowGap;
    final contentHeight = (height - chrome).clamp(0.0, height);
    final gridHeight = (contentHeight - 2 * paddingV).clamp(0.0, contentHeight);
    final rowHeights = rowHeightsFor(gridHeight);
    return AccountCenterFrameLayout(
      viewportWidth: width,
      viewportHeight: height,
      leftNavigationWidth: nav,
      mainWidth: main,
      rightRailWidth: rail,
      statusBarHeight: statusBar,
      pagePaddingHorizontal: padding,
      pagePaddingVertical: paddingV,
      gridHeight: gridHeight,
      rowHeights: rowHeights,
    );
  }

  /// Tinggi baris mockup untuk tinggi grid tersedia.
  ///
  /// Gap antar baris dikurangi dulu; sisa dibagi mengikuti [rowWeights].
  /// Baris pertama punya lantai [minFirstRowHeight]; kekurangan diambil dari
  /// baris lain (dengan lantai 80px) sehingga total tinggi tidak pernah
  /// melampaui tinggi grid.
  static List<double> rowHeightsFor(double gridHeight) {
    final count = rowWeights.length;
    if (gridHeight <= 0) {
      return List<double>.filled(count, 0);
    }
    final usable = (gridHeight - rowGap * (count - 1)).clamp(0.0, gridHeight);
    final totalWeight = rowWeights.fold<double>(0, (sum, w) => sum + w);
    final heights = <double>[
      for (var index = 0; index < count; index++)
        totalWeight > 0
            ? usable * rowWeights[index] / totalWeight
            : usable / count,
    ];
    if (heights.isNotEmpty && heights.first < minFirstRowHeight) {
      final others = heights.length - 1;
      if (others > 0) {
        // Kekurangan baris pertama hanya boleh diambil dari baris lain, dan
        // hanya sebesar yang mereka punya di atas lantai [minRowFloor]. Tanpa
        // batas ini, lantai 430px akan menambah tinggi total dan melanggar
        // scroll_containment pada viewport pendek.
        var capacity = 0.0;
        for (var index = 1; index < heights.length; index++) {
          capacity += heights[index] - min(minRowFloor, heights[index]);
        }
        final wanted = minFirstRowHeight - heights.first;
        final per = (wanted <= capacity ? wanted : capacity) / others;
        // Selisih NYATA yang berhasil dipindahkan, bukan yang diminta: clamp
        // lantai bisa menahan lebih dari `per`, dan sisa yang ditahan itu TIDAK
        // boleh ditambahkan ke baris pertama (akan melanggar total tinggi).
        var moved = 0.0;
        for (var index = 1; index < heights.length; index++) {
          final upper = heights[index];
          final lower = min(minRowFloor, upper);
          final next = (upper - per).clamp(lower, upper);
          moved += upper - next;
          heights[index] = next;
        }
        heights[0] += moved;
      }
    }
    return List<double>.unmodifiable(heights);
  }

  /// Isi status bar diturunkan apa adanya dari snapshot lokal.
  ///
  /// Tidak ada nilai yang difabrikasi: mode akun, hitungan koneksi, dan
  /// cakupan remote semuanya dibaca dari [AccountCloudSnapshot]. Saat tidak
  /// ada koneksi remote, bar menyatakan `Local data only` — bukan nol palsu.
  static List<AccountCenterStatusBarItem> statusBarItems(
    AccountCloudSnapshot snapshot,
  ) {
    final connected = snapshot.services
        .where(
          (service) => service.state == AccountCloudConnectionState.connected,
        )
        .length;
    final remoteConnected = snapshot.services.any(
      (service) =>
          service.state == AccountCloudConnectionState.connected &&
          (service.group == AccountCloudServiceGroup.cloudStorage ||
              service.group == AccountCloudServiceGroup.sync),
    );
    return List<AccountCenterStatusBarItem>.unmodifiable(
      <AccountCenterStatusBarItem>[
        AccountCenterStatusBarItem(
          label: 'Mode',
          value: snapshot.accountModeLabel,
        ),
        AccountCenterStatusBarItem(
          label: 'Services',
          value: '$connected of ${snapshot.services.length} connected',
        ),
        AccountCenterStatusBarItem(
          label: 'Remote',
          value: remoteConnected ? 'Provider connected' : 'Local data only',
        ),
      ],
    );
  }
}
