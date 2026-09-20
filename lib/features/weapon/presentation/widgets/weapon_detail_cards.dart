import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/weapon_workspace_data.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Honest fallback for missing persisted values (vs-hunt-20260914-wardrobe-
/// weapon WBUG-6: absent data must never be papered over with sample text —
/// mirrors the ENV-BUG-002 dash convention from run271).
String weaponValue(String? value) =>
    (value == null || value.isEmpty) ? _dash : value;

String weaponNumber(double? value, String unit) {
  if (value == null) return _dash;
  final text = value % 1 == 0 ? value.toInt().toString() : value.toString();
  return '$text $unit';
}

const String _dash = '—';

class WeaponTechnicalViewCard extends StatelessWidget {
  const WeaponTechnicalViewCard({super.key});

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Technical View',
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
            Icons.auto_fix_high_outlined,
            size: 58,
            color: context.palette.textMuted,
          ),
        ),
      ),
    ),
  );
}

class WeaponSpecificationCard extends StatelessWidget {
  const WeaponSpecificationCard({
    super.key,
    required this.model,
    this.title = 'Specification',
    this.description,
    this.showTechnicalFields = true,
  });
  final WeaponSpecificationData model;
  final String title;
  final String? description;
  final bool showTechnicalFields;

  @override
  Widget build(BuildContext context) => _WeaponCard(
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
        if (showTechnicalFields) ...[
          _PropertyRow(label: 'Type', value: model.type),
          _PropertyRow(label: 'Length', value: model.length),
          _PropertyRow(label: 'Weight', value: model.weight),
          _PropertyRow(label: 'Material', value: model.material),
          _PropertyRow(label: 'Energy', value: model.energy),
        ],
      ],
    ),
  );
}

class WeaponSpecificationData {
  const WeaponSpecificationData({
    required this.type,
    required this.length,
    required this.weight,
    required this.material,
    required this.energy,
  });
  final String type;
  final String length;
  final String weight;
  final String material;
  final String energy;
}

class WeaponColorPaletteCard extends StatelessWidget {
  const WeaponColorPaletteCard({super.key, required this.colors});

  final List<WeaponColorInfo> colors;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Color Palette',
    child: colors.isEmpty
        ? const _EmptyNote(text: 'Belum ada warna tersimpan.')
        : Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final color in colors) _WeaponColorSwatch(color: color),
            ],
          ),
  );
}

class _WeaponColorSwatch extends StatelessWidget {
  const _WeaponColorSwatch({required this.color});

  final WeaponColorInfo color;

  @override
  Widget build(BuildContext context) {
    final digits = color.hexValue.replaceFirst('#', '');
    final parsed = int.tryParse(digits, radix: 16);
    final swatch = parsed == null
        ? const Color(0xFF808080)
        : digits.length <= 6
        ? Color(0xFF000000 | parsed)
        : Color(parsed);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: swatch,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.palette.borderSoft),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weaponValue(color.name)),
            Text(
              color.usage.isEmpty
                  ? color.hexValue
                  : '${color.hexValue} · ${color.usage}',
              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class WeaponComponentsCard extends StatelessWidget {
  const WeaponComponentsCard({
    super.key,
    required this.components,
    this.title = 'Components',
  });

  final List<WeaponComponentInfo> components;
  final String title;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: title,
    child: components.isEmpty
        ? const _EmptyNote(text: 'Belum ada komponen tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final component in components)
                _Chip(weaponValue(component.name)),
            ],
          ),
  );
}

/// Overall length/weight come from the scalar model; every sub-part row is a
/// persisted weaponMeasurements record (WBUG-6: the old card invented fixed
/// 'Blade: 260 mm' / 'Handle: 145 mm' rows).
class WeaponDimensionsCard extends StatelessWidget {
  const WeaponDimensionsCard({
    super.key,
    required this.length,
    required this.weight,
    required this.measurements,
    this.title = 'Dimensions',
  });
  final String length;
  final String weight;
  final List<WeaponMeasurementInfo> measurements;
  final String title;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: title,
    child: Column(
      children: [
        _PropertyRow(label: 'Overall', value: length),
        _PropertyRow(label: 'Weight', value: weight),
        for (final measurement in measurements)
          _PropertyRow(
            label: weaponValue(measurement.label),
            value: weaponNumber(measurement.value, measurement.unit),
          ),
        if (measurements.isEmpty)
          const _EmptyNote(text: 'Belum ada pengukuran tersimpan.'),
      ],
    ),
  );
}

class WeaponEnergyCard extends StatelessWidget {
  const WeaponEnergyCard({
    super.key,
    required this.energy,
    required this.core,
    this.profile,
    this.title = 'Energy / Core',
  });
  final String energy;
  final String core;
  final WeaponEnergyInfo? profile;
  final String title;

  @override
  Widget build(BuildContext context) {
    final info = profile;
    return _WeaponCard(
      title: title,
      child: Column(
        children: [
          _PropertyRow(label: 'Energy Type', value: energy),
          _PropertyRow(label: 'Core Type', value: core),
          _PropertyRow(
            label: 'Emission',
            value: weaponValue(info?.emissionColor),
          ),
          _PropertyRow(
            label: 'Activation',
            value: weaponValue(info?.activation),
          ),
        ],
      ),
    );
  }
}

class WeaponVariantsCard extends StatelessWidget {
  const WeaponVariantsCard({super.key, required this.variants});

  final List<WeaponVariantInfo> variants;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Variants',
    child: variants.isEmpty
        ? const _EmptyNote(text: 'Belum ada varian tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final variant in variants) _Chip(weaponValue(variant.name)),
            ],
          ),
  );
}

class WeaponReferencesCard extends StatelessWidget {
  const WeaponReferencesCard({super.key, required this.references});

  final List<WeaponReferenceInfo> references;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'References',
    child: references.isEmpty
        ? const _EmptyNote(text: 'Belum ada referensi tersimpan.')
        : Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final reference in references)
                _Chip(weaponValue(reference.referenceType)),
            ],
          ),
  );
}

class WeaponBoardPanel extends StatelessWidget {
  const WeaponBoardPanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => _WeaponCard(title: title, child: child);
}

class WeaponReferenceGalleryCard extends StatelessWidget {
  const WeaponReferenceGalleryCard({
    super.key,
    required this.title,
    required this.references,
    required this.emptyText,
  });

  final String title;
  final List<WeaponReferenceInfo> references;
  final String emptyText;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: title,
    child: references.isEmpty
        ? _EmptyNote(text: emptyText)
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reference in references)
                _WeaponReferenceTile(reference: reference),
            ],
          ),
  );
}

class _WeaponReferenceTile extends StatelessWidget {
  const _WeaponReferenceTile({required this.reference});

  final WeaponReferenceInfo reference;

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
            weaponValue(reference.referenceType),
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

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({required this.title, required this.child});
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
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: context.palette.surfaceElevated,
    labelStyle: TextStyle(color: context.palette.textPrimary),
  );
}
