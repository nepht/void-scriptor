import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/widgets/branding/brand_assets.dart';

/// Galeri brand terintegrasi: logo brand dalam grid seragam.
/// Setiap logo ditampilkan dalam container berukuran sama dengan
/// tooltip sebagai label (tanpa teks di bawahnya).
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
    _BrandEntry(label: 'QRIS', asset: BrandAssets.paymentQris),
    _BrandEntry(label: 'Dana', asset: BrandAssets.paymentDana),
    _BrandEntry(label: 'SeaBank', asset: BrandAssets.paymentSeaBank),
    _BrandEntry(label: 'Visa', asset: BrandAssets.paymentVisa),
    _BrandEntry(label: 'GoPay', asset: BrandAssets.paymentGoPay),
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
            maxCrossAxisExtent: 88,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _brands.length,
          itemBuilder: (context, i) {
            final b = _brands[i];
            return Tooltip(
              message: b.label,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: BrandLogo(
                    assetPath: b.asset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
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
