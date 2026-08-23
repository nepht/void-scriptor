import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WardrobeProductCard extends StatelessWidget {
  const WardrobeProductCard({super.key});

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'Product View',
    child: AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.borderSoft),
        ),
        child: Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 56,
            color: context.palette.textMuted,
          ),
        ),
      ),
    ),
  );
}

class WardrobeSpecificationCard extends StatelessWidget {
  const WardrobeSpecificationCard({
    super.key,
    required this.category,
    required this.material,
    required this.fabric,
    required this.fit,
    required this.style,
  });

  final String category;
  final String material;
  final String fabric;
  final String fit;
  final String style;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'Specification',
    child: Column(
      children: [
        _PropertyRow(label: 'Category', value: category),
        _PropertyRow(label: 'Material', value: material),
        _PropertyRow(label: 'Fabric', value: fabric),
        _PropertyRow(label: 'Fit', value: fit),
        _PropertyRow(label: 'Style', value: style),
      ],
    ),
  );
}

class WardrobeComponentsCard extends StatelessWidget {
  const WardrobeComponentsCard({super.key});

  @override
  Widget build(BuildContext context) => const _WardrobeCard(
    title: 'Components',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Chip(label: 'Outer Coat'),
        _Chip(label: 'Inner Shirt'),
        _Chip(label: 'Pants'),
        _Chip(label: 'Gloves'),
        _Chip(label: 'Boots'),
        _Chip(label: 'Belt'),
      ],
    ),
  );
}

class WardrobeColorPaletteCard extends StatelessWidget {
  const WardrobeColorPaletteCard({super.key});

  @override
  Widget build(BuildContext context) => const _WardrobeCard(
    title: 'Color Palette',
    child: Wrap(
      spacing: 18,
      runSpacing: 12,
      children: [
        _ColorSwatch(name: 'Void Black', color: Color(0xFF050507)),
        _ColorSwatch(name: 'Void Violet', color: Color(0xFF5A2DFF)),
        _ColorSwatch(name: 'Electric Blue', color: Color(0xFF1E8DFF)),
      ],
    ),
  );
}

class WardrobeMaterialCard extends StatelessWidget {
  const WardrobeMaterialCard({super.key});

  @override
  Widget build(BuildContext context) => const _WardrobeCard(
    title: 'Material / Fabric',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Chip(label: 'Technical Fabric'),
        _Chip(label: 'Leather'),
        _Chip(label: 'Synthetic'),
      ],
    ),
  );
}

class WardrobeVariantsCard extends StatelessWidget {
  const WardrobeVariantsCard({super.key});

  @override
  Widget build(BuildContext context) => const _WardrobeCard(
    title: 'Variants',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Chip(label: 'Normal'),
        _Chip(label: 'Combat'),
        _Chip(label: 'Damaged'),
        _Chip(label: 'Winter'),
      ],
    ),
  );
}

class WardrobeReferencesCard extends StatelessWidget {
  const WardrobeReferencesCard({super.key});

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'References',
    child: Text(
      'Front, Back, Side, Fabric, Construction, Hardware, Color',
      style: TextStyle(color: context.palette.textMuted),
    ),
  );
}

class _WardrobeCard extends StatelessWidget {
  const _WardrobeCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: context.palette.panelSecondary,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: context.palette.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.palette.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: context.palette.surfaceElevated,
    labelStyle: TextStyle(color: context.palette.textPrimary),
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});
  final String name;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: context.palette.borderSoft),
        ),
      ),
      const SizedBox(width: 8),
      Text(name, style: TextStyle(color: context.palette.textMuted)),
    ],
  );
}
