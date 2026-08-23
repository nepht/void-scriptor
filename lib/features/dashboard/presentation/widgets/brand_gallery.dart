import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:void_scriptor/design_system/widgets/branding/brand_assets.dart';

/// Galeri brand yang terintegrasi: menampilkan logo brand + icon UI (Lucide)
/// dalam grid seragam agar rapih dan mudah dibaca.
class BrandGallery extends StatelessWidget {
  const BrandGallery({super.key});

  static const List<_BrandEntry> _brands = [
    _BrandEntry(label: 'Gemini', asset: BrandAssets.aiGemini),
    _BrandEntry(label: 'DeepSeek', asset: BrandAssets.aiDeepSeek),
    _BrandEntry(label: 'OpenAI', asset: BrandAssets.aiOpenai),
    _BrandEntry(label: 'Midjourney', asset: BrandAssets.aiMidjourney),
    _BrandEntry(label: 'Claude', asset: BrandAssets.aiClaude),
    _BrandEntry(label: 'Flutter', asset: BrandAssets.techFlutter),
    _BrandEntry(label: 'Dart', asset: BrandAssets.techDart),
    _BrandEntry(label: 'Indonesia', asset: BrandAssets.flagIndonesia),
    _BrandEntry(label: 'Japan', asset: BrandAssets.flagJapan),
    _BrandEntry(label: 'QRIS', asset: BrandAssets.paymentQris),
    _BrandEntry(label: 'Dana', asset: BrandAssets.paymentDana),
    _BrandEntry(label: 'SeaBank', asset: BrandAssets.paymentSeaBank),
    _BrandEntry(label: 'Visa', asset: BrandAssets.paymentVisa),
    _BrandEntry(label: 'GoPay', asset: BrandAssets.paymentGoPay),
  ];

  static const List<_IconEntry> _icons = [
    _IconEntry(icon: LucideIcons.home, label: 'Home'),
    _IconEntry(icon: LucideIcons.settings, label: 'Settings'),
    _IconEntry(icon: LucideIcons.user, label: 'User'),
    _IconEntry(icon: LucideIcons.search, label: 'Search'),
    _IconEntry(icon: LucideIcons.folder, label: 'Folder'),
    _IconEntry(icon: LucideIcons.save, label: 'Save'),
    _IconEntry(icon: LucideIcons.edit, label: 'Edit'),
    _IconEntry(icon: LucideIcons.trash, label: 'Trash'),
    _IconEntry(icon: LucideIcons.download, label: 'Download'),
    _IconEntry(icon: LucideIcons.upload, label: 'Upload'),
    _IconEntry(icon: LucideIcons.share, label: 'Share'),
    _IconEntry(icon: LucideIcons.star, label: 'Star'),
    _IconEntry(icon: LucideIcons.heart, label: 'Heart'),
    _IconEntry(icon: LucideIcons.bell, label: 'Bell'),
    _IconEntry(icon: LucideIcons.clock, label: 'Clock'),
    _IconEntry(icon: LucideIcons.moon, label: 'Moon'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brand Assets Terintegrasi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _brands.length,
          itemBuilder: (context, i) {
            final b = _brands[i];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BrandLogo(assetPath: b.asset, width: 36, height: 36),
                const SizedBox(height: 6),
                Text(
                  b.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Lucide UI Icons', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 90,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _icons.length,
          itemBuilder: (context, i) {
            final ic = _icons[i];
            return Tooltip(
              message: ic.label,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Center(
                  child: Icon(ic.icon, size: 22, color: cs.onSurfaceVariant),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BrandEntry {
  final String label;
  final String asset;
  const _BrandEntry({required this.label, required this.asset});
}

class _IconEntry {
  final IconData icon;
  final String label;
  const _IconEntry({required this.icon, required this.label});
}
