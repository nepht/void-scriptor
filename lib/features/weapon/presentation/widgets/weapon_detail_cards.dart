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
  const WeaponSpecificationCard({super.key, required this.model});
  final WeaponSpecificationData model;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Specification',
    child: Column(
      children: [
        _PropertyRow(label: 'Type', value: model.type),
        _PropertyRow(label: 'Length', value: model.length),
        _PropertyRow(label: 'Weight', value: model.weight),
        _PropertyRow(label: 'Material', value: model.material),
        _PropertyRow(label: 'Energy', value: model.energy),
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

class WeaponComponentsCard extends StatelessWidget {
  const WeaponComponentsCard({super.key, required this.components});

  final List<WeaponComponentInfo> components;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Components',
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
  });
  final String length;
  final String weight;
  final List<WeaponMeasurementInfo> measurements;

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Dimensions',
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
  });
  final String energy;
  final String core;
  final WeaponEnergyInfo? profile;

  @override
  Widget build(BuildContext context) {
    final info = profile;
    return _WeaponCard(
      title: 'Energy / Core',
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
