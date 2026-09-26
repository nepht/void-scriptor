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

  /// 115.36: panel tunggal — tab adalah anchor scroll, bukan pemisah konten.
  /// Kunci ini mengikat posisi scroll ke tab kanonik saat deep link `?tab=`.
  final ScrollController _panelScroll = ScrollController();

  /// Offset absolut tiap anchor section terhadap panel scroll, diisi oleh
  /// [_AccountSectionAnchor] setelah frame pertama.
  final Map<String, double> _anchorOffsets = <String, double>{};

  /// Offset anchor yang harus digulirkan setelah frame berikut.
  ///
  /// Disimpan, bukan langsung dipakai, supaya pengukuran anchor terjadi
  /// setelah layout benar-benar tersedia.
  double? _pendingAnchorOffset;

  @override
  void initState() {
    super.initState();
    _tab = AccountCenterInformationArchitecture.resolveTab(widget.initialTab);
    if (widget.onTabChanged == null) {
      _pendingAnchorOffset = double.infinity;
    }
    _scheduleAnchorReveal();
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
      if (widget.onTabChanged == null) {
        _pendingAnchorOffset = double.infinity;
        _scheduleAnchorReveal();
      }
    }
  }

  @override
  void dispose() {
    _panelScroll.dispose();
    super.dispose();
  }

  /// Menggulir ke anchor section kanonik yang terkait [_tab].
  ///
  /// [offset] berasal dari pengukuran nyata layout (bukan konstanta), lalu
  /// dijepit agar tidak melewati panjang maksimum scroll.
  void _recordAnchorOffset(String slug, double offset) {
    _anchorOffsets[slug] = offset;
  }

  /// Dijalankan setelah frame agar offset anchor sudah terukur nyata.
  void _scheduleAnchorReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _revealAnchor();
      }
    });
  }

  void _revealAnchor() {
    if (!_panelScroll.hasClients) {
      return;
    }
    final target = _anchorOffsets[_tab.slug] ?? _pendingAnchorOffset ?? 0.0;
    _panelScroll.jumpTo(
      target.clamp(0.0, _panelScroll.position.maxScrollExtent),
    );
    _pendingAnchorOffset = null;
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
    _pendingAnchorOffset = double.infinity;
    _scheduleAnchorReveal();
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
              controller: _panelScroll,
              padding: EdgeInsets.symmetric(
                horizontal:
                    AccountCenterDesignTokens.layout.pageHorizontalPadding,
                vertical: AccountCenterDesignTokens.layout.pageVerticalPadding,
              ),
              // Panel tunggal lebih tinggi dari viewport. When the widget is
              // hosted without a Scaffold (bare MaterialApp harness), the
              // incoming height is unbounded; keep the column finite so every
              // area still lays out instead of being dropped.
              physics: constraints.hasBoundedHeight
                  ? null
                  : const NeverScrollableScrollPhysics(),
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
                                final main = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 115.36: panel tunggal. Semua area kanonik
                                    // dirender sekaligus; tab hanya menentukan
                                    // anchor scroll dan breadcrumb.
                                    _FocusedAccountArea(
                                      tab: _tab,
                                      snapshot: data,
                                      gridPlan: gridPlan,
                                      providerManifest:
                                          widget.providerManifest ??
                                          ProviderConnectorManifest.standard,
                                      onConnectProvider:
                                          widget.onConnectProvider,
                                      onSyncNow: widget.onSyncNow,
                                      onAnchorMeasured: _recordAnchorOffset,
                                      onSignIn:
                                          data.service('email-sign-in').state ==
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
    required this.onAnchorMeasured,
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

  /// Laporan posisi anchor ke state panel (slug tab, offset absolut).
  final void Function(String slug, double offset) onAnchorMeasured;

  final VoidCallback? onSignIn;
  final VoidCallback? onOpenAiProviders;
  final VoidCallback? onOpenSecurity;

  @override
  Widget build(BuildContext context) {
    final gap = AccountCenterDesignTokens.layout.cardGap;
    final signInAction =
        onSignIn ?? () => context.push('${AppRoutes.login}?from=account-cloud');
    final aiProvidersAction =
        onOpenAiProviders ?? () => context.push(AppRoutes.aiProviders);
    final securityAction =
        onOpenSecurity ?? () => context.push(AppRoutes.security);

    // Kartu ringkas per area. Area overview memakai tiga kartu mockup
    // (autentikasi, quick connect, storage); area lain memakai kartu
    // ringkasan + aksi yang relevan, tetap satu panel.
    final sections = <_AccountSection>[
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[0],
        cards: [
          _AccountSectionCard.dashboard(
            key: const ValueKey('account-overview-card-authentication'),
            title: 'AUTHENTICATION',
            subtitle: 'Manage your account access',
            child: _AccountSummary(snapshot: snapshot, onSignIn: signInAction),
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
          // Mockup row 1: connection summary. Sign-in surface stays owned by
          // the overview AUTHENTICATION card, so this card lists services only.
          // 115.36 mockup baris 2: "Connected Services Overview" meringkas
          // seluruh drive dalam SATU kartu. Memetakan satu kartu penuh per
          // service membuat enam kartu meledak menjadi baris penuh dan
          // menduplikasi QUICK CONNECT — melanggar mockup dan aturan
          // satu kapabilitas = satu owner kanonik.
          _AccountSectionCard.dashboard(
            title: 'CONNECTED SERVICES OVERVIEW',
            subtitle: 'Connection summary',
            icon: Icons.hub_outlined,
            child: _ServiceSummaryList(services: snapshot.services),
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[2],
        cards: [
          _AccountSectionCard.dashboard(
            title: 'STORAGE BREAKDOWN',
            subtitle: 'Per-provider allocation',
            child: StorageUsageCard(onManage: onSyncNow),
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[3],
        cards: [
          const _AccountSectionCard.capability(
            title: 'API PROVIDERS',
            subtitle: 'AI model gateways',
            icon: Icons.api_outlined,
            message: 'Configure and test OpenAI or Gemini from AI Providers.',
          ),
          const _AccountSectionCard.capability(
            title: 'AI USAGE THIS MONTH',
            subtitle: 'Usage and estimated provider cost',
            icon: Icons.show_chart_outlined,
            message: 'No metering data is available from connected providers.',
          ),
          _AccountSectionCard.action(
            title: 'Open AI Providers',
            subtitle:
                'Configure credentials and run real provider connection tests.',
            icon: Icons.arrow_forward,
            onPressed: aiProvidersAction,
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[4],
        cards: [
          const _AccountSectionCard.capability(
            title: 'DEVELOPER TOOLS',
            subtitle: 'Source control and development services',
            icon: Icons.code_outlined,
            message: 'No developer service is connected.',
          ),
          const _AccountSectionCard.capability(
            title: 'CREATIVE TOOLS',
            subtitle: 'Design and media integrations',
            icon: Icons.palette_outlined,
            message: 'No creative tool is connected.',
          ),
          const _AccountSectionCard.capability(
            title: 'API KEYS',
            subtitle: 'Credential inventory',
            icon: Icons.key_outlined,
            message:
                'Credentials remain protected in the operating-system vault.',
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[5],
        cards: [
          const _AccountSectionCard.capability(
            title: 'TEAM & COLLABORATION',
            subtitle: 'Members, roles, and invitations',
            icon: Icons.groups_outlined,
            message: 'Team management is not configured.',
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[6],
        cards: [
          const _AccountSectionCard.capability(
            title: 'SECURITY CENTER',
            subtitle: 'Sessions and account protection',
            icon: Icons.security_outlined,
            message: 'Security telemetry is not available locally.',
          ),
          const _AccountSectionCard.capability(
            title: 'ACTIVITY LOG',
            subtitle: 'Recent account and integration events',
            icon: Icons.history_outlined,
            message: 'No account activity has been recorded.',
          ),
          _AccountSectionCard.action(
            title: 'Open Security Center',
            subtitle:
                'Review the project security tools available in this build.',
            icon: Icons.security_outlined,
            onPressed: securityAction,
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[7],
        cards: [
          const _AccountSectionCard.capability(
            title: 'BACKUP & SYNC',
            subtitle: 'Data protection and synchronization',
            icon: Icons.sync_outlined,
            message:
                'Local project backups are available. Cloud sync remains unavailable until a provider is connected.',
          ),
        ],
      ),
      _AccountSection(
        tab: AccountCenterInformationArchitecture.tabs[8],
        cards: [
          const _AccountSectionCard.capability(
            title: 'PAYMENT METHODS',
            subtitle: 'Billing service connections',
            icon: Icons.payment_outlined,
            message: 'No payment method is configured.',
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
        final columns = gridPlan.columnsFor(constraints.maxWidth);
        final contentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : gridPlan.cardWidthFor(constraints.maxWidth);
        final cardWidth = ((contentWidth - gap * (columns - 1)) / columns)
            .clamp(0.0, contentWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              _AccountSectionAnchor(
                // Key pada anchor = seam yang dipakai tab strip & deep link.
                key: ValueKey('account-anchor-${section.tab.slug}'),
                tab: section.tab,
                active: section.tab == tab,
                onMeasured: onAnchorMeasured,
                child: Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in section.cards)
                        SizedBox(
                          width: cardWidth,
                          child: KeyedSubtree(
                            key: card.key,
                            child: card.build(context),
                          ),
                        ),
                    ],
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

/// Satu area kanonik dalam panel tunggal: anchor scroll + deretan kartunya.
class _AccountSection {
  const _AccountSection({required this.tab, required this.cards});

  final AccountCenterTab tab;
  final List<_AccountSectionCard> cards;
}

/// Anchor scroll untuk satu area kanonik.
///
/// Mendaftarkan posisi dirinya terhadap panel scroll supaya tab strip dan deep
/// link `?tab=` bisa menggulir ke sini. Pengukuran terjadi setelah frame
/// pertama, lalu dilaporkan lewat [onMeasured] (slug tab, offset absolut).
class _AccountSectionAnchor extends StatefulWidget {
  const _AccountSectionAnchor({
    super.key,
    required this.tab,
    required this.active,
    required this.child,
    required this.onMeasured,
  });

  final AccountCenterTab tab;
  final bool active;
  final Widget child;
  final void Function(String slug, double offset) onMeasured;

  @override
  State<_AccountSectionAnchor> createState() => _AccountSectionAnchorState();
}

class _AccountSectionAnchorState extends State<_AccountSectionAnchor> {
  final GlobalKey _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _measureAfterFrame();
  }

  @override
  void didUpdateWidget(covariant _AccountSectionAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Anchor aktif berubah posisi relatif setelah digulir; offset lama basi.
    if (oldWidget.active != widget.active) {
      _measureAfterFrame();
    }
  }

  void _measureAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) {
        return;
      }
      widget.onMeasured(widget.tab.slug, box.localToGlobal(Offset.zero).dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Semantics memberi pembaca layar nama section saat menavigasi panel
    // tunggal yang panjang.
    return Semantics(
      identifier: 'account-anchor-${widget.tab.slug}',
      header: true,
      label: widget.tab.label,
      child: KeyedSubtree(
        key: _measureKey,
        child: Semantics(container: true, child: widget.child),
      ),
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
  }) : _kind = _AccountSectionCardKind.capability,
       child = null,
       onPressed = null,
       key = null;

  const _AccountSectionCard.action({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  }) : _kind = _AccountSectionCardKind.action,
       child = null,
       message = null,
       key = null;

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

  Widget build(BuildContext context) => switch (_kind) {
    _AccountSectionCardKind.dashboard => _DashboardCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: child!,
    ),
    _AccountSectionCardKind.capability => _OverviewCapabilityCard(
      title: title,
      subtitle: subtitle,
      icon: icon!,
      message: message!,
    ),
    _AccountSectionCardKind.action => _DestinationActionCard(
      label: title,
      description: subtitle,
      icon: icon!,
      onPressed: onPressed,
    ),
  };
}

enum _AccountSectionCardKind { dashboard, capability, action }

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
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Ikon kategori opsional pada baris judul (ikon token scale, bukan ukuran
  /// hardcode). Kartu mockup baris pertama tetap tanpa ikon.
  final IconData? icon;

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

/// Ringkasan service terhubung dalam satu kartu (115.36 mockup).
///
/// Mockup memakai SATU kartu "Connected Services Overview" yang meringkas
/// seluruh drive sebagai baris compact. Versi sebelumnya memetakan satu kartu
/// penuh per service; itu meledak menjadi N baris di panel tunggal dan
/// menduplikasi kapabilitas QUICK CONNECT.
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
