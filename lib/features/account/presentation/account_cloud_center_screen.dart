import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/theme/void_theme_context.dart';
import '../../../design_system/widgets/branding/brand_assets.dart';
import '../application/account_operational_metrics.dart';
import '../domain/account_cloud_snapshot.dart';
import '../domain/account_center_accessibility.dart';
import '../domain/account_center_authentication_profile_card.dart';
import '../domain/account_center_desktop_tablet_adaptation.dart';
import '../domain/account_center_design_tokens.dart';
import '../domain/account_center_information_architecture.dart';
import '../domain/account_center_keyboard_screen_reader_verification.dart';
import '../domain/account_center_localization_formatting.dart';
import '../domain/account_center_mobile_adaptation.dart';
import '../domain/account_center_performance_resilience.dart';
import '../domain/account_center_provider_connector_manifest.dart';
import '../domain/account_center_responsive_grid.dart';
import '../domain/account_center_wide_desktop_frame.dart';
import '../domain/account_center_provider_icon_registry.dart';
import 'storage_usage_card.dart';

/// Peran tipografi 115.5 dari product spec (bobot VoidTypography dipertahankan).
final TextStyle _pageTitle = VoidTypography.displayMedium.copyWith(
  fontSize: AccountCenterDesignTokens.typography.pageTitle,
);
final TextStyle _sectionTitle = VoidTypography.headingMedium.copyWith(
  fontSize: AccountCenterDesignTokens.typography.sectionTitle,
);
final TextStyle _body = VoidTypography.body.copyWith(
  fontSize: AccountCenterDesignTokens.typography.body,
);
final TextStyle _caption = VoidTypography.caption.copyWith(
  fontSize: AccountCenterDesignTokens.typography.caption,
);
final TextStyle _metric = VoidTypography.headingMedium.copyWith(
  fontSize: AccountCenterDesignTokens.typography.metric,
);

class AccountCloudCenterScreen extends ConsumerStatefulWidget {
  const AccountCloudCenterScreen({
    super.key,
    this.snapshot,
    this.operationalMetrics,
    this.initialTab,
    this.onSignIn,
    this.onSearch,
    this.onNotifications,
    this.onSyncNow,
    this.onBackupProject,
    this.onOpenAiProviders,
    this.onTabChanged,
    this.providerManifest,
    this.onConnectProvider,
  });

  final AccountCloudSnapshot? snapshot;
  final AccountOperationalMetrics? operationalMetrics;

  /// Slug deep link `?tab=`; null/tak dikenal jatuh ke overview (fail closed).
  final String? initialTab;
  final VoidCallback? onSignIn;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final VoidCallback? onSyncNow;
  final VoidCallback? onBackupProject;
  final VoidCallback? onOpenAiProviders;
  final ProviderConnectorManifest? providerManifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;

  /// Dipanggil saat tab berubah; router memakainya untuk mencatat history entry.
  final ValueChanged<String>? onTabChanged;

  @override
  ConsumerState<AccountCloudCenterScreen> createState() =>
      _AccountCloudCenterScreenState();
}

class _AccountCloudCenterScreenState
    extends ConsumerState<AccountCloudCenterScreen> {
  AccountCenterTab _tab = AccountCenterInformationArchitecture.tabs.first;

  /// 115.46 — ringkasan sebagai drawer pada tier `desktop` (1180-1439).
  ///
  /// State ini milik presentation, bukan kontrak: kontrak 115.46 hanya
  /// menentukan bahwa ringkasan disajikan sebagai drawer. Karena state tetap
  /// hidup di `State`, berpindah viewport dari tier adaptif ke frame 115.45
  /// tidak boleh meninggalkan drawer menggantung (test mengunci itu).
  bool _summaryDrawerOpen = false;

  /// 115.47 — entry connector yang detailnya dibuka sebagai sheet layar
  /// penuh pada tier `mobile` (<600px).
  ///
  /// State ini milik presentation, bukan kontrak: [AccountCenterMobileLayout]
  /// hanya menentukan bahwa detail provider disajikan sebagai full-screen
  /// sheet. Karena state tetap hidup di `State`, berpindah viewport ke tier
  /// lain tidak boleh meninggalkan sheet yang menggantung.
  ProviderConnectorEntry? _providerDetailsOpen;

  @override
  void initState() {
    super.initState();
    _tab = AccountCenterInformationArchitecture.resolveTab(widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant AccountCloudCenterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _tab = AccountCenterInformationArchitecture.resolveTab(
          widget.initialTab,
        );
      });
    }
  }

  void _selectTab(AccountCenterTab next) {
    if (next == _tab) {
      return;
    }
    // 115.48: perpindahan tab WAJIB terdengar. Sebelum ini perubahan tab
    // hanya terlihat (garis bawah + warna), jadi pengguna pembaca layar
    // tidak pernah tahu they've berpindah section. Router-driven mode
    // announcing di caller karena tab berubah di luar widget ini.
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(next.slug);
      _announceTabSelected(next);
      return;
    }
    setState(() => _tab = next);
    _announceTabSelected(next);
  }

  /// 115.48 `status_announcements` — pengumuman tab memakai builder kontrak
  /// supaya teksnya tidak bisa menyimpang dari yang diuji.
  void _announceTabSelected(AccountCenterTab tab) {
    // 115.48 memakai `sendAnnouncement`: `announce` sudah deprecated sejak
    // Flutter 3.35 karena tidak kompatibel multi-window, dan pengumuman di
    // kanal aksesibilitas yang sama persis (test capture tetap bekerja).
    SemanticsService.sendAnnouncement(
      View.of(context),
      AccountCenterKeyboardScreenReader.tabSelectedAnnouncement(tab.label),
      Directionality.of(context),
    );
  }

  /// 115.48 `status_announcements` — buka/tutup drawer ringkasan.
  void _announceSummaryDrawer({required bool open}) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      AccountCenterKeyboardScreenReader.summaryDrawerAnnouncement(open: open),
      Directionality.of(context),
    );
  }

  /// 115.48 `status_announcements` — sheet detail provider. Label provider
  /// dibangun dari builder 115.7 yang sama dengan `_ProviderTile`, jadi
  /// sheet dan tile tidak mungkin berbeda.
  void _announceProviderDetails({
    required ProviderConnectorEntry entry,
    required bool opening,
  }) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      AccountCenterKeyboardScreenReader.providerDetailsAnnouncement(
        name: entry.displayName,
        status: _providerConnectionLabel(entry.availability),
        opening: opening,
      ),
      Directionality.of(context),
    );
  }

  void _openAccountSearch() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AccountCenterSearchDialog(
        onSelected: (tab) {
          Navigator.of(dialogContext).pop();
          _selectTab(tab);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data =
        widget.snapshot ??
        AccountCloudSnapshot.localOnly(
          session: ref.watch(authControllerProvider).valueOrNull,
        );
    final operationalMetrics =
        widget.snapshot != null || widget.operationalMetrics != null
        ? AsyncData<AccountOperationalMetrics?>(widget.operationalMetrics)
        : ref.watch(accountOperationalMetricsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 115.6: tier breakpoint diresolusi dari lebar viewport (bukan
            // heuristik 980px) — grid mengikuti kontrak responsif spec.
            final gridPlan = AccountCenterResponsiveGrid.resolve(
              constraints.maxWidth,
            );
            // 115.45: pada tier `wide_desktop` seluruh halaman memakai frame
            // kanonik (left navigation + main grid + right rail + status bar).
            // Di bawah 1440 frame TIDAK dipakai: drawer/collapse/reflow milik
            // 115.46 dan 115.47 yang belum dieksekusi, sehingga jalur
            // responsif yang ada dipertahankan apa adanya.
            final frame = AccountCenterWideDesktopFrame.resolve(
              width: constraints.maxWidth,
              height: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height,
            );
            if (frame != null) {
              return _buildWideDesktopFrame(
                context: context,
                frame: frame,
                data: data,
                operationalMetrics: operationalMetrics,
              );
            }
            // 115.46: 600-1439 memakai chrome adaptif — ringkasan sebagai
            // drawer, navigasi terlipat, atau navigasi atas. Di bawah 600
            // kontrak mengembalikan null dan jalur responsif yang sudah ada
            // tetap dipakai apa adanya (milik 115.47).
            final adaptive = AccountCenterDesktopTabletAdaptation.resolve(
              constraints.maxWidth,
            );
            if (adaptive != null) {
              return _buildDesktopTabletLayout(
                context: context,
                adaptive: adaptive,
                data: data,
                gridPlan: gridPlan,
                operationalMetrics: operationalMetrics,
              );
            }
            // 115.47: di bawah 600 tier mobile memakai chrome sendiri — satu
            // kolom, detail provider sebagai sheet layar penuh, dan action bar
            // menempel di bawah yang menghormati ruang aman OS. Jalur
            // responsif yang sudah ada di bawah 600 TIDAK lagi dipakai karena
            // ia tidak punya padanan spec untuk ketiganya.
            final mobile = AccountCenterMobileAdaptation.resolve(
              viewportWidth: constraints.maxWidth,
              viewportHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height,
              safeAreaBottom: MediaQuery.viewPaddingOf(context).bottom,
            );
            if (mobile != null) {
              return _buildMobileLayout(
                context: context,
                mobile: mobile,
                data: data,
                gridPlan: gridPlan,
                operationalMetrics: operationalMetrics,
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    AccountCenterDesignTokens.layout.pageHorizontalPadding,
                vertical: AccountCenterDesignTokens.layout.pageVerticalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, shellConstraints) {
                  final wide = gridPlan.summaryIsSideBySide;
                  final mainWidth = wide
                      ? shellConstraints.maxWidth * 0.75 -
                            AccountCenterDesignTokens.layout.columnGap / 2
                      : shellConstraints.maxWidth;
                  final railWidth = wide
                      ? shellConstraints.maxWidth * 0.25 -
                            AccountCenterDesignTokens.layout.columnGap / 2
                      : shellConstraints.maxWidth;
                  // 115.36: satu panel penuh tanpa scroll vertikal. Tinggi
                  // viewport dipakai eksplisit karena harness pengujian
                  // tanpa Scaffold memberi tinggi tak terbatas; tanpa ini
                  // Column/Row di bawah tidak boleh memakai Expanded.
                  final shellHeight = shellConstraints.maxHeight.isFinite
                      ? shellConstraints.maxHeight
                      : MediaQuery.sizeOf(context).height;
                  return SizedBox(
                    height: shellHeight,
                    // `wide_desktop`: area utama dan rail berdampingan dalam
                    // satu baris. Tier lain: rail turun ke bawah sebagai run
                    // kedua (kontrak 115.6 `summaryIsSideBySide`). `Wrap`
                    // dipilih karena aman di kedua tier tanpa tinggi tak
                    // terbatas, sedangkan `Row` selalu menumpuk dua anak
                    // selebar viewport dan meluap.
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _shellChildren(
                              mainWidth: mainWidth,
                              railWidth: railWidth,
                              data: data,
                              gridPlan: gridPlan,
                              operationalMetrics: operationalMetrics,
                            ),
                          )
                        : SingleChildScrollView(
                            // 115.36: di tier selain `wide_desktop` seluruh
                            // halaman (chrome + grid + rail) menjadi satu
                            // run yang bergulir. Tinggi viewport dipakai
                            // sebagai `minHeight` supaya panel tetap mengisi
                            // layar, dan kedua anak memakai tinggi natural —
                            // `Expanded` di [_AccountSummaryRail] karena itu
                            // butuh tinggi terkunci, sehingga rail ikut diberi
                            // tinggi viewport penuh pada jalur ini.
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: shellHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _shellMain(
                                    mainWidth: mainWidth,
                                    data: data,
                                    gridPlan: gridPlan,
                                    scrollable: true,
                                  ),
                                  SizedBox(
                                    height: AccountCenterDesignTokens
                                        .layout
                                        .columnGap,
                                  ),
                                  _shellRail(
                                    railWidth: railWidth,
                                    data: data,
                                    gridPlan: gridPlan,
                                    operationalMetrics: operationalMetrics,
                                    natural: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// 115.47 — chrome tier `mobile` (<600px).
  ///
  /// Tiga perilaku spec ada di sini dan tidak di tempat lain: satu kolom
  /// penuh, detail provider sebagai sheet layar penuh, dan action bar
  /// menempel di bawah. Bar berada DI LUAR area konten scroll sehingga
  /// `no_clipped_content` tidak bergantung pada posisi scroll saat ini.
  ///
  /// Ruang aman OS diambil dari [MediaQuery.viewPadding] (bukan `SafeArea`),
  /// karena bar ini sudah menempel di luar area konten: `SafeArea` akan
  /// menambah ruang kosong kedua kali.
  Widget _buildMobileLayout({
    required BuildContext context,
    required AccountCenterMobileLayout mobile,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required AsyncValue<AccountOperationalMetrics?> operationalMetrics,
  }) {
    const layoutTokens = AccountCenterDesignTokens.layout;
    // 115.47: tinggi terkunci untuk area konten. Tanpa ini `Column` chrome +
    // grid akan melebihi viewport, dan inset bawah action bar tidak akan
    // pernah berarti apa-apa.
    final contentHeight = mobile.contentHeight;

    // Aksi bar memakai aksi nyata yang sudah ada pada halaman: kembali ke
    // tab overview, membuka dialog search IA, dan membuka detail provider
    // yang bisa dihubungkan. Tidak ada aksi baru yang dikarang di sini, dan
    // tidak ada aksi yang mati di tier ini.
    final connectableEntries =
        (widget.providerManifest ?? ProviderConnectorManifest.standard).all
            .where((entry) => entry.isConnectable)
            .toList(growable: false);
    // Aksi 'connect' hanya hidup bila ada entry yang benar-benar connectable
    // DAN halaman punya callback connect. Standard manifest 115.9 menyatakan
    // seluruh entry `UNVERIFIED`, jadi tanpa syarat ini target ketiga tampil
    // sebagai tombol aktif yang diam — persis kelas "dead control" yang
    // acceptance `safe_actions` melarang. Slotnya tetap ada supaya geometri
    // bar tidak berubah; yang dimatikan adalah aksi, bukan tempatnya.
    final canOpenProviderDetails =
        connectableEntries.isNotEmpty && widget.onConnectProvider != null;
    final actionEntries = <({String key, IconData icon, VoidCallback? onTap})>[
      (
        key: 'overview',
        icon: Icons.dashboard_outlined,
        onTap: () => _selectTab(AccountCenterInformationArchitecture.tabs[0]),
      ),
      (key: 'search', icon: Icons.search, onTap: _openAccountSearch),
      (
        key: 'connect',
        icon: Icons.add_link,
        onTap: canOpenProviderDetails
            ? () {
                final entry = connectableEntries.first;
                if (_providerDetailsOpen?.providerId == entry.providerId) {
                  return;
                }
                setState(() {
                  _providerDetailsOpen = entry;
                  _announceProviderDetails(entry: entry, opening: true);
                });
              }
            : null,
      ),
    ];

    // Ringkasan ditumpuk DI DALAM satu wilayah scroll yang sama dengan
    // konten: tier mobile tidak punya band navigasi tempat rail bisa
    // diletakkan, dan spec tier ini tidak menyebut drawer. Tinggi wilayahnya
    // tetap terkunci (lihat `contentHeight`) sehingga hanya isinya yang
    // bergulir, bukan halaman.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _shellMain(
          mainWidth: mobile.contentWidth,
          data: data,
          gridPlan: gridPlan,
          scrollable: true,
          onOpenProviderDetails: (entry) => setState(() {
            // 115.53: membuka sheet dari TILE sebelumnya hanya mengubah
            // state — `_announceProviderDetails` hanya dipanggil dari slot
            // action bar, sehingga pengguna pembaca layar yang membuka
            // detail lewat tile (jalur yang SATUNYA untuk provider yang
            // tidak connectable, termasuk yang sedang outage) tidak
            // mendengar apa pun. Sekarang kedua jalur mengumumkan.
            _providerDetailsOpen = entry;
            _announceProviderDetails(entry: entry, opening: true);
          }),
        ),
        SizedBox(height: AccountCenterDesignTokens.spacing.md),
        _shellRail(
          railWidth: mobile.contentWidth,
          data: data,
          gridPlan: gridPlan,
          operationalMetrics: operationalMetrics,
          natural: true,
        ),
      ],
    );

    return Stack(
      key: const ValueKey('account-center-mobile-layout'),
      children: [
        Padding(
          // Kedua sumbu: 115.5 memverifikasi token padding ini pada widget
          // yang dirender, jadi jalur mobile tidak boleh melompatinya.
          padding: EdgeInsets.symmetric(
            horizontal: layoutTokens.pageHorizontalPadding,
            vertical: layoutTokens.pageVerticalPadding,
          ),
          child: SizedBox(
            height: contentHeight,
            child: SingleChildScrollView(
              key: const ValueKey('account-center-mobile-content'),
              child: content,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _MobileActionBar(
            key: const ValueKey('account-center-mobile-action-bar'),
            layout: mobile,
            actions: actionEntries,
          ),
        ),
        if (_providerDetailsOpen case final entry?)
          _MobileProviderDetailsSheet(
            key: const ValueKey('account-center-provider-details'),
            entry: entry,
            layout: mobile,
            canConnect: widget.onConnectProvider != null,
            onConnect: widget.onConnectProvider == null
                ? null
                : () => widget.onConnectProvider!(entry),
            onClose: () => setState(() {
              // 115.48: menutup sheet juga harus terdengar, kalau tidak
              // pengguna pembaca layar menekan Close dan tidak tahu apa pun
              // yang terjadi.
              _providerDetailsOpen = null;
              _announceProviderDetails(entry: entry, opening: false);
            }),
          ),
      ],
    );
  }

  /// 115.46 — chrome adaptif desktop & tablet.
  ///
  /// Band kiri (atau navigasi atas) dan area konten dihitung dari geometri
  /// kontrak [AccountCenterDesktopTabletLayout], bukan dari heuristik persen
  /// jalur lama. Ringkasan: drawer pada tier `desktop`, menumpuk di bawah
  /// pada `compact_desktop` dan `tablet` — sesuai `behavior` product spec.
  ///
  /// Bila drawer dibuka, konten utama menyusut ke sisa lebar
  /// (`mainWidthWhenDrawerOpen`) alih-alih menimpa, jadi `right_drawer`
  /// tidak pernah menghapus konten.
  Widget _buildDesktopTabletLayout({
    required BuildContext context,
    required AccountCenterDesktopTabletLayout adaptive,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required AsyncValue<AccountOperationalMetrics?> operationalMetrics,
  }) {
    final padding = AccountCenterDesignTokens.layout.pageHorizontalPadding;
    final drawerOpen =
        _summaryDrawerOpen &&
        adaptive.summaryPresentation == AccountCenterSummaryPresentation.drawer;
    final mainWidth = drawerOpen
        ? adaptive.mainWidthWhenDrawerOpen
        : adaptive.contentWidth;
    // 115.46 `no_horizontal_overflow` punya pasangan vertikal: band navigasi
    // memakai tinggi viewport terkunci (ListView di dalamnya butuh tinggi
    // tak terbatas yang tidak boleh), sementara konten bergulir sendiri.
    // Tanpa ini Column di bawah meluap melebihi viewport.
    final shellHeight = MediaQuery.sizeOf(context).height;

    final main = _shellMain(
      mainWidth: mainWidth,
      data: data,
      gridPlan: gridPlan,
      scrollable: true,
    );
    // Ringkasan sebagai drawer: overlay di luar band konten (bukan anak
    // Row), jadi tidak pernah mendorong band navigasi. Tingginya terkunci
    // viewport dan kartu di dalamnya yang bergulir — `natural: false` memakai
    // `Expanded` yang butuh tinggi terkunci.
    final summaryDrawer = drawerOpen
        ? Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              key: const ValueKey('account-center-summary-drawer'),
              width: adaptive.drawerWidth,
              height: shellHeight,
              child: _shellRail(
                railWidth: adaptive.drawerWidth,
                data: data,
                gridPlan: gridPlan,
                operationalMetrics: operationalMetrics,
                natural: false,
              ),
            ),
          )
        : const SizedBox.shrink();

    Widget navigationBand() => switch (adaptive.navigationMode) {
      // Key sengaja BERBEDA dari band left navigation frame 115.45: chrome
      // adaptif bukan frame wide desktop, dan test 115.45 memakai key frame
      // itu untuk membuktikan frame tidak dipaksakan di bawah 1440.
      AccountCenterNavigationMode.leftNavigation => _AccountLeftNavigation(
        key: const ValueKey('account-center-desktop-left-navigation'),
        width: adaptive.navigationWidth,
        activeSection: _activeOverviewSection(),
      ),
      AccountCenterNavigationMode.collapsedRail => _AccountCollapsedNavRail(
        key: const ValueKey('account-center-collapsed-rail'),
        width: adaptive.navigationWidth,
        activeSection: _activeOverviewSection(),
      ),
      AccountCenterNavigationMode.topNavigation => const SizedBox.shrink(),
    };

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 115.46: tier tablet memakai navigasi di baris atas konten, bukan
        // band kiri; label tetap terlihat karena navigasi tidak terlipat.
        if (adaptive.usesTopNavigation) ...[
          _AccountTopNavigation(
            key: const ValueKey('account-center-top-navigation'),
            activeSection: _activeOverviewSection(),
            sections: AccountCenterWideDesktopFrame.leftNavigation,
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
        ],
        main,
        // Ringkasan menumpuk di bawah pada tier yang tidak punya drawer.
        if (!drawerOpen &&
            adaptive.summaryPresentation ==
                AccountCenterSummaryPresentation.stackedBelow) ...[
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
          _shellRail(
            railWidth: mainWidth,
            data: data,
            gridPlan: gridPlan,
            operationalMetrics: operationalMetrics,
            natural: true,
          ),
        ],
      ],
    );

    // Band navigasi kiri + konten berdampingan. Pada tier tablet band kiri
    // nol, jadi konten memakai lebar penuh viewport (tanpa baris kosong).
    //
    // Tinggi terkunci viewport dipakai pada KEDUA jalur: band navigasi
    // memakai ListView (menolak tinggi tak terbatas) dan konten memakai
    // [_shellMain] `scrollable: true` yang butuh tinggi tak terbatas. Jadi
    // band navigasi merebut tinggi viewport, konten bergulir di dalam
    // Column-nya sendiri — bukan Column yang melebihi viewport.
    final scrolledContent = SingleChildScrollView(
      key: const ValueKey('account-center-adaptive-content'),
      child: contentColumn,
    );
    final body = adaptive.navigationWidth == 0
        ? SizedBox(height: shellHeight, child: scrolledContent)
        : SizedBox(
            height: shellHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                navigationBand(),
                SizedBox(width: mainWidth, child: scrolledContent),
              ],
            ),
          );

    return Stack(
      children: [
        Padding(
          // Padding halaman memakai kedua sumbu: 115.5 memverifikasi nilai
          // token ini pada widget yang dirender, jadi jalur adaptif tidak
          // boleh melompati padding vertikal.
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: AccountCenterDesignTokens.layout.pageVerticalPadding,
          ),
          child: body,
        ),
        // 115.46 — drawer memakai lebar token ringkasan dan tidak pernah
        // menutupi navigasi; isinya tetap [_AccountSummaryRail] yang sama
        // dengan jalur lain, jadi tidak ada ringkasan kedua yang dikarang.
        summaryDrawer,
        if (adaptive.summaryPresentation ==
            AccountCenterSummaryPresentation.drawer)
          Align(
            alignment: Alignment.topRight,
            child: Semantics(
              label: 'Account summary',
              child: IconButton(
                key: const ValueKey('account-center-drawer-toggle'),
                tooltip: drawerOpen
                    ? 'Hide account summary'
                    : 'Show account summary',
                onPressed: () => setState(() {
                  _summaryDrawerOpen = !_summaryDrawerOpen;
                  _announceSummaryDrawer(open: _summaryDrawerOpen);
                }),
                icon: Icon(
                  drawerOpen ? Icons.close : Icons.unfold_more,
                  size: AccountCenterDesignTokens.iconSizes.action,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 115.45 — frame `wide_desktop`: left navigation, main grid, right rail,
  /// dan status bar, semuanya dari geometri kontrak
  /// [AccountCenterWideDesktopFrame] (bukan heuristik piksel).
  ///
  /// Tinggi terkunci per band, jadi grid TIDAK pernah memanjang: kartu
  /// menggulir di dalam dirinya dan rail menggulir di dalam bandnya
  /// (scroll_containment).
  Widget _buildWideDesktopFrame({
    required BuildContext context,
    required AccountCenterFrameLayout frame,
    required AccountCloudSnapshot data,
    required AsyncValue<AccountOperationalMetrics?> operationalMetrics,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: frame.pagePaddingHorizontal,
        vertical: frame.pagePaddingVertical,
      ),
      child: SizedBox(
        height: frame.viewportHeight - 2 * frame.pagePaddingVertical,
        child: Column(
          children: [
            // Baris utama: left navigation | main grid | right rail. Tinggi
            // terkunci oleh [frame.gridHeight] sehingga halaman tidak memanjang.
            SizedBox(
              height: frame.gridHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AccountLeftNavigation(
                    key: const ValueKey('account-center-left-navigation'),
                    width: frame.leftNavigationWidth,
                    activeSection: _activeOverviewSection(),
                  ),
                  SizedBox(
                    key: const ValueKey('account-center-main-grid'),
                    width: frame.mainWidth,
                    child: _shellMain(
                      mainWidth: frame.mainWidth,
                      data: data,
                      gridPlan: AccountCenterResponsiveGrid.resolve(
                        frame.viewportWidth,
                      ),
                      scrollable: false,
                      frame: frame,
                    ),
                  ),
                  _AccountSummaryRailFrame(
                    key: const ValueKey('account-center-right-rail'),
                    width: frame.rightRailWidth,
                    snapshot: data,
                    operationalMetrics: operationalMetrics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AccountCenterWideDesktopFrame.rowGap),
            _AccountStatusBar(
              key: const ValueKey('account-center-status-bar'),
              height: frame.statusBarHeight,
              snapshot: data,
            ),
          ],
        ),
      ),
    );
  }

  /// Section overview yang sedang aktif — dipakai untuk menandai entri left
  /// navigation. Tab aktif dipetakan ke section kanoniknya lewat urutan
  /// [AccountCenterWideDesktopFrame.leftNavigation].
  String _activeOverviewSection() {
    final index = AccountCenterInformationArchitecture.tabs.indexOf(_tab);
    final sections = <String>[
      'authentication',
      'connected_services',
      'cloud_storage_usage',
      'quick_connect',
      'api_keys_summary',
      'team_summary',
      'security_summary',
      'backup_sync_summary',
      'security_summary',
    ];
    if (index < 0 || index >= sections.length) {
      return 'authentication';
    }
    return sections[index];
  }

  /// Area utama shell: chrome atas lalu grid tiga baris mockup.
  ///
  /// Dipakai oleh tier `wide_desktop` (lebar 75%) dan tier lain yang
  /// menumpuk rail di bawah lewat [Expanded].
  Widget _shellMain({
    required double mainWidth,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required bool scrollable,
    AccountCenterFrameLayout? frame,

    /// 115.47: hanya diisi dari jalur tier mobile; tile provider membuka
    /// sheet layar penuh. Tier lain membiarkan null.
    ValueChanged<ProviderConnectorEntry>? onOpenProviderDetails,
  }) {
    final area = _FocusedAccountArea(
      tab: _tab,
      snapshot: data,
      gridPlan: gridPlan,
      frame: frame,
      onOpenProviderDetails: onOpenProviderDetails,
      providerManifest:
          widget.providerManifest ?? ProviderConnectorManifest.standard,
      onConnectProvider: widget.onConnectProvider,
      onSyncNow: widget.onSyncNow,
      onSignIn:
          // 115.52: `connectionStateOf` menggantikan `service(...)`: snapshot
          // yang tidak memuat `email-sign-in` berarti belum terhubung, bukan
          // error yang menjatuhkan seluruh halaman.
          data.connectionStateOf('email-sign-in') ==
              AccountCloudConnectionState.connected
          ? null
          : widget.onSignIn ??
                () => context.push('${AppRoutes.login}?from=account-cloud'),
      onOpenAiProviders:
          widget.onOpenAiProviders ?? () => context.push(AppRoutes.aiProviders),
      onOpenSecurity: () => context.push(AppRoutes.security),
    );
    return SizedBox(
      width: mainWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AccountCenterDesignTokens.spacing.md),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    AccountCenterDesignTokens.radius.tile,
                  ),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: context.palette.primaryBright,
                  size: AccountCenterDesignTokens.iconSizes.page,
                ),
              ),
              SizedBox(width: AccountCenterDesignTokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACCOUNT & CLOUD CENTER', style: _pageTitle),
                    SizedBox(height: AccountCenterDesignTokens.spacing.xs),
                    Text(
                      'Kelola akun, koneksi, cloud, dan integrasi layanan Anda',
                      style: _body.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: AccountCenterAccessibility.searchSemanticsLabel,
                button: true,
                child: IconButton(
                  tooltip: widget.onSearch == null
                      ? AccountCenterAccessibility.searchSemanticsLabel
                      : 'Search',
                  onPressed: widget.onSearch ?? _openAccountSearch,
                  icon: Icon(
                    Icons.search,
                    size: AccountCenterDesignTokens.iconSizes.action,
                  ),
                ),
              ),
              Semantics(
                label: widget.onNotifications == null
                    ? AccountCenterAccessibility.notificationsSemanticsLabel
                    : 'Notifications',
                button: widget.onNotifications != null,
                enabled: widget.onNotifications != null,
                child: IconButton(
                  tooltip: widget.onNotifications == null
                      ? AccountCenterAccessibility.notificationsSemanticsLabel
                      : 'Notifications',
                  onPressed: widget.onNotifications,
                  icon: Icon(
                    Icons.notifications_none,
                    size: AccountCenterDesignTokens.iconSizes.action,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.sm),
          Text(
            AccountCenterInformationArchitecture.breadcrumbsFor(
              _tab,
            ).join(' / '),
            key: const ValueKey('account-center-breadcrumb'),
            style: _caption.copyWith(color: context.palette.textSecondary),
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
          // 115.46: `scrollable_tabs` — strip digulir mendatar pada semua
          // tier; key stabil dipakai test adaptif untuk membuktikan tab aktif
          // bertahan saat viewport berpindah tier.
          SingleChildScrollView(
            key: const ValueKey('account-center-tab-strip'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in AccountCenterInformationArchitecture.tabs)
                  _CenterTab(
                    label: tab.label,
                    active: tab == _tab,
                    onTap: () => _selectTab(tab),
                  ),
              ],
            ),
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.xl),
          // 115.36: grid mengisi sisa tinggi viewport sehingga seluruh panel
          // muat tanpa scroll luar di tier `wide_desktop` — `Expanded` memberi
          // batas keras dan kartu di dalamnya yang menyusut atau menggulir.
          //
          // Tier selain `wide_desktop` memakai jalur scroll: chrome boleh lebih
          // tinggi dari viewport (textScale 200% = 812.8px pada 484.8px share
          // `flex:3`), jadi area utama memakai tinggi natural, [_RowCards] yang
          // menggulir, dan [_shellMain] sudah dibungkus `SingleChildScrollView`
          // di pemanggilnya.
          if (scrollable) area else Expanded(child: area),
        ],
      ),
    );
  }

  /// Rail ringkasan shell, meluap ke bawah pada tier sempit.
  Widget _shellRail({
    required double railWidth,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required AsyncValue<AccountOperationalMetrics?> operationalMetrics,
    required bool natural,
  }) {
    final rail = _AccountSummaryRail(
      plan: gridPlan,
      snapshot: data,
      operationalMetrics: operationalMetrics,
      onSyncNow: widget.onSyncNow,
      onBackupProject: widget.onBackupProject,
      onOpenAiProviders: widget.onOpenAiProviders,
      natural: natural,
    );
    return SizedBox(width: railWidth, child: rail);
  }

  /// Dua anak shell pada tier `wide_desktop`: area utama lalu rail ringkasan.
  List<Widget> _shellChildren({
    required double mainWidth,
    required double railWidth,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required AsyncValue<AccountOperationalMetrics?> operationalMetrics,
  }) {
    return [
      _shellMain(
        mainWidth: mainWidth,
        data: data,
        gridPlan: gridPlan,
        scrollable: false,
      ),
      _shellRail(
        railWidth: railWidth,
        data: data,
        gridPlan: gridPlan,
        operationalMetrics: operationalMetrics,
        natural: false,
      ),
    ];
  }
}

/// Kartu AUTHENTICATION mockup: foto profil, nama akun, email, jenis
/// subscription, aksi edit profil, dan sign-in methods beserta ikonnya —
/// semua dalam SATU kartu.
///
/// 115.36: sebelum ini sign-in methods berdiri sebagai kartu terpisah di area
/// Connected Accounts, sehingga surface autentikasi terpecah dan tidak punya
/// foto profil maupun subscription. Aturan satu kapabilitas = satu owner
/// kanonik tetap berlaku: daftar sign-in milik kartu ini, dan kartu
/// CONNECTED SERVICES OVERVIEW tetap meringkas storage/sync saja.
class _AuthenticationProfileCard extends StatelessWidget {
  const _AuthenticationProfileCard({
    required this.snapshot,
    required this.onSignIn,
    required this.onEditProfile,
  });

  final AccountCloudSnapshot snapshot;

  /// Aksi "Sign in or connect account".
  ///
  /// 115.36: kartu ini menggantikan kartu sign-in terpisah, jadi aksi ini
  /// pindah ke sini. Function-nya sama persis — hanya owner-nya yang
  /// berubah, mengikuti aturan satu kapabilitas = satu owner kanonik.
  final VoidCallback onSignIn;

  final VoidCallback onEditProfile;

  /// Ikon per provider sign-in.
  ///
  /// Tidak ada material icon resmi untuk tiap brand, jadi glyph marcap yang
  /// dipakai konsisten untuk seluruh aplikasi (lihat [_ProviderIcon]) dipakai
  /// ulang agar kartu ini tidak memperkenalkan kosmetik kedua.
  IconData _iconFor(AccountCloudServiceGroup group) => switch (group) {
    AccountCloudServiceGroup.signIn => Icons.alternate_email,
    AccountCloudServiceGroup.cloudStorage => Icons.cloud_outlined,
    AccountCloudServiceGroup.localStorage => Icons.folder_outlined,
    AccountCloudServiceGroup.sync => Icons.sync_outlined,
  };

  /// 115.36: mockup menandai tiap metode sign-in dengan brand icon-nya sendiri,
  /// bukan satu ikon generik per group. Ikon memakai set Material bawaan yang
  /// sudah ada di bundle — tidak ada aset baru.
  IconData _signInIconFor(AccountCloudService service) => switch (service.id) {
    'email-sign-in' => Icons.mail_outline,
    'google-sign-in' => Icons.g_mobiledata,
    'microsoft-sign-in' => Icons.window,
    'github-sign-in' => Icons.code,
    'apple-sign-in' => Icons.phone_iphone,
    _ => _iconFor(service.group),
  };

  @override
  Widget build(BuildContext context) {
    final profile = AuthenticationProfileCard.authenticated(
      avatar: const ProfileAvatar.initials('VS'),
      displayName: snapshot.accountDisplayName,
      email: snapshot.accountEmail ?? 'No email on this local session',
      plan: _planFrom(snapshot),
      signInMethods: _signInMethods,
      primaryIdentity: SignInMethod.email,
    );

    return LayoutBuilder(
      builder: (context, cardConstraints) => Row(
        // 115.36: mockup menaruh kartu ini dalam DUA kolom — identitas di
        // kiri (avatar, nama, email, plan, Edit Profile) dan daftar metode
        // sign-in di kanan (panel berborder + tombol Add Another Method).
        // Proporsi mengikuti mockup: kolom kiri ~40%, kolom kanan ~58%.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: cardConstraints.maxWidth * 0.4,
            child: _profileColumn(context, profile),
          ),
          SizedBox(width: AccountCenterDesignTokens.spacing.md),
          Expanded(child: _signInMethodsPanel(context, profile)),
        ],
      ),
    );
  }

  /// Kolom kiri mockup: avatar besar, nama, email, badge plan, Edit Profile.
  Widget _profileColumn(
    BuildContext context,
    AuthenticationProfileCard profile,
  ) => Column(
    key: const ValueKey('account-auth-profile-column'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: _ProfileAvatar(
          key: const ValueKey('account-profile-avatar'),
          avatar: profile.avatar,
        ),
      ),
      SizedBox(height: AccountCenterDesignTokens.spacing.sm),
      Text(
        profile.displayName,
        key: const ValueKey('account-profile-name'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: _body.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
      Text(
        profile.email,
        key: const ValueKey('account-profile-email'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: _caption.copyWith(color: context.palette.textSecondary),
      ),
      SizedBox(height: AccountCenterDesignTokens.spacing.sm),
      Center(
        child: _PlanBadge(
          key: const ValueKey('account-profile-subscription'),
          plan: profile.plan,
        ),
      ),
      SizedBox(height: AccountCenterDesignTokens.spacing.md),
      SizedBox(
        height: AccountCenterDesignTokens.density.minimumTouchTarget,
        child: OutlinedButton.icon(
          onPressed: onEditProfile,
          icon: Icon(
            Icons.settings_outlined,
            size: AccountCenterDesignTokens.iconSizes.action,
          ),
          label: const Text(
            'Edit Profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(
              0,
              AccountCenterDesignTokens.density.minimumTouchTarget,
            ),
          ),
        ),
      ),
    ],
  );

  /// Kolom kanan mockup: panel berborder berisi daftar metode sign-in dan
  /// tombol "+ Add Another Method" di dasar panel.
  Widget _signInMethodsPanel(
    BuildContext context,
    AuthenticationProfileCard profile,
  ) => Container(
    key: const ValueKey('account-auth-methods-panel'),
    padding: EdgeInsets.all(AccountCenterDesignTokens.card.padding),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.tile,
      ),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SIGN IN METHODS',
          style: _caption.copyWith(
            color: context.palette.primaryBright,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
        Text(
          'Manage how you sign in to your account',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _caption.copyWith(color: context.palette.textMuted),
        ),
        SizedBox(height: AccountCenterDesignTokens.spacing.sm),
        // Kartu grid digulir oleh _DashboardCard, jadi daftar ini tidak boleh
        // membawa scroll kedua (nested viewport membuat tinggi tak terbatas).
        for (final service in _signInServices)
          _SignInMethodRow(
            key: ValueKey('account-sign-in-method-${service.id}'),
            icon: _signInIconFor(service),
            label: _signInLabelFor(service),
            state: service.state,
            primary: service.id == 'email-sign-in',
            account: service.id == 'email-sign-in'
                ? (snapshot.accountEmail ?? profile.email)
                : null,
          ),
        SizedBox(height: AccountCenterDesignTokens.spacing.sm),
        SizedBox(
          width: double.infinity,
          height: AccountCenterDesignTokens.density.minimumTouchTarget,
          child: OutlinedButton.icon(
            onPressed: onSignIn,
            icon: Icon(
              Icons.add,
              size: AccountCenterDesignTokens.iconSizes.action,
            ),
            label: const Text(
              '+ Add Another Method',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(
                0,
                AccountCenterDesignTokens.density.minimumTouchTarget,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// Metode sign-in kanonik, diturunkan dari snapshot yang sama dengan kartu
  /// overview lama supaya tidak ada dua sumber kebenaran.
  List<AccountCloudService> get _signInServices => snapshot.services
      .where((service) => service.group == AccountCloudServiceGroup.signIn)
      .toList(growable: false);

  /// Label persis seperti mockup. Snapshot menyimpan `Email sign-in`
  /// sebagai ID deskriptif, sedangkan mockup menampilkan `Email`.
  String _signInLabelFor(AccountCloudService service) => switch (service.id) {
    'email-sign-in' => 'Email',
    'apple-sign-in' => 'Apple ID',
    _ => service.label,
  };

  List<SignInMethod> get _signInMethods => const [
    SignInMethod.email,
    SignInMethod.google,
    SignInMethod.github,
  ];

  /// Subscription lokal dipetakan dari mode akun, karena belum ada billing
  /// service yang terhubung pada build ini.
  AccountPlan _planFrom(AccountCloudSnapshot snapshot) {
    final authenticated =
        snapshot.connectionStateOf('email-sign-in') ==
        AccountCloudConnectionState.connected;
    return authenticated ? AccountPlan.pro : AccountPlan.free;
  }
}

/// Avatar profil: gambar, inisial, atau placeholder tanpa gambar.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({super.key, required this.avatar});

  final ProfileAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AccountCenterDesignTokens.radius.tile);
    return switch (avatar.kind) {
      ProfileAvatarKind.image => ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          avatar.value!,
          width: AccountCenterDesignTokens.avatarSizes.image,
          height: AccountCenterDesignTokens.avatarSizes.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              const _InitialsAvatar(initials: 'VS'),
        ),
      ),
      ProfileAvatarKind.initials => _InitialsAvatar(initials: avatar.value!),
      ProfileAvatarKind.none => Container(
        width: AccountCenterDesignTokens.avatarSizes.image,
        height: AccountCenterDesignTokens.avatarSizes.image,
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: radius,
        ),
        child: Icon(
          Icons.person_outline,
          color: context.palette.textMuted,
          size: AccountCenterDesignTokens.iconSizes.page,
        ),
      ),
    };
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: AccountCenterDesignTokens.avatarSizes.image,
    height: AccountCenterDesignTokens.avatarSizes.image,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.palette.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.tile,
      ),
    ),
    child: Text(
      initials,
      style: _body.copyWith(
        color: context.palette.primaryBright,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({super.key, required this.plan});

  final AccountPlan plan;

  String get _label => switch (plan) {
    AccountPlan.free => 'FREE PLAN',
    AccountPlan.pro => 'PRO PLAN',
    AccountPlan.team => 'TEAM PLAN',
    AccountPlan.enterprise => 'ENTERPRISE PLAN',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.palette.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.pill,
      ),
    ),
    child: Text(
      _label,
      style: _caption.copyWith(
        color: context.palette.primaryBright,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
  );
}

class _SignInMethodRow extends StatelessWidget {
  const _SignInMethodRow({
    super.key,
    required this.icon,
    required this.label,
    required this.state,
    this.primary = false,
    this.account,
  });

  final IconData icon;
  final String label;
  final AccountCloudConnectionState state;

  /// 115.36: mockup menandai baris email sebagai `Primary` dan sisanya
  /// `Connected`, memakai titik hijau + teks, bukan badge berlabel panjang.
  final bool primary;

  /// Identitas akun di baris kedua (email, handle, nama channel). Null untuk
  /// provider yang mockup tidak menampilkan identitasnya.
  final String? account;

  @override
  Widget build(BuildContext context) {
    final connected = state == AccountCloudConnectionState.connected;
    final statusLabel = primary
        ? 'Primary'
        : connected
        ? 'Connected'
        : 'Not connected';
    final statusColor = connected
        ? context.palette.success
        : context.palette.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: AccountCenterDesignTokens.iconSizes.action),
          SizedBox(width: AccountCenterDesignTokens.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caption.copyWith(
                    color: context.palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (account case final identity?) ...[
                  SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
                  Text(
                    identity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _caption.copyWith(color: context.palette.textMuted),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AccountCenterDesignTokens.spacing.twoXs),
          // Titik status + label, mengikuti mockup. Label boleh ellipsis
          // di kartu sempit lewat Flexible.
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AccountCenterDesignTokens.iconSizes.statusDot,
                  height: AccountCenterDesignTokens.iconSizes.statusDot,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AccountCenterDesignTokens.spacing.twoXs),
                Flexible(
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 115.47 — Action bar tier `mobile` (<600px).
///
/// Bar menempel di tepi bawah viewport, DI LUAR wilayah scroll konten, jadi
/// kartu terakhir tidak pernah tertutup (acceptance `safe_actions` +
/// `no_clipped_content`). Tingginya termasuk ruang aman OS: konten's
/// `contentBottomInset` memakai angka yang sama, jadi keduanya tidak bisa
/// menyimpang.
///
/// Setiap target memakai [AccountCenterMobileLayout.actionTargetHeight] yang
/// diturunkan dari `density.minimum_touch_target_px` (44) — bukan angka
/// karangan di presentation ini.
class _MobileActionBar extends StatelessWidget {
  const _MobileActionBar({
    super.key,
    required this.layout,
    required this.actions,
  });

  final AccountCenterMobileLayout layout;

  /// `onTap` null berarti aksi sengaja dimatikan (mis. tidak ada provider
  /// yang boleh dihubungkan). Slotnya tetap dirender supaya geometri bar dan
  /// target sentuhnya tidak berubah; `IconButton.onPressed` yang null membuat
  /// target itu non-interaktif, bukan kontrol mati.
  final List<({String key, IconData icon, VoidCallback? onTap})> actions;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: layout.actionBarHeight,
      color: context.palette.surface,
      padding: EdgeInsets.symmetric(
        horizontal: AccountCenterDesignTokens.spacing.twoXs,
        vertical: AccountCenterDesignTokens.spacing.twoXs,
      ),
      child: Row(
        children: [
          for (final action in actions)
            Expanded(
              child: Semantics(
                label: 'Account ${action.key}',
                button: true,
                enabled: action.onTap != null,
                child: SizedBox(
                  key: ValueKey('account-center-mobile-action-${action.key}'),
                  height: layout.actionTargetHeight,
                  child: IconButton(
                    tooltip: 'Account ${action.key}',
                    onPressed: action.onTap,
                    icon: Icon(
                      action.icon,
                      size: AccountCenterDesignTokens.iconSizes.action,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    // Ruang aman OS menambah tinggi total, bukan tinggi bar: bar tetap
    // 52px (44 + 2*4) dan ruang kosongnya ada DI BAWAH bar.
    if (layout.safeAreaBottom <= 0) {
      return bar;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        SizedBox(height: layout.safeAreaBottom),
      ],
    );
  }
}

/// 115.47 — Sheet layar penuh untuk detail provider pada tier `mobile`.
///
/// Spec tier mobile: "provider details open as full-screen sheet". Isinya
/// DITURUNKAN dari entry connector yang sama (manifest 115.15) — bukan
/// ringkasan provider kedua yang dikarang di sini, dan bukan nilai provider
/// yang dihitung ulang.
///
/// Baris detail memakai label yang sudah ada di [_ProviderTile] supaya isi
/// sheet dan tile tidak bisa berbeda.
class _MobileProviderDetailsSheet extends StatelessWidget {
  const _MobileProviderDetailsSheet({
    super.key,
    required this.entry,
    required this.layout,
    required this.canConnect,
    required this.onClose,
    this.onConnect,
  });

  final ProviderConnectorEntry entry;
  final AccountCenterMobileLayout layout;
  final bool canConnect;
  final VoidCallback? onConnect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      (label: 'Category', value: entry.category.wireName),
      (label: 'Availability', value: entry.availability.wireName),
      (
        label: 'Connection',
        value: _providerConnectionLabel(entry.availability),
      ),
      (label: 'Auth type', value: entry.authType.wireName),
      (label: 'Connector version', value: entry.connectorVersion),
      (
        label: 'Regions',
        value: entry.regions.map((region) => region.wireName).join(', '),
      ),
      (
        label: 'Capabilities',
        value: entry.capabilities
            .map((capability) => capability.wireName)
            .join(', '),
      ),
      (
        label: 'Permissions',
        value: entry.permissions
            .map((permission) => permission.wireName)
            .join(', '),
      ),
    ];
    return Positioned.fill(
      child: Semantics(
        container: true,
        label: AccountCenterAccessibility.providerSemanticsLabel(
          entry.displayName,
          _providerConnectionLabel(entry.availability),
        ),
        child: Material(
          color: context.palette.background,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  // Tanpa `const`: `layout` adalah token instan sehingga
                  // pembacaan field-nya tidak sah dalam ekspresi konstanta
                  // Dart (pola yang sama pada 115.5 dan 115.46).
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        AccountCenterDesignTokens.layout.pageHorizontalPadding,
                    vertical: AccountCenterDesignTokens.spacing.md,
                  ),
                  child: Row(
                    children: [
                      _ProviderIcon(entry: entry),
                      SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.displayName,
                              style: _sectionTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _providerAvailabilityLabel(entry.availability),
                              style: _caption,
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label: 'Close provider details',
                        button: true,
                        child: SizedBox(
                          key: const ValueKey(
                            'account-center-provider-details-close',
                          ),
                          height: layout.actionTargetHeight,
                          width: layout.actionTargetHeight,
                          child: IconButton(
                            tooltip: 'Close provider details',
                            onPressed: onClose,
                            icon: Icon(
                              Icons.close,
                              size: AccountCenterDesignTokens.iconSizes.action,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    // Tanpa `const`: token instan tidak boleh dibaca dalam
                    // ekspresi konstanta Dart (pola 115.5/115.46).
                    padding: EdgeInsets.symmetric(
                      horizontal: AccountCenterDesignTokens
                          .layout
                          .pageHorizontalPadding,
                    ),
                    children: [
                      for (final detail in details)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(detail.label, style: _caption),
                          subtitle: Text(
                            detail.value,
                            style: _body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: AccountCenterDesignTokens.spacing.md),
                      // Aksi connect memakai callback yang sudah ada
                      // (115.15). Tanpa callback, aksi tidak dibuat —
                      // status "Not available" sudah jujur dan tombol mati
                      // hanya menambah noise.
                      if (onConnect != null)
                        SizedBox(
                          height: layout.actionTargetHeight,
                          child: FilledButton(
                            onPressed: canConnect && entry.isConnectable
                                ? onConnect
                                : null,
                            child: Text(
                              entry.isConnectable ? 'Connect' : 'Not available',
                            ),
                          ),
                        ),
                      SizedBox(height: AccountCenterDesignTokens.spacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 115.45 — Band left navigation frame `wide_desktop`.
///
/// Lebar, urutan entri, dan isi berasal dari kontrak
/// [AccountCenterWideDesktopFrame.leftNavigation] (`overview_sections` spec).
/// Entri bersifat struktural (seam navigasi area kanonik), bukan filter: tab
/// strip dan baris grid tetap satu-satunya seam scroll/interaksi, jadi slice
/// ini tidak menambah perilaku baru di luar kontrak.
class _AccountLeftNavigation extends StatelessWidget {
  const _AccountLeftNavigation({
    super.key,
    required this.width,
    required this.activeSection,
  });

  final double width;

  /// Section kanonik yang sedang aktif; entri lain tampil netral.
  final String activeSection;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: context.palette.textMuted.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
    ),
    padding: EdgeInsets.only(
      right: AccountCenterDesignTokens.spacing.md,
      top: AccountCenterDesignTokens.spacing.twoXs,
    ),
    child: Semantics(
      container: true,
      label: 'Account sections',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final item in AccountCenterWideDesktopFrame.leftNavigation)
            Padding(
              padding: EdgeInsets.only(
                bottom: AccountCenterDesignTokens.spacing.twoXs,
              ),
              child: Row(
                children: [
                  Icon(
                    _AccountLeftNavigationIcon.resolve(item.iconKey),
                    size: AccountCenterDesignTokens.iconSizes.navigation,
                    color: context.palette.textSecondary,
                  ),
                  SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _caption.copyWith(
                        color: item.section == activeSection
                            ? context.palette.primaryBright
                            : context.palette.textSecondary,
                        fontWeight: item.section == activeSection
                            ? FontWeight.w600
                            : _caption.fontWeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// 115.46 — Navigasi terlipat untuk tier `compact_desktop` (900-1179).
///
/// Hanya ikon; label [_AccountLeftNavigation] disembunyikan agar rail 52px
/// benar-benar cukup. Lebar band bukan angka karangan: nilainya
/// dari [AccountCenterDesktopTabletAdaptation.collapsedRailWidth], yang
/// diturunkan dari target sentuh minimum + padding.
class _AccountCollapsedNavRail extends StatelessWidget {
  const _AccountCollapsedNavRail({
    super.key,
    required this.width,
    required this.activeSection,
  });

  final double width;
  final String activeSection;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: context.palette.textMuted.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
    ),
    // Navigasi terlipat: setiap entri memakai tinggi/ lebar target sentuh
    // 44px sehingga rail masih bisa diklik dan dibaca pembaca layar.
    padding: EdgeInsets.only(
      right: AccountCenterDesignTokens.spacing.twoXs,
      top: AccountCenterDesignTokens.spacing.twoXs,
    ),
    child: Semantics(
      container: true,
      label: 'Account sections',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final item in AccountCenterWideDesktopFrame.leftNavigation)
            Padding(
              padding: EdgeInsets.only(
                bottom: AccountCenterDesignTokens.spacing.twoXs,
              ),
              // Label disembunyikan (bukan dihapus): ikon tetap punya semantics
              // label supaya pembaca layar tidak kehilangan nama section.
              //
              // 115.48: `button` DIHAPUS. Entri ini seam struktural tanpa
              // callback apa pun, jadi mengannounced-nya sebagai "tombol"
              // adalah affordance palsu — pembaca layar mengira ada aksi dan
              // pengguna sempat menekan sesuatu yang tidak terjadi.
              // `AccountCenterKeyboardScreenReader.navigationEntrySemantics`
              // mengunci aturan yang sama; label tetap terbaca.
              child: Semantics(
                label:
                    AccountCenterKeyboardScreenReader.navigationEntrySemantics(
                      label: item.label,
                      actionable: false,
                    ).label,
                child: Tooltip(
                  message: item.label,
                  child: SizedBox(
                    width: width - 2 * AccountCenterDesignTokens.spacing.twoXs,
                    height:
                        AccountCenterDesignTokens.density.minimumTouchTarget,
                    child: Icon(
                      _AccountLeftNavigationIcon.resolve(item.iconKey),
                      size: AccountCenterDesignTokens.iconSizes.navigation,
                      color: item.section == activeSection
                          ? context.palette.primaryBright
                          : context.palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Pemetaan ikon navigasi yang dipakai rail terlipat dan navigasi atas.
/// Dipisah dari [_AccountLeftNavigation] supaya kedua chrome memakai glyph
/// yang sama — dan tidak ada peta ikon kedua yang bisa menyimpang.
abstract final class _AccountLeftNavigationIcon {
  static const Map<String, IconData> _icons = <String, IconData>{
    'badge': Icons.badge_outlined,
    'bolt': Icons.bolt_outlined,
    'cloud': Icons.cloud_outlined,
    'hub': Icons.hub_outlined,
    'key': Icons.key_outlined,
    'groups': Icons.groups_outlined,
    'history': Icons.history_outlined,
    'sync': Icons.sync_outlined,
    'shield': Icons.security_outlined,
  };

  static IconData resolve(String iconKey) =>
      _icons[iconKey] ?? Icons.circle_outlined;
}

/// 115.46 — Navigasi baris atas untuk tier `tablet` (600-899).
///
/// Tidak ada band kiri pada tier ini ([AccountCenterDesktopTabletLayout
/// .navigationWidth] = 0), jadi navigasi pindah ke atas konten. Label tetap
/// terlihat karena tier ini tidak terlipat; barisnya juga bergulir mendatar
/// agar sembilan entri tidak memaksa lebar halaman.
class _AccountTopNavigation extends StatelessWidget {
  const _AccountTopNavigation({
    super.key,
    required this.activeSection,
    required this.sections,
  });

  final String activeSection;
  final List<AccountCenterLeftNavItem> sections;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Account sections',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in sections)
            Padding(
              padding: EdgeInsets.only(
                right: AccountCenterDesignTokens.spacing.sm,
              ),
              // 115.48: navigasi atas adalah seam struktural (scroll), bukan
              // pengalih tab — `button` tidak diklaim. Label tetap ada dan
              // `selected` tetap menandai section aktif.
              child: Semantics(
                selected: item.section == activeSection,
                label:
                    AccountCenterKeyboardScreenReader.navigationEntrySemantics(
                      label: item.label,
                      actionable: false,
                    ).label,
                child: Container(
                  height: AccountCenterDesignTokens.layout.tabBarHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: AccountCenterDesignTokens.spacing.sm,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _caption.copyWith(
                      color: item.section == activeSection
                          ? context.palette.primaryBright
                          : context.palette.textSecondary,
                      fontWeight: item.section == activeSection
                          ? FontWeight.w600
                          : _caption.fontWeight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// 115.45 — Status bar frame `wide_desktop`.
///
/// Isi SELALU diturunkan dari snapshot lokal lewat
/// [AccountCenterWideDesktopFrame.statusBarItems]; tidak ada nilai yang
/// difabrikasi dan tidak ada aksi baru yang ditambahkan di sini.
class _AccountStatusBar extends StatelessWidget {
  const _AccountStatusBar({
    super.key,
    required this.height,
    required this.snapshot,
  });

  final double height;
  final AccountCloudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = AccountCenterWideDesktopFrame.statusBarItems(snapshot);
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.palette.textMuted.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(
                right: AccountCenterDesignTokens.spacing.lg,
              ),
              child: Row(
                children: [
                  // Label dan nilai adalah dua `Text` terpisah supaya
                  // pembaca layar bisa membedakan kunci dan isinya.
                  Text(
                    item.label,
                    style: _caption.copyWith(color: context.palette.textMuted),
                  ),
                  SizedBox(width: AccountCenterDesignTokens.spacing.xs),
                  Text(item.value, style: _caption),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 115.45 — Right rail di dalam frame: band lebar terkunci dan kartu
/// bergulir di dalamnya, jadi panel luar tidak pernah memanjang.
class _AccountSummaryRailFrame extends StatelessWidget {
  const _AccountSummaryRailFrame({
    super.key,
    required this.width,
    required this.snapshot,
    required this.operationalMetrics,
  });

  final double width;
  final AccountCloudSnapshot snapshot;
  final AsyncValue<AccountOperationalMetrics?> operationalMetrics;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _AccountSummaryRail(
      plan: AccountCenterResponsiveGrid.resolve(width),
      snapshot: snapshot,
      operationalMetrics: operationalMetrics,
      natural: false,
    ),
  );
}

class _AccountSummaryRail extends StatelessWidget {
  const _AccountSummaryRail({
    required this.plan,
    required this.snapshot,
    required this.operationalMetrics,
    this.onSyncNow,
    this.onBackupProject,
    this.onOpenAiProviders,
    this.natural = false,
  });

  /// Rencana grid tier (115.6) — kolom ringkasan mengikuti batas tier dan
  /// aturan fit card.minWidth, bukan heuristik 760px.
  final AccountCenterGridPlan plan;

  /// 115.36: saat true (jalur scroll halaman di tier selain `wide_desktop`)
  /// rail memakai tinggi natural dan kartu di dalamnya boleh menggulir lewat
  /// `Wrap`, bukan `Expanded` yang butuh tinggi terkunci.
  final bool natural;
  final AccountCloudSnapshot snapshot;
  final AsyncValue<AccountOperationalMetrics?> operationalMetrics;
  final VoidCallback? onSyncNow;
  final VoidCallback? onBackupProject;
  final VoidCallback? onOpenAiProviders;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = plan.cardWidthFor(constraints.maxWidth);
      final cards = Wrap(
        spacing: AccountCenterDesignTokens.layout.cardGap,
        runSpacing: AccountCenterDesignTokens.layout.cardGap,
        children: [
          SizedBox(
            width: width,
            child: _PlanSummaryCard(snapshot: snapshot),
          ),
          SizedBox(width: width, child: const _CreditsCard()),
          SizedBox(
            width: width,
            child: _QuickActionsCard(
              onSyncNow: onSyncNow,
              onOpenAiProviders:
                  onOpenAiProviders ??
                  () => context.push(AppRoutes.aiProviders),
              onBackupProject:
                  onBackupProject ??
                  () => context.push(AppRoutes.projectBackups),
            ),
          ),
          SizedBox(
            width: constraints.maxWidth,
            child: _OperationalMetricsCards(
              metrics: operationalMetrics,
              cardWidth: width,
            ),
          ),
        ],
      );
      final header = Row(
        children: [
          Expanded(child: Text('ACCOUNT SUMMARY', style: _sectionTitle)),
          Icon(
            Icons.unfold_more,
            color: context.palette.textMuted,
            size: AccountCenterDesignTokens.iconSizes.section,
          ),
        ],
      );
      final gap = SizedBox(height: AccountCenterDesignTokens.spacing.md);
      // 115.36: di tier `wide_desktop` panel luar tidak digulir, jadi rail
      // mengisi sisa tinggi dan kartunya menggulir di dalam `Wrap`. Di jalur
      // scroll halaman (tier sempit) rail memakai tinggi natural dan ikut
      // bergulir bersama chrome.
      if (natural) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [header, gap, cards],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          gap,
          Expanded(child: SingleChildScrollView(child: cards)),
        ],
      );
    },
  );
}

class _OperationalMetricsCards extends StatelessWidget {
  const _OperationalMetricsCards({
    required this.metrics,
    required this.cardWidth,
  });

  final AsyncValue<AccountOperationalMetrics?> metrics;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final value = metrics.valueOrNull;
    final loading = metrics.isLoading && value == null;
    final failed = metrics.hasError && value == null;
    final usageMessage = loading
        ? 'Loading usage from the active project...'
        : failed
        ? 'Could not read active project metrics. Retry after checking the project session.'
        : value == null
        ? 'Open a project to inspect locally recorded AI usage.'
        : '${AccountCenterLocalizationFormatting.groupedInteger(value.totalTokens)} tokens\n'
              '\$${AccountCenterLocalizationFormatting.formatMoney(value.estimatedCost)} estimated';
    final storageMessage = loading
        ? 'Indexing storage for the active project...'
        : failed
        ? 'Could not read active project metrics. Retry after checking the project session.'
        : value == null
        ? 'Open a project to inspect its local storage distribution.'
        : _storageMessage(value);

    return Wrap(
      spacing: AccountCenterDesignTokens.layout.cardGap,
      runSpacing: AccountCenterDesignTokens.layout.cardGap,
      children: [
        SizedBox(
          width: cardWidth,
          child: _AiUsageMetricsCard(metrics: value, message: usageMessage),
        ),
        SizedBox(
          width: cardWidth,
          child: _StorageDistributionCard(
            metrics: value,
            message: storageMessage,
          ),
        ),
      ],
    );
  }

  static String _storageMessage(AccountOperationalMetrics metrics) {
    final total = metrics.totalStorageBytes;
    if (total <= 0) return '0 B indexed\nNo project files were found.';
    final categories = metrics.storageBytesByCategory.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final shares = categories
        .map(
          (entry) =>
              '${entry.key} '
              '${AccountCenterLocalizationFormatting.percentLabel(AccountCenterLocalizationFormatting.sharePercent(entry.value, total))}',
        )
        .join('\n');
    return '${AccountCenterLocalizationFormatting.storageUnits(total)} indexed${shares.isEmpty ? '' : '\n$shares'}';
  }
}

class _AiUsageMetricsCard extends StatelessWidget {
  const _AiUsageMetricsCard({required this.metrics, required this.message});

  final AccountOperationalMetrics? metrics;
  final String message;

  @override
  Widget build(BuildContext context) {
    final value = metrics;
    final promptShare = value == null || value.totalTokens == 0
        ? 0.0
        : value.promptTokens / value.totalTokens;
    return _DashboardCard(
      title: 'AI USAGE THIS MONTH',
      subtitle: 'Locally recorded usage and estimated provider cost',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 115.7: CustomPaint tanpa label akan hilang bagi screen reader;
          // alternatif teks dibangun dari fakta yang sama dengan teks terlihat.
          Semantics(
            image: true,
            label: AccountCenterAccessibility.chartTextAlternative(
              title: 'AI USAGE THIS MONTH',
              facts: message.split('\n'),
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 72,
                    child: CustomPaint(
                      key: const ValueKey('account-ai-usage-chart'),
                      painter: _UsageCompositionPainter(
                        promptShare: promptShare,
                        color: context.palette.primaryBright,
                        trackColor: context.palette.borderSoft,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  SizedBox(height: AccountCenterDesignTokens.spacing.sm),
                  Text(message, style: _body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageDistributionCard extends StatelessWidget {
  const _StorageDistributionCard({
    required this.metrics,
    required this.message,
  });

  final AccountOperationalMetrics? metrics;
  final String message;

  @override
  Widget build(BuildContext context) {
    final entries =
        metrics?.storageBytesByCategory.entries.toList() ?? const [];
    return _DashboardCard(
      title: 'STORAGE DISTRIBUTION',
      subtitle: 'Active project files by media category',
      // 115.7: donut + teks diringkas jadi satu node Semantics image dengan
      // Judul + fakta yang sama seperti yang terlihat.
      child: Semantics(
        image: true,
        label: AccountCenterAccessibility.chartTextAlternative(
          title: 'STORAGE DISTRIBUTION',
          facts: message.split('\n'),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CustomPaint(
                  key: const ValueKey('account-storage-donut'),
                  painter: _StorageDonutPainter(
                    values: entries.map((entry) => entry.value).toList(),
                    colors: [
                      context.palette.primaryBright,
                      context.palette.info,
                      context.palette.warning,
                      context.palette.success,
                      context.palette.textMuted,
                    ],
                    trackColor: context.palette.borderSoft,
                  ),
                ),
              ),
              SizedBox(width: AccountCenterDesignTokens.spacing.md),
              Expanded(child: Text(message, style: _body)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageCompositionPainter extends CustomPainter {
  const _UsageCompositionPainter({
    required this.promptShare,
    required this.color,
    required this.trackColor,
  });

  final double promptShare;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 12;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), track);
    final progress = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final safeShare = promptShare.clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width * safeShare, 12),
      progress,
    );
    canvas.drawCircle(
      Offset(size.width * safeShare, 12),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_UsageCompositionPainter oldDelegate) =>
      oldDelegate.promptShare != promptShare ||
      // 115.53: `trackColor` TIDAK boleh diabaikan. `RenderCustomPaint.
      // _didUpdatePainter` melewati `markNeedsPaint()` ketika
      // `shouldRepaint` false, jadi satu-satunya cara painter tahu palet
      // berganti adalah lewat perbandingan di sini. Sebelumnya hanya
      // `promptShare` dan `color` yang dibandingkan, sehinggapertukaran
      // tema yang hanya mengubah `borderSoft` (track) meninggalkan track
      // lama di layar sementara chrome di sekitarnya sudah mengecat ulang.
      AccountCenterPerformanceResilience.chartPalette(
            values: const <int>[],
            colors: <int>[color.toARGB32()],
            trackColor: trackColor.toARGB32(),
          ).toString() !=
          AccountCenterPerformanceResilience.chartPalette(
            values: const <int>[],
            colors: <int>[oldDelegate.color.toARGB32()],
            trackColor: oldDelegate.trackColor.toARGB32(),
          ).toString();
}

class _StorageDonutPainter extends CustomPainter {
  const _StorageDonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<int> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final stroke = size.shortestSide * .18;
    final base = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.283185, false, base);
    if (total == 0) return;
    var start = -1.570796;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * 6.283185;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_StorageDonutPainter oldDelegate) =>
      // 115.53: `values.toString()` saja TIDAK cukup. Irisan memakai
      // `colors` dan track memakai `trackColor`; kalau keduanya tidak
      // dibandingkan, `RenderCustomPaint` melewati `markNeedsPaint()` dan
      // donut tetap memakai tinta palet LAMA setelah tema berganti —
      // persis cacat yang step ini temukan di kedua painter chart.
      AccountCenterPerformanceResilience.chartPalette(
        values: values,
        colors: colors.map((color) => color.toARGB32()).toList(),
        trackColor: trackColor.toARGB32(),
      ).toString() !=
      AccountCenterPerformanceResilience.chartPalette(
        values: oldDelegate.values,
        colors: oldDelegate.colors.map((color) => color.toARGB32()).toList(),
        trackColor: oldDelegate.trackColor.toARGB32(),
      ).toString();
}

// 115.49: integer, byte, percentage, and money formatting live in
// AccountCenterLocalizationFormatting; this file no longer owns formatters.

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.snapshot});

  final AccountCloudSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: 'PLAN',
    subtitle: 'Current account access',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          size: AccountCenterDesignTokens.iconSizes.section,
          color: context.palette.primaryBright,
        ),
        SizedBox(width: AccountCenterDesignTokens.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.accountModeLabel,
                style: VoidTypography.headingMedium,
              ),
              SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
              Text(snapshot.accountDisplayName, style: _body),
              SizedBox(height: AccountCenterDesignTokens.spacing.sm),
              Text(
                'Subscription details are not available locally.',
                style: _caption,
              ),
              SizedBox(height: AccountCenterDesignTokens.spacing.md),
              // 115.52: entri yang absen berarti "Not connected", bukan crash.
              _ConnectionBadge(
                state: snapshot.connectionStateOf('email-sign-in'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard();

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: 'CREDITS & TOKENS',
    subtitle: 'Live balances from connected services',
    child: Wrap(
      spacing: AccountCenterDesignTokens.spacing.sm,
      runSpacing: AccountCenterDesignTokens.spacing.sm,
      children: const [
        _MetricTile(label: 'AI Credits', value: 'Unavailable'),
        _MetricTile(label: 'Render Credits', value: 'Unavailable'),
        _MetricTile(label: 'Cloud Storage', value: 'Local only'),
        _MetricTile(label: 'Team Seats', value: 'Unavailable'),
      ],
    ),
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 142,
    padding: EdgeInsets.all(AccountCenterDesignTokens.spacing.sm),
    decoration: BoxDecoration(
      color: context.palette.background,
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.tile,
      ),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _caption),
        SizedBox(height: AccountCenterDesignTokens.spacing.xs),
        Text(value, style: _metric),
      ],
    ),
  );
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onOpenAiProviders,
    required this.onBackupProject,
    this.onSyncNow,
  });

  final VoidCallback? onSyncNow;
  final VoidCallback onOpenAiProviders;
  final VoidCallback onBackupProject;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: 'QUICK ACTIONS',
    subtitle: 'Available local account actions',
    child: Column(
      children: [
        _ActionRow(
          label: 'Sync Now',
          description: onSyncNow == null
              ? 'Connect a sync provider to enable this action'
              : 'Synchronize connected services',
          onPressed: onSyncNow,
        ),
        _ActionRow(
          label: 'Backup Project',
          description: 'Open local project backups',
          onPressed: onBackupProject,
        ),
        _ActionRow(
          label: 'AI Providers',
          description: 'Connect and test OpenAI or Gemini',
          onPressed: onOpenAiProviders,
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.description,
    this.onPressed,
  });

  final String label;
  final String description;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onPressed,
      leading: Icon(
        onPressed == null ? Icons.block_outlined : Icons.arrow_forward_ios,
        size: AccountCenterDesignTokens.iconSizes.action,
        color: onPressed == null ? context.palette.textMuted : null,
      ),
      title: Text(
        label,
        style: _body.copyWith(
          color: onPressed == null ? context.palette.textMuted : null,
        ),
      ),
      subtitle: Text(description, style: _caption),
      trailing: onPressed == null
          ? null
          : Icon(
              Icons.chevron_right,
              size: AccountCenterDesignTokens.iconSizes.action,
            ),
    ),
  );
}

class _OverviewCapabilityCard extends StatelessWidget {
  const _OverviewCapabilityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.message,
    this.fillHeight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String message;

  /// 115.36: kartu capability hidup di dalam baris mockup yang tingginya
  /// terkunci. Tanpa flag ini kartu shrink-wrap di dalam `Row` ber-`stretch`
  /// dan isinya meluap 9.2px (baris 2) / 103px (baris 3).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: title,
    subtitle: subtitle,
    fillHeight: fillHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AccountCenterDesignTokens.iconSizes.section,
          color: context.palette.primaryBright,
        ),
        SizedBox(width: AccountCenterDesignTokens.spacing.md),
        Expanded(child: Text(message, style: _body)),
      ],
    ),
  );
}

/// 115.36 — Panel tunggal Account & Cloud Center.
///
/// Sembilan area kanonik dirender berurutan dalam satu panel scroll. Setiap
/// area punya anchor yang bisa diukur, sehingga tab strip dan deep link
/// `?tab=` menggulir ke area terkait alih-alih menyembunyikan yang lain.
class _FocusedAccountArea extends StatelessWidget {
  const _FocusedAccountArea({
    required this.tab,
    required this.snapshot,
    required this.gridPlan,
    required this.providerManifest,
    required this.onConnectProvider,
    required this.onSyncNow,
    this.onOpenProviderDetails,
    this.frame,
    this.onSignIn,
    this.onOpenAiProviders,
    this.onOpenSecurity,
  });

  final AccountCenterTab tab;
  final AccountCloudSnapshot snapshot;

  /// Rencana grid yang sudah diresolusi dari lebar viewport oleh pemanggil.
  final AccountCenterGridPlan gridPlan;

  /// 115.45: geometri frame wide desktop. Null pada jalur responsif di bawah
  /// 1440, yang memakai perhitungan tinggi baris lamanya.
  final AccountCenterFrameLayout? frame;

  final ProviderConnectorManifest providerManifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;

  /// 115.47: tier mobile membuka detail provider sebagai sheet layar penuh.
  /// Null pada tier lain sehingga tile tidak punya gesture mati di sana.
  final ValueChanged<ProviderConnectorEntry>? onOpenProviderDetails;
  final VoidCallback? onSyncNow;

  final VoidCallback? onSignIn;
  final VoidCallback? onOpenAiProviders;
  final VoidCallback? onOpenSecurity;

  @override
  Widget build(BuildContext context) {
    final gap = AccountCenterDesignTokens.layout.cardGap;

    // 115.36: aksi sign-in pindah ke kartu AUTHENTICATION gabungan. Function
    // ini tidak hilang saat redesign — kartu auth adalah satu-satunya owner
    // surface autentikasi, jadi tombol sign-in hidup di sana.
    final signInAction =
        onSignIn ?? () => context.push('${AppRoutes.login}?from=account-cloud');

    // 115.36 — mockup 1536x1024 adalah tiga baris yang MEMUAT SELURUH panel:
    //   row 1: AUTHENTICATION | QUICK CONNECT | CLOUD STORAGE USAGE
    //   row 2: CONNECTED SERVICES | API PROVIDERS | DEVELOPER TOOLS |
    //           CREATIVE TOOLS | PAYMENT METHODS
    //   row 3: API KEYS | TEAM & COLLABORATION | ACTIVITY LOG |
    //           BACKUP & SYNC | SECURITY CENTER
    // Baris 1 lebar penuh tiga kolom; baris 2 dan 3 lima kolom. Tinggi tiap
    // baris dihitung dari tinggi viewport yang tersisa, bukan dari jumlah
    // kartu — itulah yang membuat panel muat tanpa scroll luar.
    final rows = <_AccountSection>[
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[0],
        cards: [
          _AccountSectionCard.dashboard(
            key: const ValueKey('account-overview-card-authentication'),
            title: 'AUTHENTICATION',
            subtitle: 'Manage your account access',
            child: _AuthenticationProfileCard(
              snapshot: snapshot,
              onSignIn: signInAction,
              onEditProfile: () => context.push(AppRoutes.settings),
            ),
          ),
          _AccountSectionCard.dashboard(
            key: const ValueKey('account-overview-card-quick-connect'),
            title: 'QUICK CONNECT',
            subtitle: 'Connect services available to this account',
            child: _QuickConnectPanel(
              manifest: providerManifest,
              onConnectProvider: onConnectProvider,
              onOpenProviderDetails: onOpenProviderDetails,
            ),
          ),
          _AccountSectionCard.dashboard(
            key: const ValueKey('account-overview-card-storage'),
            title: 'CLOUD STORAGE USAGE',
            subtitle: 'Storage metering by provider',
            child: StorageUsageCard(onManage: onSyncNow),
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[1],
        cards: [
          // Mockup row 2: "Connected Services Overview" meringkas seluruh
          // drive dalam SATU kartu. Satu kartu penuh per service membuat enam
          // kartu meledak dan menduplikasi QUICK CONNECT.
          _AccountSectionCard.dashboard(
            key: const ValueKey('account-overview-card-connected-services'),
            title: 'CONNECTED SERVICES OVERVIEW',
            subtitle: 'Connection summary',
            icon: Icons.hub_outlined,
            child: _ServiceSummaryList(services: snapshot.services),
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-api-providers'),
            title: 'API PROVIDERS',
            subtitle: 'AI model gateways',
            icon: Icons.api_outlined,
            message: 'Configure and test OpenAI or Gemini from AI Providers.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-developer-tools'),
            title: 'DEVELOPER TOOLS',
            subtitle: 'Source control and development services',
            icon: Icons.code_outlined,
            message: 'No developer service is connected.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-creative-tools'),
            title: 'CREATIVE TOOLS',
            subtitle: 'Design and media integrations',
            icon: Icons.palette_outlined,
            message: 'No creative tool is connected.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-payment-methods'),
            title: 'PAYMENT METHODS',
            subtitle: 'Billing service connections',
            icon: Icons.payment_outlined,
            message: 'No payment method is configured.',
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[2],
        cards: [
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-api-keys-manager'),
            title: 'API KEYS MANAGER',
            subtitle: 'Credential inventory',
            icon: Icons.key_outlined,
            message:
                'Credentials remain protected in the operating-system vault.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-team-collaboration'),
            title: 'TEAM & COLLABORATION',
            subtitle: 'Members, roles, and invitations',
            icon: Icons.groups_outlined,
            message: 'Team management is not configured.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-activity-log'),
            title: 'ACTIVITY LOG',
            subtitle: 'Recent account and integration events',
            icon: Icons.history_outlined,
            message: 'No account activity has been recorded.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-backup-sync'),
            title: 'BACKUP & SYNC',
            subtitle: 'Data protection and synchronization',
            icon: Icons.sync_outlined,
            message:
                'Local project backups are available. Cloud sync remains unavailable until a provider is connected.',
          ),
          const _AccountSectionCard.capability(
            key: ValueKey('account-overview-card-security-center'),
            title: 'SECURITY CENTER',
            subtitle: 'Sessions and account protection',
            icon: Icons.security_outlined,
            message: 'Security telemetry is not available locally.',
          ),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar kartu mengikuti kontrak grid responsif (115.6): jumlah kolom
        // berasal dari tier VIEWPORT (plan luar), lebar kartu dihitung dari
        // lebar area konten. Tanpa pemisahan ini panel utama 75% salah dibaca
        // sebagai tier yang lebih sempit dan kartu turun ke 2 kolom.
        //
        // Batas keras: `cardWidthFor` menjumlahkan gap untuk N-2 kolom, sehingga
        // pada N kolom diperlukan (N-1) gap. Lebar dikurung supaya baris
        // tidak pernah melewati area konten (RenderFlex overflow).
        final contentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : gridPlan.cardWidthFor(constraints.maxWidth);
        // 115.36: tinggi baris berasal dari tinggi yang tersisa, dibagi rata ke
        // tiga baris. Dua baris terakhir memakai lima kolom, jadi gap hanya
        // dihitung di dalam baris yang relevan.
        final rowGap = gap;
        final rowCount = rows.length;
        // 115.45: tinggi baris pada frame wide desktop dihitung SATU KALI di
        // kontrak [AccountCenterFrameLayout] (terukur dari viewport, bukan
        // dari tinggi tak terkunci panel), sehingga chrome yang dikurangi
        // tidak pernah membuat baris meluap. Jalur responsif di bawah 1440
        // tetap memakai perhitungan lama agar tier 115.46/115.47 tidak
        // ikut berubah oleh slice ini.
        final wideFrame = frame;
        List<double> rowHeights;
        double availableHeight;
        if (wideFrame != null && constraints.maxHeight.isFinite) {
          // Band main memuat chrome (header, breadcrumb, tab strip) sebelum
          // kartu. Tinggi yang benar untuk grid adalah sisa SETELAH chrome,
          // jadi tinggi baris dihitung dari tinggi yang benar-benar tersedia
          // — bukan dari tinggi band. Algoritma tetap milik kontrak
          // ([rowHeightsFor]); kontrak juga sudah mengurangi celah antar
          // baris di dalamnya, jadi caller TIDAK boleh mengurangi celah lagi
          // (celah terpotong dua kali menyisakan 44px band kosong — 117.23).
          availableHeight = constraints.maxHeight;
          rowHeights = AccountCenterWideDesktopFrame.rowHeightsFor(
            availableHeight,
          );
        } else if (wideFrame != null) {
          // Harness tanpa Scaffold memberi tinggi tak terbatas; anggaran
          // frame dipakai sebagai gantinya agar baris tetap terukur.
          availableHeight = wideFrame.gridHeight;
          rowHeights = wideFrame.rowHeights;
        } else {
          // Tinggi tak terbatas hanya terjadi bila panel di-host tanpa
          // Scaffold pada harness pengujian; fallback lokal menjaga baris
          // tetap terukur tanpa menyentuh design token yang dipaku test.
          const fallbackHeight = 900.0;
          availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackHeight;
          // Sama seperti jalur live: celah sudah dipotong di dalam
          // [rowHeightsFor], jadi tinggi yang dikirim = tinggi tersedia apa
          // adanya.
          rowHeights = AccountCenterWideDesktopFrame.rowHeightsFor(
            availableHeight,
          );
        }
        // 115.36: tiga baris mockup hanya sah di tier `wide_desktop` (viewport
        // referensi 1536x1024). Di tier lain, mockup tidak berlaku dan kontrak
        // responsif 115.6 yang dipakai: kartu mengalir sesuai [maxColumns]
        // dan halaman digulir. Memaksakan tiga baris mockup pada viewport
        // 600-1179px hanya menghasilkan baris yang meluap isinya.
        final mockupTier = gridPlan.tier == AccountCenterLayoutTier.wideDesktop;
        const minRowHeight = 120.0;
        // 115.45: pada frame wide desktop, jumlah kolom tiap baris sudah
        // diputuskan kontrak (aturan fit card.minWidth terhadap band main).
        // Baris mockup hanya sah bila tinggi tersedia masih cukup.
        if (!mockupTier || availableHeight < minRowHeight * rowCount) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in rows) ...[
                  Padding(
                    key: ValueKey('account-anchor-${section.tab.slug}'),
                    padding: EdgeInsets.only(bottom: gap),
                    child: _RowCards(
                      cards: section.cards,
                      contentWidth: contentWidth,
                      gap: gap,
                      maxColumns: gridPlan.maxColumns,
                      boundedHeight: false,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < rowCount; index++) ...[
              // Celah antar baris di LUAR anchor: [rowHeightsFor] sudah
              // menyisakan (rowCount - 1) * gap dari tinggi band, sehingga
              // baris + celah = tinggi tersedia persis, tanpa sisa 44px di
              // bawah baris (cacat fail-closed yang diukur 117.23).
              if (index > 0) SizedBox(height: rowGap),
              _AccountSectionAnchor(
                // Key pada anchor = seam yang dipakai tab strip & deep link.
                key: ValueKey('account-anchor-${rows[index].tab.slug}'),
                tab: rows[index].tab,
                active: rows[index].tab == tab,
                child: SizedBox(
                  height: rowHeights[index],
                  child: _RowCards(
                    cards: rows[index].cards,
                    contentWidth: contentWidth,
                    gap: rowGap,
                    // Anggaran kartu = seluruh tinggi baris; celah antar
                    // baris kini berada di luar anchor sehingga tidak lagi
                    // dipotong dari dalam baris.
                    boundedRowHeight: rowHeights[index],
                    // Mockup 1536x1024 memakai lima kolom pada baris 2 dan
                    // 3; batas itu hanya sah di tier wide_desktop, dan
                    // pada frame 115.45 angka kolom berasal dari kontrak
                    // (1536 hanya muat 4 kolom setelah nav 192px).
                    maxColumns:
                        frame?.rowColumns[index] ??
                        (gridPlan.tier == AccountCenterLayoutTier.wideDesktop
                            ? 5
                            : gridPlan.maxColumns),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Deretan kartu satu baris mockup, dengan fallback bertumpuk.
///
/// Mockup 1536x1024 memakai tiga dan lima kolom. Pada viewport sempit lima
/// kolom tidak mungkin muat pada lebar kartu minimum, jadi baris berubah
/// menjadi satu kolom penuh — perilaku ini milik kontrak responsif 115.6
/// (`columnsFor`), bukan tebakan per baris.
class _RowCards extends StatelessWidget {
  const _RowCards({
    required this.cards,
    required this.contentWidth,
    required this.gap,
    required this.maxColumns,
    this.boundedHeight = true,
    this.boundedRowHeight,
  });

  final List<_AccountSectionCard> cards;
  final double contentWidth;
  final double gap;

  /// Batas kolom dari rencana responsif kanonik (115.6).
  ///
  /// Baris mockup 3/5/5 hanya sah di tier `wide_desktop`. Tier 2 kolom
  /// (compact_desktop, tablet) memakai [maxColumns] — TAPI kartu tidak
  /// pernah dipotong: baris membungkus ke beberapa baris fisik, bukan
  /// menghilangkan kartu.
  final int maxColumns;

  /// Apakah baris punya tinggi terkunci (baris mockup) atau shrink-wrap
  /// (jalur scroll pada viewport pendek).
  final bool boundedHeight;

  /// Tinggi terkunci baris ini. Bila kartu membungkus ke beberapa baris
  /// fisik (115.45: lima kartu pada 961px hanya muat empat), tinggi ini
  /// DIBAGI rata ke baris fisik agar tidak ada yang meluap dan tidak ada
  /// tinggi yang hilang.
  final double? boundedRowHeight;

  @override
  Widget build(BuildContext context) {
    // 115.36: mockup 1536x1024 memakai lima kolom selebar 213px, jadi
    // ambang baris mockup adalah konstanta lokal 200px. Token desain
    // (`card.minWidth` 220) tidak disentuh dan tetap dipakai di tier lain.
    const mockupMinCardWidth = 200.0;
    final minCard = maxColumns >= 5 ? mockupMinCardWidth : 220.0;
    final perRow = cards.length < maxColumns ? cards.length : maxColumns;
    final fits =
        perRow > 0 && (contentWidth - gap * (perRow - 1)) / perRow >= minCard;

    if (!fits) {
      // Jalur bertumpuk memakai tinggi tak terbatas, jadi kartu di dalamnya
      // harus shrink-wrap: `fillHeight` di sini akan melempar "non-zero flex
      // but unbounded height".
      return SingleChildScrollView(
        child: Column(
          children: [
            for (final card in cards)
              Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: KeyedSubtree(
                  key: card.key,
                  child: card.build(context, fillHeight: false),
                ),
              ),
          ],
        ),
      );
    }

    final cardWidth = (contentWidth - gap * (perRow - 1)) / perRow;
    Widget card(int index) => SizedBox(
      width: cardWidth,
      child: KeyedSubtree(
        key: cards[index].key,
        child: cards[index].build(context, fillHeight: boundedHeight),
      ),
    );

    // Baris mockup: semua kartu dalam SATU baris. Tier non-wide mengikuti
    // kontrak 115.6: kartu membungkus ke beberapa baris, tidak ada yang
    // dipotong.
    if (perRow == cards.length) {
      return Row(
        // `stretch` memerlukan tinggi baris yang sudah ditetapkan. Di jalur
        // scroll (tinggi tak terbatas) `stretch` memaksa tinggi tak terbatas
        // pada tiap kartu, jadi kartu memakai `start` agar shrink-wrap.
        crossAxisAlignment: boundedHeight
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < perRow; index++)
            Padding(
              padding: EdgeInsets.only(right: index == perRow - 1 ? 0 : gap),
              child: card(index),
            ),
        ],
      );
    }

    // Jalur beberapa baris fisik. Bila baris punya tinggi terkunci, tinggi
    // itu dibagi rata ke baris fisik — tanpa ini lima kartu pada 961px
    // (empat per baris + satu) akan memakai tinggi natural ~2x dan meluap.
    // Bila tinggi tidak terkunci, `Column` meneruskan tinggi tak terbatas ke
    // tiap `Row` anak sehingga `stretch` melempar "infinite height"; baris
    // anak lalu shrink-wrap dan kartu bergulir di dalamnya.
    final physicalRows = (cards.length / perRow).ceil();
    final locked = boundedHeight && boundedRowHeight != null;
    // Celah antar baris fisik ikut dipotong dari tinggi terkunci; tanpa itu
    // tinggi baris fisik + celah melampaui tinggi baris mockup dan meluap.
    final perPhysicalRow = locked
        ? (boundedRowHeight! - gap * (physicalRows - 1)) / physicalRows
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row = 0; row * perRow < cards.length; row++) ...[
          if (perPhysicalRow != null)
            SizedBox(
              height: perPhysicalRow,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < perRow; index++)
                    if (row * perRow + index < cards.length)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == perRow - 1 ? 0 : gap,
                        ),
                        child: card(row * perRow + index),
                      ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < perRow; index++)
                  if (row * perRow + index < cards.length)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == perRow - 1 ? 0 : gap,
                      ),
                      child: card(row * perRow + index),
                    ),
              ],
            ),
          if ((row + 1) * perRow < cards.length) SizedBox(height: gap),
        ],
      ],
    );
  }
}

/// Satu baris mockup: anchor section + deretan kartu selebar viewport.
class _AccountSection {
  const _AccountSection({required this.tab, required this.cards});

  final AccountCenterTab tab;
  final List<_AccountSectionCard> cards;
}

/// Pembungkus satu area kanonik dalam panel tunggal.
///
/// 115.36: panel luar tidak lagi digulir, jadi anchor tidak perlu mengukur
/// posisi absolut. Yang tersisa adalah seam semantik: nama section untuk
/// pembaca layar dan identity yang dipakai tab strip & deep link `?tab=`.
class _AccountSectionAnchor extends StatelessWidget {
  const _AccountSectionAnchor({
    super.key,
    required this.tab,
    required this.active,
    required this.child,
  });

  final AccountCenterTab tab;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'account-anchor-${tab.slug}',
      header: true,
      label: tab.label,
      child: Semantics(container: true, child: child),
    );
  }
}

/// Kartu dalam satu area, dibungkus supaya tiap jenis punya satu constructor.
class _AccountSectionCard {
  const _AccountSectionCard.dashboard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.key,
    this.icon,
  }) : _kind = _AccountSectionCardKind.dashboard,
       message = null,
       onPressed = null;

  const _AccountSectionCard.capability({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.message,
    this.key,
  }) : _kind = _AccountSectionCardKind.capability,
       child = null,
       onPressed = null;

  /// Key stabil untuk kartu baris pertama mockup; dipakai tes layout untuk
  /// mengukur baris overview, bukan kemunculan pertama sebuah judul.
  final Key? key;

  final String title;
  final String subtitle;
  final _AccountSectionCardKind _kind;
  final Widget? child;
  final IconData? icon;
  final String? message;
  final VoidCallback? onPressed;

  /// [fillHeight] hanya sah di dalam baris mockup yang tingginya terkunci.
  /// Jalur bertumpuk sempit (lihat [_RowCards]) MUSTI mengoper `false`.
  Widget build(BuildContext context, {bool fillHeight = true}) =>
      switch (_kind) {
        _AccountSectionCardKind.dashboard => _DashboardCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          fillHeight: fillHeight,
          child: child!,
        ),
        _AccountSectionCardKind.capability => _OverviewCapabilityCard(
          title: title,
          subtitle: subtitle,
          icon: icon!,
          message: message!,
          fillHeight: fillHeight,
        ),
      };
}

enum _AccountSectionCardKind { dashboard, capability }

class _CenterTab extends StatefulWidget {
  const _CenterTab({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_CenterTab> createState() => _CenterTabState();
}

class _CenterTabState extends State<_CenterTab> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _revealInTabStrip();
    }
  }

  /// Tab aktif (termasuk hasil deep link) wajib terlihat di tab strip.
  /// Hanya saat inisialisasi halaman: perubahan tab lokal tidak menggeser
  /// strip agar target tap yang sudah terlihat tetap stabil.
  ///
  /// 117.24: yang digeser HANYA strip horizontal ini. `Scrollable
  /// .ensureVisible` mem-scroll SEMUA scrollable yang membungkus konten
  /// (Flutter: "Scrolls all scrollables that enclose the given context"),
  /// sehingga page scroll vertikal ikut menarik tab ke tanda 20% viewport:
  /// pada paint pertama tier `tablet` navigasi atas (chrome wajib tier)
  /// terpotong 32.8px ke atas dan tier `mobile` membuka halaman pada
  /// offset 79.4px. Posisi strip terdekat digerakkan langsung lewat
  /// [ScrollPosition.ensureVisible] yang hanya menggerakkan posisinya
  /// sendiri.
  void _revealInTabStrip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final strip = Scrollable.maybeOf(context);
      final renderObject = context.findRenderObject();
      if (strip == null || renderObject == null) {
        return;
      }
      strip.position.ensureVisible(
        renderObject,
        duration: Duration.zero,
        alignment: 0.2,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(right: AccountCenterDesignTokens.spacing.xl),
    child: SizedBox(
      height: AccountCenterDesignTokens.layout.tabBarHeight,
      child: Semantics(
        selected: widget.active,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (focused == _focused) {
              return;
            }
            setState(() => _focused = focused);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.active
                      ? context.palette.primaryBright
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: AccountCenterDesignTokens.spacing.sm,
                ),
                child: AnimatedContainer(
                  duration: _focusRingDuration(context),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _focused
                          ? context.palette.primaryBright
                          : Colors.transparent,
                      width: AccountCenterAccessibility.tabFocusRingWidth,
                    ),
                    borderRadius: BorderRadius.circular(
                      AccountCenterDesignTokens.radius.tile,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AccountCenterDesignTokens.spacing.sm,
                  ),
                  child: Text(
                    widget.label,
                    style: _body.copyWith(
                      color: widget.active
                          ? context.palette.primaryBright
                          : context.palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 115.7: reduced-motion mematikan durasi dekoratif focus ring. Sumber
/// keputusan tunggal = [AccountCenterAccessibility.reducedMotion].
Duration _focusRingDuration(BuildContext context) =>
    AccountCenterAccessibility.reducedMotion(context)
    ? Duration.zero
    : const Duration(milliseconds: 120);

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.fillHeight = false,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Ikon kategori opsional pada baris judul (ikon token scale, bukan ukuran
  /// hardcode). Kartu mockup baris pertama tetap tanpa ikon.
  final IconData? icon;

  /// 115.36: apakah body kartu menyerap tinggi baris mockup.
  ///
  /// Hanya sah untuk kartu yang duduk di dalam baris berukuran tetap. Kartu
  /// rail hidup di dalam `SingleChildScrollView` dengan tinggi tak
  /// terbatas, dan `Expanded` di sana melempar "non-zero flex but unbounded
  /// height". Karena itu ini opt-in, bukan default.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AccountCenterDesignTokens.card.padding),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.card,
      ),
      border: Border.all(color: context.palette.border),
    ),
    // 115.36: pada baris mockup body kartu menyerap tinggi sisa baris,
    // sehingga daftar panjang (metode sign-in) menggulir di dalam kartu —
    // bukan memanjangkan panel luar.
    child: _DashboardCardContent(
      fillHeight: fillHeight,
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: child,
    ),
  );
}

/// Isi [_DashboardCard]: seluruh kartu bergulir, header termasuk.
class _DashboardCardContent extends StatelessWidget {
  const _DashboardCardContent({
    required this.fillHeight,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
  });

  final bool fillHeight;
  final String title;
  final String subtitle;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Kartu shrink-wrap memakai `min`: pada tinggi tak terbatas `max`
    // membuat RenderFlex menganggap isinya meluap.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon case final iconData?) ...[
          Icon(
            iconData,
            size: AccountCenterDesignTokens.iconSizes.section,
            color: context.palette.primaryBright,
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
        ],
        Text(title, style: _sectionTitle),
        SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
        Text(subtitle, style: _caption),
        SizedBox(height: AccountCenterDesignTokens.spacing.md),
        // Tanpa flex: RenderFlex menolak semua flex saat tinggi tak terbatas,
        // dan pada baris terkunci seluruh kartu sudah digulir oleh
        // [_DashboardCardContent] sehingga isinya tidak perlu `Expanded` lagi.
        child,
      ],
    );
    if (!fillHeight) return content;
    // Baris mockup punya tinggi terkunci. Isi yang lebih tinggi — termasuk
    // header saat textScale 200% — menggulir DI DALAM kartu, bukan
    // memanjangkan panel luar dan bukan meluap.
    return SingleChildScrollView(child: content);
  }
}

class _QuickConnectPanel extends StatelessWidget {
  const _QuickConnectPanel({
    required this.manifest,
    this.onConnectProvider,
    this.onOpenProviderDetails,
  });

  final ProviderConnectorManifest manifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;

  /// 115.47: tier mobile membuka detail provider sebagai sheet layar penuh.
  final ValueChanged<ProviderConnectorEntry>? onOpenProviderDetails;

  @override
  Widget build(BuildContext context) {
    final entries = manifest.all
        .where(
          (entry) => entry.category == ProviderConnectorCategory.cloudStorage,
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        // 115.36: baris mockup punya tinggi tetap, jadi daftar provider yang
        // panjang harus menggulir DI DALAM kartu. Tanpa scroll internal kartu
        // meluap dan mendorong panel luar melewati viewport.
        final tiles = <Widget>[
          for (final entry in entries)
            _ProviderTile(
              entry: entry,
              onConnect: onConnectProvider == null
                  ? null
                  : () => onConnectProvider!(entry),
              onOpenDetails: onOpenProviderDetails == null
                  ? null
                  : () => onOpenProviderDetails!(entry),
            ),
        ];
        if (constraints.maxHeight.isInfinite) {
          return Column(children: tiles);
        }
        return SingleChildScrollView(child: Column(children: tiles));
      },
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.entry,
    this.onConnect,
    this.onOpenDetails,
  });

  final ProviderConnectorEntry entry;
  final VoidCallback? onConnect;

  /// 115.47: pada tier `mobile` spec meminta detail provider terbuka sebagai
  /// sheet layar penuh, jadi tile jadi target ketuk. Null pada tier lain
  /// (drail/rail desktop memakai baris penuh) sehingga tidak ada gesture
  /// yang mati di luar tier miliknya.
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final canConnect = entry.isConnectable && onConnect != null;
    return Padding(
      key: ValueKey('quick-connect-provider-${entry.providerId}'),
      padding: EdgeInsets.only(
        bottom: AccountCenterDesignTokens.serviceRow.gap,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AccountCenterDesignTokens.serviceRow.minHeight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final providerLabel =
                AccountCenterAccessibility.providerSemanticsLabel(
                  entry.displayName,
                  _providerConnectionLabel(entry.availability),
                );
            final details = Semantics(
              // 115.47: pada tier mobile baris detail dibungkus Semantics
              // berlabel 'Provider details' (lihat `_tappableDetails`).
              // Semantics terluar menang, jadi label provider yang sudah
              // ada ikut dirangkai di sini agar nama + status koneksinya
              // tidak hilang bagi pembaca layar. Di tier lain labelnya
              // apa adanya seperti sebelum 115.47.
              label: onOpenDetails == null
                  ? providerLabel
                  : '$providerLabel, Open provider details',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.displayName, style: _body),
                    Text(
                      _providerAvailabilityLabel(entry.availability),
                      style: _caption,
                    ),
                    Text(
                      _providerHealthLabel(entry.availability),
                      style: _caption,
                    ),
                  ],
                ),
              ),
            );
            // 115.36: pada kolom mockup yang sempit tombol aksi tidak boleh
            // memaksa lebar minimum; ia boleh menyusut dan labelnya ellipsis.
            // `Flexible` hanya sah di dalam `Row`, jadi di jalur `Align`
            // (textScale tinggi) tombol dibungkus tanpa `Flexible`; `Align`
            // sendiri yang membatasi lebarnya.
            //
            // 115.47: pada tier mobile spec meminta detail provider sebagai
            // sheet layar penuh, jadi BARIS DETAIL (bukan tombol Connect)
            // yang menjadi target ketuk. Tombol Connect tetap hidup dan
            // tidak ditimpa.
            Widget action({bool shrink = false}) => ConstrainedBox(
              constraints: shrink
                  ? const BoxConstraints(maxWidth: double.infinity)
                  : const BoxConstraints(),
              child: TextButton(
                onPressed: canConnect ? onConnect : null,
                child: Text(
                  entry.isConnectable ? 'Connect' : 'Not available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
            final rowAction = Flexible(child: action());
            final textScale = MediaQuery.textScalerOf(context).scale(1);

            // 115.47: pada tier mobile spec meminta detail provider sebagai
            // sheet layar penuh. Seluruh tile jadi SATU target ketuk, dan
            // aksi Connect pindah ke dalam sheet (lihat
            // `_MobileProviderDetailsSheet`) — bukan tombol kedua di tile.
            // Ini juga menghapus pusat tile yang mati: kalau tombol Connect
            // tetap di sini, titik ketukan tengah tile bisa mendarat di
            // tombol yang tidak melakukan apa-apa.
            //
            // TOKEN: setiap tile tetap punya tepat satu `Row` anak langsung
            // dari `ConstrainedBox(minHeight: serviceRow.minHeight)`, karena
            // 115.5 mengukur `constraints.minHeight` pada Row TERDEKAT dari
            // teks provider. `Row` bersarang di dalam tile akan memutus
            // rantai itu dan membuat 115.5 gagal.
            if (onOpenDetails != null) {
              final detailsRow = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProviderIcon(entry: entry),
                  SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                  Expanded(child: details),
                ],
              );
              return Semantics(
                button: true,
                label: 'Provider details',
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        AccountCenterDesignTokens.density.minimumTouchTarget,
                  ),
                  child: InkWell(onTap: onOpenDetails, child: detailsRow),
                ),
              );
            }

            if (textScale > 1.3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProviderIcon(entry: entry),
                      SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                      Expanded(child: details),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: action()),
                ],
              );
            }

            return Row(
              children: [
                _ProviderIcon(entry: entry),
                SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                Expanded(child: details),
                rowAction,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.entry});

  final ProviderConnectorEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sprint 117.22: seven of the fourteen bundled marks are dark-ink-only
    // (anthropic #1f1f1e at luminance 0.0137, paypal 0.0363, bitbucket 0.1039,
    // canva 0.1179, plus the openai/github/midtrans marks whose fills are black
    // or near-black). Painting those on the dark chrome surface produced an
    // invisible mark. `resolveForSurface` degrades such a mark to the approved
    // generic category glyph AND corrects the accessible name, because keeping
    // "Anthropic icon" while drawing a generic glyph tells a screen-reader user
    // a mark is present when it is not.
    final icon = ProviderIconRegistry.standard.resolveForSurface(
      entry.providerId,
      isDark: isDark,
    );
    final assetPath = isDark
        ? icon.assetDark ?? icon.assetLight
        : icon.assetLight ?? icon.assetDark;
    final size = AccountCenterDesignTokens.iconSizes.action;

    // Sprint 117.22: aspect preservation is now arithmetic from the measured
    // source box, so a 1180x320 wordmark is no longer squeezed into a square.
    final height = size;
    final width = icon.intrinsicSize == null
        ? size
        : icon.widthForHeight(height).clamp(0.0, size * 2.5);

    return Semantics(
      image: true,
      label: icon.accessibleName,
      child: ExcludeSemantics(
        child: assetPath == null
            ? Icon(Icons.cloud_queue_outlined, size: size)
            : BrandLogo(
                assetPath: assetPath,
                width: width,
                height: height,
                fallbackIcon: Icons.cloud_queue_outlined,
              ),
      ),
    );
  }
}

String _providerAvailabilityLabel(ProviderConnectorAvailability availability) =>
    switch (availability) {
      ProviderConnectorAvailability.unverified => 'Provider unverified',
      ProviderConnectorAvailability.planned => 'Planned',
      ProviderConnectorAvailability.available => 'Ready to connect',
      ProviderConnectorAvailability.unavailable => 'Unavailable',
      ProviderConnectorAvailability.unsupportedRegion =>
        'Unsupported in this region',
      ProviderConnectorAvailability.degraded => 'Degraded',
      ProviderConnectorAvailability.outage => 'Provider outage',
    };

String _providerHealthLabel(ProviderConnectorAvailability availability) =>
    switch (availability) {
      ProviderConnectorAvailability.degraded => 'Health: Degraded',
      ProviderConnectorAvailability.outage => 'Health: Outage',
      _ => 'Health: Unknown',
    };

String _providerConnectionLabel(ProviderConnectorAvailability availability) =>
    // 115.53: pemetaan ini tadinya hidup di presentation dan memetakan
    // `available`, `degraded`, DAN `outage` semuanya ke 'Connected'. String
    // itu masuk ke TIGA permukaan sekaligus: label semantik tile provider,
    // baris `Connection` di sheet detail mobile, dan pengumuman screen
    // reader 115.48 — sehingga pengguna pembaca layar diberi tahu akunnya
    // terhubung saat provider-nya sedang outage. Sekarang satu kontrak yang
    // dipakai bersama dan outage tidak pernah diklaim sebagai terhubung.
    AccountCenterPerformanceResilience.connectionLabel(availability.wireName);

/// Label status koneksi yang diumumkan sebagai teks (spec: warna bukan satu
///-satunya pembawa connection/health state).
String _connectionStatusLabel(AccountCloudConnectionState state) =>
    switch (state) {
      AccountCloudConnectionState.connected => 'Connected',
      AccountCloudConnectionState.availableLocal => 'Available locally',
      AccountCloudConnectionState.notConnected => 'Not connected',
    };

class _ServiceSummaryList extends StatelessWidget {
  const _ServiceSummaryList({required this.services});

  final List<AccountCloudService> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text(
        'Connected services appear here after provider verification.',
        style: _body,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final service in services) ...[
          MergeSemantics(
            child: Semantics(
              label: AccountCenterAccessibility.providerSemanticsLabel(
                service.label,
                _connectionStatusLabel(service.state),
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.label,
                        style: VoidTypography.headingMedium,
                        // 115.36: baris ringkas di rail sempit; label panjang
                        // ellipsis, bukan memicu RenderFlex overflow.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AccountCenterDesignTokens.spacing.twoXs),
                    Flexible(child: _ConnectionBadge(state: service.state)),
                  ],
                ),
              ),
            ),
          ),
          if (service != services.last)
            SizedBox(height: AccountCenterDesignTokens.spacing.sm),
        ],
      ],
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});

  final AccountCloudConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      AccountCloudConnectionState.connected => (
        'Connected',
        context.palette.success,
      ),
      AccountCloudConnectionState.availableLocal => (
        'Available locally',
        context.palette.primaryBright,
      ),
      AccountCloudConnectionState.notConnected => (
        'Not connected',
        context.palette.textMuted,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AccountCenterDesignTokens.spacing.sm,
        vertical: AccountCenterDesignTokens.spacing.twoXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          AccountCenterDesignTokens.radius.pill,
        ),
      ),
      child: Text(
        label,
        style: _caption.copyWith(color: color),
        // 115.36: badge wajib ellipsis pada text scale besar.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Dialog pencarian bagian Account & Cloud Center (115.3 search index).
class _AccountCenterSearchDialog extends StatefulWidget {
  const _AccountCenterSearchDialog({required this.onSelected});

  final ValueChanged<AccountCenterTab> onSelected;

  @override
  State<_AccountCenterSearchDialog> createState() =>
      _AccountCenterSearchDialogState();
}

class _AccountCenterSearchDialogState
    extends State<_AccountCenterSearchDialog> {
  String _query = '';

  /// 115.48: jumlah hasil diumumkan setiap kali berubah, jadi pengguna
  /// pembaca layar tahu apakah kuerinya menghasilkan apa pun. Diamnya
  /// daftar hasil adalah kegagalan, bukan hemat.
  void _announceResults(int count) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      AccountCenterKeyboardScreenReader.searchResultsAnnouncement(count),
      Directionality.of(context),
    );
  }

  @override
  void initState() {
    super.initState();
    // 115.48: dialog yang baru dibuka langsung mengumumkan statusnya saat
    // masuk, termasuk saat kueri masih kosong. Tanpa ini pengguna pembaca
    // layar melihat dialog berisi field tanpa tahu berapa hasil yang ada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _announceResults(
          AccountCenterInformationArchitecture.search(_query).length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = AccountCenterInformationArchitecture.search(_query);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AccountCenterDesignTokens.radius.dialog,
        ),
      ),
      title: const Text('Search account sections'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              autofocus: true,
              // 115.48: `labelText` permanen. `hintText` saja hilang begitu
              // pengguna mengetik, jadi pembaca layar kehilangan nama field.
              decoration: const InputDecoration(
                labelText: AccountCenterKeyboardScreenReader.searchFieldLabel,
                hintText: AccountCenterKeyboardScreenReader.searchFieldHint,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _announceResults(
                  AccountCenterInformationArchitecture.search(_query).length,
                );
              }),
            ),
            SizedBox(height: AccountCenterDesignTokens.spacing.md),
            if (results.isEmpty)
              const Text('No account sections match that search.')
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final tab in results)
                        ListTile(
                          title: Text(tab.label),
                          subtitle: const Text('Account section'),
                          onTap: () => widget.onSelected(tab),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          // 115.7: target sentuh 44px (default Material 3 = 40px).
          style: TextButton.styleFrom(
            minimumSize: const Size(
              0,
              AccountCenterAccessibility.minimumTouchTarget,
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
