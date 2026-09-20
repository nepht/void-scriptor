import 'dart:io';

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
    this.title = 'Specification',
    this.description,
  });

  final String category;
  final String material;
  final String fabric;
  final String fit;
  final String style;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null && description!.isNotEmpty) ...[
          Text(
            description!,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
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
  const WardrobeComponentsCard({
    super.key,
    required this.components,
    this.title = 'Components',
    this.emptyText = 'Belum ada komponen tersimpan.',
  });

  final List<WardrobeComponentInfo> components;
  final String title;
  final String emptyText;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: title,
    child: components.isEmpty
        ? _EmptyNote(text: emptyText)
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
  const WardrobeMaterialCard({
    super.key,
    required this.components,
    this.title = 'Material / Fabric',
  });

  final List<WardrobeComponentInfo> components;
  final String title;

  @override
  Widget build(BuildContext context) {
    final values = <String>{
      for (final component in components)
        if (component.material.isNotEmpty) component.material,
      for (final component in components)
        if (component.fabric.isNotEmpty) component.fabric,
    };
    return _WardrobeCard(
      title: title,
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

class WardrobeBoardPanel extends StatelessWidget {
  const WardrobeBoardPanel({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _WardrobeCard(title: title, child: child);
}

class WardrobeReferenceGalleryCard extends StatelessWidget {
  const WardrobeReferenceGalleryCard({
    super.key,
    required this.title,
    required this.references,
    required this.emptyText,
  });

  final String title;
  final List<WardrobeReferenceInfo> references;
  final String emptyText;

  @override
  Widget build(BuildContext context) => _WardrobeCard(
    title: title,
    child: references.isEmpty
        ? _EmptyNote(text: emptyText)
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reference in references)
                _ReferenceTile(reference: reference),
            ],
          ),
  );
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final WardrobeReferenceInfo reference;

  @override
  Widget build(BuildContext context) {
    final file = reference.filePath.isEmpty ? null : File(reference.filePath);
    final fileExists = file?.existsSync() ?? false;
    return Container(
      width: 132,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.palette.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 116,
            height: 76,
            child: fileExists
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(file!, fit: BoxFit.cover),
                  )
                : Icon(Icons.image_outlined, color: context.palette.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            wardrobeValue(reference.referenceType),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (!fileExists)
            Text(
              reference.filePath.isEmpty
                  ? 'File belum ditautkan'
                  : 'File tidak ditemukan',
              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
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
