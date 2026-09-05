import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../navigation/app_navigation_registry.dart';
import '../../../core/theme/theme_mode_menu.dart';
import '../../../design_system/widgets/branding/brand_assets.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class VoidTopBar extends StatelessWidget {
  const VoidTopBar({
    super.key,
    required this.onMenuSelected,
    this.onLogout,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onLogout;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
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
          final desktopDestinations = coreNavigationDestinations
              .where(
                (destination) =>
                    destination.id != AppNavigationId.characters &&
                    destination.id != AppNavigationId.world,
              )
              .toList(growable: false);
          final visibleCore = showAllCore
              ? desktopDestinations
              : desktopDestinations.take(4).toList(growable: false);
          final hiddenCore = showAllCore
              ? const <AppNavigationDestination>[]
              : desktopDestinations.skip(4).toList(growable: false);
          return Row(
            children: [
              SizedBox(
                width: showFullBrand ? 230 : 40,
                child: VoidLogo(compact: !showFullBrand),
              ),
              const SizedBox(width: 8),
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
                  _AiStudioMenu(onMenuSelected: onMenuSelected),
                  _OptionalToolsMenu(onMenuSelected: onMenuSelected),
                  const ThemeModeMenu(),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.palette.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
      } else if (key == 'donate') {
        _showDonationDialog(context);
      } else {
        onMenuSelected(key);
      }
    },
    itemBuilder: (context) => const [
      PopupMenuItem(value: 'account-cloud', child: Text('Account & Cloud')),
      PopupMenuItem(value: 'donate', child: Text('Support Void Scriptor')),
      PopupMenuDivider(),
      PopupMenuItem(value: 'logout', child: Text('Log out')),
    ],
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
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...methods.map(
                (m) => ListTile(
                  leading: m.asset != null
                      ? BrandLogo(assetPath: m.asset!, width: 32, height: 32)
                      : Icon(m.icon ?? Icons.payment),
                  title: Text(m.label),
                  subtitle: Text(m.note, style: const TextStyle(fontSize: 11)),
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
