import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';

class WeaponTechnicalViewCard extends StatelessWidget {
  const WeaponTechnicalViewCard({super.key});

  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Technical View',
    child: AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: VoidColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: VoidColors.borderSoft),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_fix_high_outlined,
            size: 58,
            color: VoidColors.textMuted,
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
  const WeaponComponentsCard({super.key});
  @override
  Widget build(BuildContext context) => const _WeaponCard(
    title: 'Components',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Chip('Blade'),
        _Chip('Edge'),
        _Chip('Guard'),
        _Chip('Handle'),
        _Chip('Core'),
        _Chip('Energy Channel'),
      ],
    ),
  );
}

class WeaponDimensionsCard extends StatelessWidget {
  const WeaponDimensionsCard({
    super.key,
    required this.length,
    required this.weight,
  });
  final String length;
  final String weight;
  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Dimensions',
    child: Column(
      children: [
        _PropertyRow(label: 'Overall', value: length),
        _PropertyRow(label: 'Weight', value: weight),
        const _PropertyRow(label: 'Blade', value: '260 mm'),
        const _PropertyRow(label: 'Handle', value: '145 mm'),
      ],
    ),
  );
}

class WeaponEnergyCard extends StatelessWidget {
  const WeaponEnergyCard({super.key, required this.energy, required this.core});
  final String energy;
  final String core;
  @override
  Widget build(BuildContext context) => _WeaponCard(
    title: 'Energy / Core',
    child: Column(
      children: [
        _PropertyRow(label: 'Energy', value: energy),
        _PropertyRow(label: 'Core', value: core),
        const _PropertyRow(label: 'Emission', value: 'Violet'),
        const _PropertyRow(label: 'Activation', value: 'Grip Recognition'),
      ],
    ),
  );
}

class WeaponVariantsCard extends StatelessWidget {
  const WeaponVariantsCard({super.key});
  @override
  Widget build(BuildContext context) => const _WeaponCard(
    title: 'Variants',
    child: Wrap(
      spacing: 10,
      children: [
        _Chip('Normal'),
        _Chip('Combat'),
        _Chip('Overcharged'),
        _Chip('Prototype'),
      ],
    ),
  );
}

class WeaponReferencesCard extends StatelessWidget {
  const WeaponReferencesCard({super.key});
  @override
  Widget build(BuildContext context) => const _WeaponCard(
    title: 'References',
    child: Text(
      'Front, Side, Back, Top, Close-up, Blade, Handle, Core, Effects',
      style: TextStyle(color: VoidColors.textMuted),
    ),
  );
}

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: VoidColors.panelSecondary,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: VoidColors.textPrimary, fontSize: 16),
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
            style: const TextStyle(color: VoidColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: VoidColors.textPrimary),
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
    backgroundColor: VoidColors.surfaceElevated,
    labelStyle: const TextStyle(color: VoidColors.textPrimary),
  );
}
