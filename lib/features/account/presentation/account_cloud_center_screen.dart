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
      _tab = AccountCenterInformationArchitecture.resolveTab(widget.initialTab);
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
            return SingleChildScrollView(
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
                  return Wrap(
                    spacing: AccountCenterDesignTokens.layout.columnGap,
                    runSpacing: AccountCenterDesignTokens.layout.columnGap,
                    children: [
                      SizedBox(
                        width: mainWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    AccountCenterDesignTokens.spacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.palette.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AccountCenterDesignTokens.radius.tile,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.cloud_outlined,
                                    color: context.palette.primaryBright,
                                    size: AccountCenterDesignTokens
                                        .iconSizes
                                        .page,
                                  ),
                                ),
                                SizedBox(
                                  width: AccountCenterDesignTokens.spacing.md,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ACCOUNT & CLOUD CENTER',
                                        style: _pageTitle,
                                      ),
                                      SizedBox(
                                        height: AccountCenterDesignTokens
                                            .spacing
                                            .xs,
                                      ),
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
                                  label: AccountCenterAccessibility
                                      .searchSemanticsLabel,
                                  button: true,
                                  child: IconButton(
                                    tooltip: widget.onSearch == null
                                        ? AccountCenterAccessibility
                                              .searchSemanticsLabel
                                        : 'Search',
                                    onPressed:
                                        widget.onSearch ?? _openAccountSearch,
                                    icon: Icon(
                                      Icons.search,
                                      size: AccountCenterDesignTokens
                                          .iconSizes
                                          .action,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  label: widget.onNotifications == null
                                      ? AccountCenterAccessibility
                                            .notificationsSemanticsLabel
                                      : 'Notifications',
                                  button: widget.onNotifications != null,
                                  enabled: widget.onNotifications != null,
                                  child: IconButton(
                                    tooltip: widget.onNotifications == null
                                        ? AccountCenterAccessibility
                                              .notificationsSemanticsLabel
                                        : 'Notifications',
                                    onPressed: widget.onNotifications,
                                    icon: Icon(
                                      Icons.notifications_none,
                                      size: AccountCenterDesignTokens
                                          .iconSizes
                                          .action,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: AccountCenterDesignTokens.spacing.sm,
                            ),
                            Text(
                              AccountCenterInformationArchitecture.breadcrumbsFor(
                                _tab,
                              ).join(' / '),
                              key: const ValueKey('account-center-breadcrumb'),
                              style: _caption.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                            SizedBox(
                              height: AccountCenterDesignTokens.spacing.md,
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final tab
                                      in AccountCenterInformationArchitecture
                                          .tabs)
                                    _CenterTab(
                                      label: tab.label,
                                      active: tab == _tab,
                                      onTap: () => _selectTab(tab),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: AccountCenterDesignTokens.spacing.xl,
                            ),
                            LayoutBuilder(
                              builder: (context, bodyConstraints) {
                                final mainWidth = bodyConstraints.maxWidth;
                                // 115.6: kolom grid overview dari kontrak
                                // tier + aturan fit card.minWidth (220).
                                final mainCardWidth = gridPlan.cardWidthFor(
                                  mainWidth,
                                );
                                final main = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_tab.slug != 'overview')
                                      _FocusedAccountArea(
                                        tab: _tab,
                                        snapshot: data,
                                        onSignIn:
                                            data
                                                    .service('email-sign-in')
                                                    .state ==
                                                AccountCloudConnectionState
                                                    .connected
                                            ? null
                                            : widget.onSignIn ??
                                                  () => context.push(
                                                    '${AppRoutes.login}?from=account-cloud',
                                                  ),
                                        onOpenAiProviders:
                                            widget.onOpenAiProviders ??
                                            () => context.push(
                                              AppRoutes.aiProviders,
                                            ),
                                        onOpenSecurity: () =>
                                            context.push(AppRoutes.security),
                                      ),
                                    if (_tab.slug == 'overview') ...[
                                      Wrap(
                                        spacing: AccountCenterDesignTokens
                                            .layout
                                            .cardGap,
                                        runSpacing: AccountCenterDesignTokens
                                            .layout
                                            .cardGap,
                                        children: [
                                          SizedBox(
                                            width: mainCardWidth,
                                            child: _DashboardCard(
                                              title: 'AUTHENTICATION',
                                              subtitle:
                                                  'Manage your account access',
                                              child: _AccountSummary(
                                                snapshot: data,
                                                onSignIn:
                                                    data
                                                            .service(
                                                              'email-sign-in',
                                                            )
                                                            .state ==
                                                        AccountCloudConnectionState
                                                            .connected
                                                    ? null
                                                    : widget.onSignIn ??
                                                          () => context.push(
                                                            '${AppRoutes.login}?from=account-cloud',
                                                          ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: mainCardWidth,
                                            child: _DashboardCard(
                                              title: 'QUICK CONNECT',
                                              subtitle:
                                                  'Connect services available to this account',
                                              child: _QuickConnectPanel(
                                                manifest:
                                                    widget.providerManifest ??
                                                    ProviderConnectorManifest
                                                        .standard,
                                                onConnectProvider:
                                                    widget.onConnectProvider,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: mainCardWidth,
                                            child: StorageUsageCard(
                                              onManage: widget.onSyncNow,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: AccountCenterDesignTokens
                                            .spacing
                                            .xl,
                                      ),
                                      Wrap(
                                        spacing: AccountCenterDesignTokens
                                            .layout
                                            .cardGap,
                                        runSpacing: AccountCenterDesignTokens
                                            .layout
                                            .cardGap,
                                        children: [
                                          for (final card in const [
                                            (
                                              'CONNECTED SERVICES OVERVIEW',
                                              'Connection summary',
                                              Icons.hub_outlined,
                                              'Connected services appear here after provider verification.',
                                            ),
                                            (
                                              'AI PROVIDERS',
                                              'AI model gateways',
                                              Icons.api_outlined,
                                              'Configure and test OpenAI or Gemini from AI Providers.',
                                            ),
                                            (
                                              'DEVELOPER TOOLS',
                                              'Source control and development services',
                                              Icons.code_outlined,
                                              'No developer service is connected.',
                                            ),
                                            (
                                              'CREATIVE TOOLS',
                                              'Design and media integrations',
                                              Icons.palette_outlined,
                                              'No creative tool is connected.',
                                            ),
                                            (
                                              'PAYMENT METHODS',
                                              'Billing service connections',
                                              Icons.payment_outlined,
                                              'No payment method is configured.',
                                            ),
                                            (
                                              'API KEYS MANAGER',
                                              'Credential inventory',
                                              Icons.key_outlined,
                                              'Credentials remain protected in the operating-system vault.',
                                            ),
                                            (
                                              'TEAM & COLLABORATION',
                                              'Members, roles, and invitations',
                                              Icons.groups_outlined,
                                              'Team management is not configured.',
                                            ),
                                            (
                                              'ACTIVITY LOG',
                                              'Recent account and integration events',
                                              Icons.history_outlined,
                                              'No account activity has been recorded.',
                                            ),
                                            (
                                              'BACKUP & SYNC',
                                              'Data protection and synchronization',
                                              Icons.sync_outlined,
                                              'No cloud backup destination is configured.',
                                            ),
                                            (
                                              'SECURITY CENTER',
                                              'Sessions and account protection',
                                              Icons.security_outlined,
                                              'Security telemetry is not available locally.',
                                            ),
                                          ])
                                            SizedBox(
                                              width: mainCardWidth,
                                              child: _OverviewCapabilityCard(
                                                title: card.$1,
                                                subtitle: card.$2,
                                                icon: card.$3,
                                                message: card.$4,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                                return main;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: railWidth,
                        child: _AccountSummaryRail(
                          plan: gridPlan,
                          snapshot: data,
                          operationalMetrics: operationalMetrics,
                          onSyncNow: widget.onSyncNow,
                          onBackupProject: widget.onBackupProject,
                          onOpenAiProviders: widget.onOpenAiProviders,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
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
  });

  /// Rencana grid tier (115.6) — kolom ringkasan mengikuti batas tier dan
  /// aturan fit card.minWidth, bukan heuristik 760px.
  final AccountCenterGridPlan plan;
  final AccountCloudSnapshot snapshot;
  final AsyncValue<AccountOperationalMetrics?> operationalMetrics;
  final VoidCallback? onSyncNow;
  final VoidCallback? onBackupProject;
  final VoidCallback? onOpenAiProviders;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = plan.cardWidthFor(constraints.maxWidth);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('ACCOUNT SUMMARY', style: _sectionTitle)),
              Icon(Icons.unfold_more, color: context.palette.textMuted),
            ],
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
          Wrap(
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
          ),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: title,
    subtitle: subtitle,
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

class _FocusedAccountArea extends StatelessWidget {
  const _FocusedAccountArea({
    required this.tab,
    required this.snapshot,
    this.onSignIn,
    this.onOpenAiProviders,
    this.onOpenSecurity,
  });

  final AccountCenterTab tab;
  final AccountCloudSnapshot snapshot;
  final VoidCallback? onSignIn;
  final VoidCallback? onOpenAiProviders;
  final VoidCallback? onOpenSecurity;

  @override
  Widget build(BuildContext context) {
    final cards = switch (tab.slug) {
      'connected_accounts' => const [
        (
          'AUTHENTICATION',
          'Account identity and sign-in state',
          Icons.person_outline,
          'Account access reflects the configured authentication provider.',
        ),
      ],
      'backup_sync' => const [
        (
          'BACKUP & SYNC',
          'Data protection and synchronization',
          Icons.sync_outlined,
          'Local project backups are available. Cloud sync remains unavailable until a provider is connected.',
        ),
      ],
      'cloud_storage' => const [
        (
          'CLOUD STORAGE USAGE',
          'Storage metering by provider',
          Icons.cloud_queue_outlined,
          'No connected provider is reporting quota or usage.',
        ),
        (
          'BACKUP & SYNC',
          'Data protection and synchronization',
          Icons.sync_outlined,
          'No cloud backup destination is configured.',
        ),
      ],
      'ai_providers' => const [
        (
          'API PROVIDERS',
          'AI model gateways',
          Icons.api_outlined,
          'Configure and test OpenAI or Gemini from AI Providers.',
        ),
        (
          'AI USAGE THIS MONTH',
          'Usage and estimated provider cost',
          Icons.show_chart_outlined,
          'No metering data is available from connected providers.',
        ),
      ],
      'api_keys' => const [
        (
          'DEVELOPER TOOLS',
          'Source control and development services',
          Icons.code_outlined,
          'No developer service is connected.',
        ),
        (
          'CREATIVE TOOLS',
          'Design and media integrations',
          Icons.palette_outlined,
          'No creative tool is connected.',
        ),
        (
          'API KEYS',
          'Credential inventory',
          Icons.key_outlined,
          'Credentials remain protected in the operating-system vault.',
        ),
      ],
      'team_collaboration' => const [
        (
          'TEAM & COLLABORATION',
          'Members, roles, and invitations',
          Icons.groups_outlined,
          'Team management is not configured.',
        ),
      ],
      'security' => const [
        (
          'SECURITY CENTER',
          'Sessions and account protection',
          Icons.security_outlined,
          'Security telemetry is not available locally.',
        ),
        (
          'ACTIVITY LOG',
          'Recent account and integration events',
          Icons.history_outlined,
          'No account activity has been recorded.',
        ),
      ],
      'billing' => const [
        (
          'PAYMENT METHODS',
          'Billing service connections',
          Icons.payment_outlined,
          'No payment method is configured.',
        ),
      ],
      _ => const [],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 820
            ? (constraints.maxWidth -
                      AccountCenterDesignTokens.layout.cardGap) /
                  2
            : constraints.maxWidth;
        return Wrap(
          spacing: AccountCenterDesignTokens.layout.cardGap,
          runSpacing: AccountCenterDesignTokens.layout.cardGap,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _OverviewCapabilityCard(
                  title: card.$1,
                  subtitle: card.$2,
                  icon: card.$3,
                  message: card.$4,
                ),
              ),
            if (tab.slug == 'connected_accounts')
              SizedBox(
                width: cardWidth,
                child: _DashboardCard(
                  title: 'ACCOUNT ACCESS',
                  subtitle: 'Current authentication state',
                  child: _AccountSummary(
                    snapshot: snapshot,
                    onSignIn: onSignIn,
                  ),
                ),
              ),
            if (tab.slug == 'backup_sync')
              for (final service in snapshot.services)
                SizedBox(
                  width: cardWidth,
                  child: _ServiceCard(service: service),
                ),
            if (tab.slug == 'cloud_storage')
              for (final service in snapshot.services.where(
                (service) =>
                    service.group == AccountCloudServiceGroup.cloudStorage,
              ))
                SizedBox(
                  width: cardWidth,
                  child: _ServiceCard(service: service),
                ),
            if (tab.slug == 'ai_providers')
              SizedBox(
                width: cardWidth,
                child: _DestinationActionCard(
                  label: 'Open AI Providers',
                  description:
                      'Configure credentials and run real provider connection tests.',
                  icon: Icons.arrow_forward,
                  onPressed: onOpenAiProviders,
                ),
              ),
            if (tab.slug == 'security')
              SizedBox(
                width: cardWidth,
                child: _DestinationActionCard(
                  label: 'Open Security Center',
                  description:
                      'Review the project security tools available in this build.',
                  icon: Icons.security_outlined,
                  onPressed: onOpenSecurity,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DestinationActionCard extends StatelessWidget {
  const _DestinationActionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    title: label.toUpperCase(),
    subtitle: description,
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AccountCenterDesignTokens.iconSizes.action),
        label: Text(label),
        // 115.7: default Material 3 TextButton 40px < target sentuh 44px.
        style: TextButton.styleFrom(
          minimumSize: const Size(
            0,
            AccountCenterAccessibility.minimumTouchTarget,
          ),
        ),
      ),
    ),
  );
}

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
  });

  final String title;
  final String subtitle;
  final Widget child;

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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionTitle),
        SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
        Text(subtitle, style: _caption),
        SizedBox(height: AccountCenterDesignTokens.spacing.md),
        child,
      ],
    ),
  );
}

class _QuickConnectPanel extends StatelessWidget {
  const _QuickConnectPanel({required this.manifest, this.onConnectProvider});

  final ProviderConnectorManifest manifest;
  final ValueChanged<ProviderConnectorEntry>? onConnectProvider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in manifest.all.where(
        (entry) => entry.category == ProviderConnectorCategory.cloudStorage,
      ))
        _ProviderTile(
          entry: entry,
          onConnect: onConnectProvider == null
              ? null
              : () => onConnectProvider!(entry),
        ),
    ],
  );
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
            final action = TextButton(
              onPressed: canConnect ? onConnect : null,
              child: Text(entry.isConnectable ? 'Connect' : 'Not available'),
            );
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
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }

            return Row(
              children: [
                _ProviderIcon(entry: entry),
                SizedBox(width: AccountCenterDesignTokens.spacing.sm),
                Expanded(child: details),
                action,
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

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.snapshot, this.onSignIn});

  final AccountCloudSnapshot snapshot;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(AccountCenterDesignTokens.card.padding),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(
        AccountCenterDesignTokens.radius.card,
      ),
      border: Border.all(color: context.palette.border),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: AccountCenterDesignTokens.avatarSizes.compact / 2,
          backgroundColor: context.palette.primary,
          child: const Icon(Icons.person_outline, color: Colors.white),
        ),
        SizedBox(width: AccountCenterDesignTokens.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.accountDisplayName,
                style: VoidTypography.headingMedium,
              ),
              SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
              Text(snapshot.accountModeLabel, style: _caption),
              if (onSignIn != null) ...[
                SizedBox(height: AccountCenterDesignTokens.spacing.md),
                OutlinedButton.icon(
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
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final AccountCloudService service;

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
    // 115.7: header kartu = satu node "nama, status"; deskripsi & usage tetap
    // dibaca sebagai teks terpisah di bawahnya.
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    ),
                  ),
                  _ConnectionBadge(state: service.state),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AccountCenterDesignTokens.spacing.sm),
        Text(service.description, style: _body),
        if (service.usageLabel case final usage?) ...[
          SizedBox(height: AccountCenterDesignTokens.spacing.sm),
          Text(usage, style: _caption),
        ],
      ],
    ),
  );
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
      child: Text(label, style: _caption.copyWith(color: color)),
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
