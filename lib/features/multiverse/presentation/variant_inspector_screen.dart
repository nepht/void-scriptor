import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Variant inspector: membandingkan varian karakter antar universe —
/// panel Base vs panel Variant (Sprint 45 — Character Portability).
class VariantInspectorScreen extends StatefulWidget {
  const VariantInspectorScreen({super.key});

  @override
  State<VariantInspectorScreen> createState() => _VariantInspectorScreenState();
}

class _VariantInspectorScreenState extends State<VariantInspectorScreen> {
  static const List<String> _characters = [
    'Arin Vale',
    'Mira Solenne',
    'Kael Duskborn',
  ];

  static const List<String> _variants = [
    'Canon Prime · Arin Vale',
    'What If: Echoes · Arin Vale',
    'Parallel Nexus · Arin Vale',
  ];

  String _selectedCharacter = _characters.first;
  String _selectedVariant = _variants.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(
          'Variant Inspector',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final selector = _VariantSelector(
                characters: _characters,
                variants: _variants,
                selectedCharacter: _selectedCharacter,
                selectedVariant: _selectedVariant,
                onCharacterChanged: (value) =>
                    setState(() => _selectedCharacter = value),
                onVariantChanged: (value) =>
                    setState(() => _selectedVariant = value),
              );
              const base = _VariantPanel(
                title: 'Base',
                subtitle: 'Canon Prime',
                locked: true,
              );
              final variant = _VariantPanel(
                title: 'Variant',
                subtitle: _selectedVariant,
                locked: false,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 280, child: selector),
                        const Spacer(),
                        const Expanded(child: base),
                        const SizedBox(width: VoidSpacing.xl),
                        Expanded(child: variant),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selector,
                        const SizedBox(height: VoidSpacing.xl),
                        base,
                        const SizedBox(height: VoidSpacing.xl),
                        variant,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.characters,
    required this.variants,
    required this.selectedCharacter,
    required this.selectedVariant,
    required this.onCharacterChanged,
    required this.onVariantChanged,
  });

  final List<String> characters;
  final List<String> variants;
  final String selectedCharacter;
  final String selectedVariant;
  final ValueChanged<String> onCharacterChanged;
  final ValueChanged<String> onVariantChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 18,
                color: context.palette.primary,
              ),
              const SizedBox(width: VoidSpacing.xs),
              Text(
                'Inspector',
                style: VoidTypography.label.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoidSpacing.md),
          Text(
            'Karakter',
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: selectedCharacter,
            isExpanded: true,
            dropdownColor: context.palette.surfaceElevated,
            style: VoidTypography.body.copyWith(
              color: context.palette.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.palette.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VoidSpacing.sm,
                vertical: VoidSpacing.xs,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.palette.primary),
              ),
            ),
            items: [
              for (final name in characters)
                DropdownMenuItem(
                  value: name,
                  child: Text(
                    name,
                    style: VoidTypography.body.copyWith(
                      color: context.palette.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onCharacterChanged(value);
            },
          ),
          const SizedBox(height: VoidSpacing.md),
          Text(
            'Universe Variant',
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: selectedVariant,
            isExpanded: true,
            dropdownColor: context.palette.surfaceElevated,
            style: VoidTypography.body.copyWith(
              color: context.palette.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.palette.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VoidSpacing.sm,
                vertical: VoidSpacing.xs,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.palette.primary),
              ),
            ),
            items: [
              for (final name in variants)
                DropdownMenuItem(
                  value: name,
                  child: Text(
                    name,
                    style: VoidTypography.body.copyWith(
                      color: context.palette.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onVariantChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _VariantPanel extends StatelessWidget {
  const _VariantPanel({
    required this.title,
    required this.subtitle,
    required this.locked,
  });

  final String title;
  final String subtitle;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked ? context.palette.primary : context.palette.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                locked ? Icons.lock_outline : Icons.lock_open,
                size: 18,
                color: context.palette.primary,
              ),
              const SizedBox(width: VoidSpacing.sm),
              Text(
                title,
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoidSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Canon',
                    style: VoidTypography.caption.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VoidSpacing.xs),
          Text(
            subtitle,
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.lg),
          _TraitRow(label: 'Identitas', value: locked ? 'Terkunci' : 'Bebas'),
          const SizedBox(height: VoidSpacing.sm),
          _TraitRow(
            label: 'Asal Universe',
            value: locked ? 'Canon Prime' : subtitle,
          ),
          const SizedBox(height: VoidSpacing.sm),
          const _TraitRow(label: 'Relasi', value: '12 koneksi'),
          const SizedBox(height: VoidSpacing.sm),
          _TraitRow(label: 'Status', value: locked ? 'Stabil' : 'Berubah'),
        ],
      ),
    );
  }
}

class _TraitRow extends StatelessWidget {
  const _TraitRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: VoidTypography.body.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
