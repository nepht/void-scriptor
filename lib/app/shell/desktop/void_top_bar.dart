import 'package:flutter/material.dart';

import '../../../core/theme/theme_mode_menu.dart';
import '../../../design_system/widgets/branding/brand_assets.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../features/collaboration/domain/sync_models.dart';
import '../../../features/collaboration/presentation/sync_status_indicator.dart';
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
    this.syncStatus = const SyncStatus(),
  });

  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onLogout;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final SyncStatus syncStatus;

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
          final wide = constraints.maxWidth >= 1200;
          return Row(
            children: [
              const SizedBox(width: 230, child: VoidLogo()),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TopMenuButton(
                        label: 'Workspace',
                        onTap: () => onMenuSelected('workspace'),
                      ),
                      _TopMenuButton(
                        label: 'Projects',
                        onTap: () => onMenuSelected('projects'),
                      ),
                      _TopMenuButton(
                        label: 'AI Tools',
                        onTap: () => onMenuSelected('ai'),
                      ),
                      _TopMenuButton(
                        label: 'Assets',
                        onTap: () => onMenuSelected('assets'),
                      ),
                      _TopMenuButton(
                        label: 'Bible',
                        onTap: () => onMenuSelected('bible'),
                      ),
                      if (wide) ...[
                        _TopMenuButton(
                          label: 'Marketplace',
                          onTap: () => onMenuSelected('marketplace'),
                        ),
                        _TopMenuButton(
                          label: 'Donate',
                          onTap: () => onMenuSelected('donate'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (wide) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  height: 34,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, size: 17),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
              ),
              _TopIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onPressed: canRedo ? onRedo : null,
              ),
              _TopIconButton(
                icon: Icons.health_and_safety_outlined,
                tooltip: 'Project resilience',
                onPressed: () => onMenuSelected('resilience'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SyncStatusIndicator(status: syncStatus),
              ),
              const _TopIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
              ),
              _TopIconButton(
                icon: Icons.favorite_border_rounded,
                tooltip: 'Donate / Support',
                onPressed: () {
                  _showDonationDialog(context);
                },
              ),
              const ThemeModeMenu(),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 16,
                backgroundColor: context.palette.primary,
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopMenuButton extends StatelessWidget {
  const _TopMenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
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
