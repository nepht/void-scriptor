import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/commands/project_mutation_state.dart';
import '../../navigation/app_navigation_registry.dart';
import '../../../design_system/widgets/branding/brand_assets.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/design_system/typography/void_typography.dart';

class VoidTopBar extends StatelessWidget {
  const VoidTopBar({
    super.key,
    required this.onMenuSelected,
    this.onLogout,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.saveState,
    this.onOpenSearch,
    this.projectContext,
    this.height = 32,
  });

  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onLogout;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  /// Null when no project session is open (no save-status chip rendered).
  final ProjectMutationState? saveState;

  /// Opens the global project search sheet (command-palette entry point).
  final VoidCallback? onOpenSearch;

  /// Null when no project session is open (no project-context button).
  final ProjectContextSummary? projectContext;

  /// Global default stays compact; Account & Cloud Center opts into the
  /// taller reference chrome at its route boundary.
  final double height;
  @override
  Widget build(BuildContext context) {
    final saveState = this.saveState;
    final projectContext = this.projectContext;
    return Container(
      // 115.38 (Choi, 2026-09-27): default top bar 39px -> 32px. Isi di dalamnya ikut
      // dikecilkan supaya muat: avatar 32px, _TopMenuButton 30px
      // (padding 6 + ikon 16 + teks 12 + padding 6), dan project-context
      // button 28px. Border bawah 1px brings the total to 32.
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.palette.panel,
        border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAllCore = constraints.maxWidth >= 1320;
          final showFullBrand = constraints.maxWidth >= 1500;
          // Project workspaces belong in the Explorer sidebar, not global
          // desktop navigation. Keep the shared registry intact for mobile.
          // Frontier 2: project workspaces live in the Explorer sidebar and
          // Backup & Export moved into the project-context menu. Global
          // desktop navigation keeps only Dashboard, Projects, Search.
          final desktopDestinations = coreNavigationDestinations
              .where(
                (destination) =>
                    destination.id == AppNavigationId.dashboard ||
                    destination.id == AppNavigationId.novels ||
                    destination.id == AppNavigationId.search,
              )
              .toList(growable: false);
          final visibleCore = showAllCore
              ? desktopDestinations
              : desktopDestinations.take(3).toList(growable: false);
          final hiddenCore = showAllCore
              ? const <AppNavigationDestination>[]
              : desktopDestinations.skip(3).toList(growable: false);
          return Row(
            children: [
              SizedBox(
                width: showFullBrand ? 230 : 40,
                child: VoidLogo(compact: !showFullBrand),
              ),
              const SizedBox(width: 8),
              if (projectContext != null)
                Flexible(
                  child: _ProjectContextButton(
                    summary: projectContext,
                    onMenuSelected: onMenuSelected,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final destination in visibleCore)
                        _TopMenuButton(
                          label: destination.label,
                          icon: destination.icon,
                          onTap: () => onMenuSelected(destination.key),
                        ),
                      if (hiddenCore.isNotEmpty)
                        _NavigationOverflow(
                          tooltip: 'More navigation',
                          destinations: hiddenCore,
                          onSelected: onMenuSelected,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saveState != null)
                    _SaveStateChip(dirty: saveState.isDirty),
                  _TopIconButton(
                    icon: LucideIcons.undo2,
                    tooltip: 'Undo',
                    onPressed: canUndo ? onUndo : null,
                  ),
                  _TopIconButton(
                    icon: LucideIcons.redo2,
                    tooltip: 'Redo',
                    onPressed: canRedo ? onRedo : null,
                  ),
                  if (onOpenSearch != null)
                    _TopIconButton(
                      icon: LucideIcons.command,
                      tooltip: 'Search across the project',
                      onPressed: onOpenSearch,
                    ),
                  _AiStudioMenu(onMenuSelected: onMenuSelected),
                  _OptionalToolsMenu(onMenuSelected: onMenuSelected),
                  _AccountMenu(
                    onMenuSelected: onMenuSelected,
                    onLogout: onLogout,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Summary of the active project session rendered as the project-context
/// entry point in the top bar. Null when no session is open.
class ProjectContextSummary {
  const ProjectContextSummary({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;
}

class _ProjectContextButton extends StatelessWidget {
  const _ProjectContextButton({
    required this.summary,
    required this.onMenuSelected,
  });

  final ProjectContextSummary summary;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Project context',
    onSelected: onMenuSelected,
    itemBuilder: (context) => const [
      PopupMenuItem(value: 'backup-export', child: Text('Backup & Export')),
    ],
    child: Container(
      // 115.38: ikut top bar 32px.
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.palette.panel,
        border: Border.all(color: context.palette.borderSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                summary.projectName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: VoidTypography.appBrand,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    ),
  );
}

class _SaveStateChip extends StatelessWidget {
  const _SaveStateChip({required this.dirty});

  final bool dirty;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          dirty ? Icons.circle : Icons.check_circle_outline,
          size: 12,
          color: dirty
              ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.amberAccent
                    : Colors.amber.shade800)
              : Colors.green,
        ),
        const SizedBox(width: 6),
        Text(
          dirty ? 'Belum tersimpan' : 'Tersimpan',
          style: VoidTypography.caption.copyWith(
            color: context.palette.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _TopMenuButton extends StatelessWidget {
  const _TopMenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      // 115.38: padding vertikal 8 -> 6 supaya tombol menu muat di top bar 32px.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.palette.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: VoidTypography.topNavigation.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationOverflow extends StatelessWidget {
  const _NavigationOverflow({
    required this.tooltip,
    required this.destinations,
    required this.onSelected,
  });

  final String tooltip;
  final List<AppNavigationDestination> destinations;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: tooltip,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final destination in destinations)
        PopupMenuItem(
          value: destination.key,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(destination.icon, size: 19),
            title: Text(destination.label),
          ),
        ),
    ],
    icon: const Icon(Icons.more_horiz_rounded),
  );
}

class _AiStudioMenu extends StatelessWidget {
  const _AiStudioMenu({required this.onMenuSelected});

  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'AI Studio',
    onSelected: onMenuSelected,
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'ai',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.auto_awesome_outlined, size: 19),
          title: Text('Open AI Studio'),
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 'ai-image-generator',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.image_outlined, size: 19),
          title: Text('Image Generator'),
        ),
      ),
      PopupMenuItem(
        value: 'ai-video-generator',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.movie_creation_outlined, size: 19),
          title: Text('Video Generator'),
        ),
      ),
    ],
    child: const _TopMenuButtonContent(
      label: 'AI Studio',
      icon: Icons.auto_awesome_outlined,
    ),
  );
}

class _TopMenuButtonContent extends StatelessWidget {
  const _TopMenuButtonContent({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.palette.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: VoidTypography.topNavigation.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(width: 3),
        Icon(
          Icons.arrow_drop_down_rounded,
          size: 16,
          color: context.palette.textMuted,
        ),
      ],
    ),
  );
}

class _OptionalToolsMenu extends StatelessWidget {
  const _OptionalToolsMenu({required this.onMenuSelected});

  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Optional tools',
    onSelected: (key) {
      if (key == 'donate') {
        _showDonationDialog(context);
      } else {
        onMenuSelected(key);
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(enabled: false, child: Text('Optional tools')),
      for (final destination in optionalNavigationDestinations)
        PopupMenuItem(
          value: destination.key,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(destination.icon, size: 19),
            title: Text(destination.label),
          ),
        ),
    ],
    icon: const Icon(Icons.extension_outlined),
  );
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.onMenuSelected, this.onLogout});

  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Account menu',
    onSelected: (key) {
      if (key == 'logout') {
        onLogout?.call();
      } else {
        onMenuSelected(key);
      }
    },
    itemBuilder: (context) => const [
      PopupMenuItem(value: 'settings', child: Text('Settings')),
      PopupMenuItem(value: 'account-cloud', child: Text('Account & Cloud')),
      PopupMenuDivider(),
      PopupMenuItem(value: 'logout', child: Text('Log out')),
    ],
    // 115.38: avatar 32px (radius 16) pas di tinggi top bar 32px.
    icon: CircleAvatar(
      radius: 16,
      backgroundColor: context.palette.primary,
      child: const Icon(Icons.person_outline, size: 18, color: Colors.white),
    ),
  );
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class DonationOption {
  final String label;
  final String? asset;
  final IconData? icon;
  final String note;

  const DonationOption({
    required this.label,
    this.asset,
    this.icon,
    required this.note,
  });
}

void _showDonationDialog(BuildContext context) {
  const methods = [
    DonationOption(
      label: 'QRIS',
      asset: BrandAssets.paymentQris,
      note: 'Scan QRIS dengan e-wallet apa pun.',
    ),
    DonationOption(
      label: 'SeaBank',
      asset: BrandAssets.paymentSeaBank,
      note: 'Transfer bank SeaBank (no admin fee).',
    ),
    DonationOption(
      label: 'DANA',
      asset: BrandAssets.paymentDana,
      note: 'Transfer ke akun DANA.',
    ),
    DonationOption(
      label: 'GoPay',
      asset: BrandAssets.paymentGoPay,
      note: 'Transfer ke akun GoPay.',
    ),
    DonationOption(
      label: 'Visa',
      asset: BrandAssets.paymentVisa,
      note: 'Kartu Visa (via payment gateway).',
    ),
  ];

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
          SizedBox(width: 8),
          Text('Support Void Scriptor'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih metode pembayaran. Integrasi otomatis belum '
                'aktif — nomor/QR akan ditampilkan di sini setelah '
                'konfigurasi payment gateway.',
                style: VoidTypography.caption,
              ),
              const SizedBox(height: 16),
              ...methods.map(
                (m) => ListTile(
                  leading: m.asset != null
                      ? BrandLogo(assetPath: m.asset!, width: 32, height: 32)
                      : Icon(m.icon ?? Icons.payment),
                  title: Text(m.label),
                  subtitle: Text(m.note, style: VoidTypography.caption),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Metode ${m.label} dipilih (belum terkonfigurasi).',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
