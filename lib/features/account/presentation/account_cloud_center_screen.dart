import 'package:flutter/material.dart';
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
import '../domain/account_center_design_tokens.dart';
import '../domain/account_center_information_architecture.dart';
import '../domain/account_center_provider_connector_manifest.dart';
import '../domain/account_center_responsive_grid.dart';
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
    // Mode router-driven (onTabChanged terpasang): state tab hidup di URL,
    // halaman ini tidak boleh berubah agar target back-navigation stabil.
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(next.slug);
      return;
    }
    setState(() => _tab = next);
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

  /// Area utama shell: chrome atas lalu grid tiga baris mockup.
  ///
  /// Dipakai oleh tier `wide_desktop` (lebar 75%) dan tier lain yang
  /// menumpuk rail di bawah lewat [Expanded].
  Widget _shellMain({
    required double mainWidth,
    required AccountCloudSnapshot data,
    required AccountCenterGridPlan gridPlan,
    required bool scrollable,
  }) {
    final area = _FocusedAccountArea(
      tab: _tab,
      snapshot: data,
      gridPlan: gridPlan,
      providerManifest:
          widget.providerManifest ?? ProviderConnectorManifest.standard,
      onConnectProvider: widget.onConnectProvider,
      onSyncNow: widget.onSyncNow,
      onSignIn:
          data.service('email-sign-in').state ==
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
          SingleChildScrollView(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(
              key: const ValueKey('account-profile-avatar'),
              avatar: profile.avatar,
            ),
            SizedBox(width: AccountCenterDesignTokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    key: const ValueKey('account-profile-name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body.copyWith(
                      color: context.palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AccountCenterDesignTokens.spacing.xs),
                  Text(
                    profile.email,
                    key: const ValueKey('account-profile-email'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _caption.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  SizedBox(height: AccountCenterDesignTokens.spacing.xs),
                  _PlanBadge(
                    key: const ValueKey('account-profile-subscription'),
                    plan: profile.plan,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AccountCenterDesignTokens.spacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'SIGN-IN METHODS',
                style: _caption.copyWith(
                  color: context.palette.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            // `Flexible` + ellipsis: pada kartu sempit (200px di baris 2/3
            // mockup) label dan tombol tidak bisa muat dalam Row tanpa
            // menyusut. Tombol boleh menyusut, teks label yang dipangkas.
            Flexible(
              child: TextButton(
                onPressed: onEditProfile,
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    0,
                    AccountCenterAccessibility.minimumTouchTarget,
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Edit profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        // Aksi sign-in yang sebelumnya hidup di kartu ringkasan terpisah.
        SizedBox(height: AccountCenterDesignTokens.spacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSignIn,
            icon: Icon(
              Icons.login_outlined,
              size: AccountCenterDesignTokens.iconSizes.action,
            ),
            label: const Text('Sign in or connect account'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(
                0,
                AccountCenterDesignTokens.density.minimumTouchTarget,
              ),
            ),
          ),
        ),
        // 115.36: kartu grid sudah digulir oleh _DashboardCard, jadi daftar
        // metode sign-in tidak boleh membawa scroll kedua (nested viewport
        // membuat tinggi tak terbatas dan merusak flexible child).
        for (final service in _signInServices)
          _SignInMethodRow(
            icon: _iconFor(service.group),
            label: service.label,
            state: service.state,
          ),
      ],
    );
  }

  /// Metode sign-in kanonik, diturunkan dari snapshot yang sama dengan kartu
  /// overview lama supaya tidak ada dua sumber kebenaran.
  List<AccountCloudService> get _signInServices => snapshot.services
      .where((service) => service.group == AccountCloudServiceGroup.signIn)
      .toList(growable: false);

  List<SignInMethod> get _signInMethods => const [
    SignInMethod.email,
    SignInMethod.google,
    SignInMethod.github,
  ];

  /// Subscription lokal dipetakan dari mode akun, karena belum ada billing
  /// service yang terhubung pada build ini.
  AccountPlan _planFrom(AccountCloudSnapshot snapshot) {
    final authenticated =
        snapshot.service('email-sign-in').state ==
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
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final AccountCloudConnectionState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: AccountCenterDesignTokens.iconSizes.action),
          SizedBox(width: AccountCenterDesignTokens.spacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _caption.copyWith(color: context.palette.textSecondary),
            ),
          ),
          SizedBox(width: AccountCenterDesignTokens.spacing.twoXs),
          // 115.36: badge ikut boleh menyusut. Pada textScale 200% di 390px,
          // badge "Available locally" lebih lebar dari sisa ruang dan
          // memicu overflow 5.3px kalau tidak diberi `Flexible`.
          Flexible(child: _ConnectionBadge(state: state, shrinkToFit: true)),
        ],
      ),
    );
  }
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
          Icon(Icons.unfold_more, color: context.palette.textMuted),
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
        : '${_formatInteger(value.totalTokens)} tokens\n'
              '\$${value.estimatedCost.toStringAsFixed(2)} estimated';
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
        .map((entry) => '${entry.key} ${(entry.value * 100 / total).round()}%')
        .join('\n');
    return '${_formatBytes(total)} indexed${shares.isEmpty ? '' : '\n$shares'}';
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
      oldDelegate.promptShare != promptShare || oldDelegate.color != color;
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
      oldDelegate.values.toString() != values.toString();
}

String _formatInteger(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    final value = bytes / 1024;
    return '${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    final value = bytes / (1024 * 1024);
    return '${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} MB';
  }
  final value = bytes / (1024 * 1024 * 1024);
  return '${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} GB';
}

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
              _ConnectionBadge(state: snapshot.service('email-sign-in').state),
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
    this.onSignIn,
    this.onOpenAiProviders,
    this.onOpenSecurity,
  });

  final AccountCenterTab tab;
  final AccountCloudSnapshot snapshot;

  /// Rencana grid yang sudah diresolusi dari lebar viewport oleh pemanggil.
  final AccountCenterGridPlan gridPlan;

  final ProviderConnectorManifest providerManifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;
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
        // Tinggi tak terbatas hanya terjadi bila panel di-host tanpa Scaffold
        // pada harness pengujian; fallback lokal menjaga baris tetap terukur
        // tanpa menyentuh design token yang dipaku test.
        const fallbackHeight = 900.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : fallbackHeight;
        // Tinggi baris mengikuti proporsi mockup (351 / 268 / 265 px pada
        // 1536x1024), bukan dibagi rata: baris pertama memuat kartu
        // Authentication, Quick Connect, dan Storage yang paling padat.
        const rowWeights = <double>[351, 268, 265];
        final totalWeight = rowWeights
            .take(rowCount)
            .fold<double>(0, (sum, weight) => sum + weight);
        // Gap dipisah: `rowCount - 1` jarak antar baris. Padding bawah tiap
        // baris sudah termasuk di dalam `rowHeights`.
        final usable = (availableHeight - rowGap * (rowCount - 1)).clamp(
          0.0,
          availableHeight,
        );
        final rowHeights = <double>[
          for (var i = 0; i < rowCount; i++)
            totalWeight > 0
                ? usable * rowWeights[i] / totalWeight
                : usable / rowCount,
        ];
        // 115.36: tiga baris mockup hanya sah di tier `wide_desktop` (viewport
        // referensi 1536x1024). Di tier lain, mockup tidak berlaku dan kontrak
        // responsif 115.6 yang dipakai: kartu mengalir sesuai [maxColumns]
        // dan halaman digulir. Memaksakan tiga baris mockup pada viewport
        // 600-1179px hanya menghasilkan baris yang meluap isinya.
        final mockupTier = gridPlan.tier == AccountCenterLayoutTier.wideDesktop;
        const minRowHeight = 120.0;
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
              _AccountSectionAnchor(
                // Key pada anchor = seam yang dipakai tab strip & deep link.
                key: ValueKey('account-anchor-${rows[index].tab.slug}'),
                tab: rows[index].tab,
                active: rows[index].tab == tab,
                child: SizedBox(
                  // Padding baris DI DALAM tinggi baris: kalau di luar, total
                  // tinggi menjadi 3 * rowHeight + 3 * gap dan melampaui
                  // tinggi viewport yang tersisa.
                  height: rowHeights[index],
                  child: Padding(
                    padding: EdgeInsets.only(bottom: rowGap),
                    child: _RowCards(
                      cards: rows[index].cards,
                      contentWidth: contentWidth,
                      gap: rowGap,
                      // Mockup 1536x1024 memakai lima kolom pada baris 2 dan
                      // 3; batas itu hanya sah di tier wide_desktop.
                      maxColumns:
                          gridPlan.tier == AccountCenterLayoutTier.wideDesktop
                          ? 5
                          : gridPlan.maxColumns,
                    ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row = 0; row * perRow < cards.length; row++) ...[
          Row(
            crossAxisAlignment: boundedHeight
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.start,
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
  void _revealInTabStrip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        context,
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
  const _QuickConnectPanel({required this.manifest, this.onConnectProvider});

  final ProviderConnectorManifest manifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;

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
  const _ProviderTile({required this.entry, this.onConnect});

  final ProviderConnectorEntry entry;
  final VoidCallback? onConnect;

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
            final details = Semantics(
              label: AccountCenterAccessibility.providerSemanticsLabel(
                entry.displayName,
                _providerConnectionLabel(entry.availability),
              ),
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
    final icon = ProviderIconRegistry.standard.resolve(entry.providerId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark
        ? icon.assetDark ?? icon.assetLight
        : icon.assetLight ?? icon.assetDark;
    final size = AccountCenterDesignTokens.iconSizes.action;

    return Semantics(
      image: true,
      label: icon.accessibleName,
      child: ExcludeSemantics(
        child: assetPath == null
            ? Icon(Icons.cloud_queue_outlined, size: size)
            : BrandLogo(
                assetPath: assetPath,
                width: size,
                height: size,
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
    switch (availability) {
      ProviderConnectorAvailability.available ||
      ProviderConnectorAvailability.degraded ||
      ProviderConnectorAvailability.outage => 'Connected',
      _ => 'Not connected',
    };

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
  const _ConnectionBadge({required this.state, this.shrinkToFit = false});

  final AccountCloudConnectionState state;

  /// 115.36: bila true, badge melepaskan padding horizontal saat ruang
  /// sempit sehingga label boleh ellipsis alih-alih memaksa lebar.
  final bool shrinkToFit;

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
        horizontal: shrinkToFit
            ? AccountCenterDesignTokens.spacing.twoXs
            : AccountCenterDesignTokens.spacing.sm,
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
              decoration: const InputDecoration(
                hintText: 'Search tabs and sections',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
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
