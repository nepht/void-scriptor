import 'package:flutter/material.dart';

import '../../domain/wardrobe_workspace_data.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Honest fallback for missing persisted values (vs-hunt-20260914-wardrobe-
/// weapon WBUG-5: absent data must never be papered over with sample text —
/// mirrors the ENV-BUG-002 dash convention from run271).
String wardrobeValue(String? value) =>
    (value == null || value.isEmpty) ? _dash : value;

const String _dash = '—';

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
  const WardrobeComponentsCard({super.key, required this.components});

  final List<WardrobeComponentInfo> components;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'Components',
    child: components.isEmpty
        ? const _EmptyNote(text: 'Belum ada komponen tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final component in components)
                _Chip(label: wardrobeValue(component.name)),
            ],
          ),
  );
}

class WardrobeColorPaletteCard extends StatelessWidget {
  const WardrobeColorPaletteCard({super.key, required this.colors});

  final List<WardrobeColorInfo> colors;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'Color Palette',
    child: colors.isEmpty
        ? const _EmptyNote(text: 'Belum ada warna tersimpan.')
        : Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              for (final color in colors)
                _ColorSwatch(
                  name: wardrobeValue(color.name),
                  color: _parseHex(color.hexValue),
                ),
            ],
          ),
  );

  static Color _parseHex(String hex) {
    final digits = hex.replaceFirst('#', '');
    final parsed = int.tryParse(digits, radix: 16);
    if (parsed == null) return const Color(0xFF808080);
    if (digits.length <= 6) return Color(0xFF000000 | parsed);
    return Color(parsed);
  }
}

/// Material/Fabric summary derived from persisted component rows; the old
/// card listed three invented fabrics that had no source row at all
/// (WBUG-5).
class WardrobeMaterialCard extends StatelessWidget {
  const WardrobeMaterialCard({super.key, required this.components});

  final List<WardrobeComponentInfo> components;

  @override
  Widget build(BuildContext context) {
    final values = <String>{
      for (final component in components)
        if (component.material.isNotEmpty) component.material,
      for (final component in components)
        if (component.fabric.isNotEmpty) component.fabric,
    };
    return _WardrobeCard(
      title: 'Material / Fabric',
      child: values.isEmpty
          ? const _EmptyNote(text: 'Belum ada material tersimpan.')
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final value in values) _Chip(label: value)],
            ),
    );
  }
}

class WardrobeVariantsCard extends StatelessWidget {
  const WardrobeVariantsCard({super.key, required this.variants});

  final List<WardrobeVariantInfo> variants;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'Variants',
    child: variants.isEmpty
        ? const _EmptyNote(text: 'Belum ada varian tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final variant in variants)
                _Chip(
                  label: wardrobeValue(variant.name),
                  marker: variant.isDefault
                      ? const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFC85C),
                        )
                      : null,
                ),
            ],
          ),
  );
}

class WardrobeReferencesCard extends StatelessWidget {
  const WardrobeReferencesCard({super.key, required this.references});

  final List<WardrobeReferenceInfo> references;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: 'References',
    child: references.isEmpty
        ? const _EmptyNote(text: 'Belum ada referensi tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final reference in references)
                _Chip(label: wardrobeValue(reference.referenceType)),
            ],
          ),
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: context.palette.textMuted));
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
  const _Chip({required this.label, this.marker});
  final String label;
  final Widget? marker;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    avatar: marker,
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
      Text(name, style: TextStyle(color: context.palette.textPrimary)),
    ],
  );
}
