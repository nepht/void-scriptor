import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Wizard pembuatan universe: 3 langkah (Nama → Tipe → Konfirmasi)
/// dengan tombol Next dan Cancel (Sprint 45 — Universe Registry).
class CreateUniverseWizardScreen extends StatefulWidget {
  const CreateUniverseWizardScreen({super.key});

  @override
  State<CreateUniverseWizardScreen> createState() =>
      _CreateUniverseWizardScreenState();
}

class _CreateUniverseWizardScreenState
    extends State<CreateUniverseWizardScreen> {
  static const List<String> _steps = ['Name', 'Type', 'Confirm'];

  static const List<String> _universeTypes = [
    'Canon',
    'Alternate',
    'What If',
    'Spin-Off',
    'AU',
    'Crossover',
    'Parallel',
    'Dream',
  ];

  int _stepIndex = 0;
  String _name = '';
  String _selectedType = 'Alternate';

  void _next() {
    setState(() {
      if (_stepIndex < _steps.length - 1) {
        _stepIndex++;
      }
    });
  }

  void _cancel() {
    setState(() {
      _stepIndex = 0;
      _name = '';
      _selectedType = 'Alternate';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(
          'Create Universe',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.surface,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.palette.textSecondary),
          onPressed: _cancel,
          tooltip: 'Cancel',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final stepper = _StepIndicator(
                steps: _steps,
                currentIndex: _stepIndex,
              );
              final form = _buildForm();
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 280, child: stepper),
                        const SizedBox(width: VoidSpacing.xl),
                        Expanded(child: form),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stepper,
                        const SizedBox(height: VoidSpacing.xl),
                        form,
                      ],
                    );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancel,
                child: Text(
                  'Cancel',
                  style: VoidTypography.label.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: VoidSpacing.sm),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.textPrimary,
                ),
                child: Text(
                  _stepIndex == _steps.length - 1 ? 'Create' : 'Next',
                  style: VoidTypography.label.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (_stepIndex) {
      case 0:
        return _NameStep(
          name: _name,
          onChanged: (value) => setState(() => _name = value),
        );
      case 1:
        return _TypeStep(
          selectedType: _selectedType,
          onSelect: (value) => setState(() => _selectedType = value),
        );
      default:
        return _ConfirmStep(
          name: _name.isEmpty ? 'Unnamed Universe' : _name,
          type: _selectedType,
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.steps, required this.currentIndex});

  final List<String> steps;
  final int currentIndex;

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
          Text(
            'Steps',
            style: VoidTypography.label.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.sm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VoidSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    i < currentIndex
                        ? Icons.check_circle
                        : i == currentIndex
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: i <= currentIndex
                        ? context.palette.primary
                        : context.palette.textMuted,
                  ),
                  const SizedBox(width: VoidSpacing.sm),
                  Text(
                    steps[i],
                    style: VoidTypography.body.copyWith(
                      color: i == currentIndex
                          ? context.palette.textPrimary
                          : context.palette.textSecondary,
                      fontWeight: i == currentIndex
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.name, required this.onChanged});

  final String name;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.edit_outlined,
      title: 'Nama Universe',
      description:
          'Beri nama unik untuk universe baru. Nama akan digunakan '
          'sebagai identitas di seluruh proyek.',
      child: TextField(
        controller: TextEditingController(text: name)
          ..selection = TextSelection.collapsed(offset: name.length),
        onChanged: onChanged,
        style: VoidTypography.body.copyWith(color: context.palette.textPrimary),
        decoration: InputDecoration(
          labelText: 'Nama Universe',
          labelStyle: VoidTypography.label.copyWith(
            color: context.palette.textSecondary,
          ),
          hintText: 'cth: What If: Echoes',
          hintStyle: VoidTypography.body.copyWith(
            color: context.palette.textMuted,
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
      ),
    );
  }
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.selectedType, required this.onSelect});

  final String selectedType;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.category_outlined,
      title: 'Tipe Universe',
      description: 'Pilih tipe yang menentukan aturan isolasi dan identitas.',
      child: Wrap(
        spacing: VoidSpacing.sm,
        runSpacing: VoidSpacing.sm,
        children: [
          for (final type in _CreateUniverseWizardScreenState._universeTypes)
            ChoiceChip(
              label: Text(
                type,
                style: VoidTypography.label.copyWith(
                  color: type == selectedType
                      ? context.palette.textPrimary
                      : context.palette.textSecondary,
                ),
              ),
              selected: type == selectedType,
              selectedColor: context.palette.primary.withValues(alpha: 0.18),
              backgroundColor: context.palette.surfaceElevated,
              side: BorderSide(
                color: type == selectedType
                    ? context.palette.primary
                    : context.palette.border,
              ),
              onSelected: (_) => onSelect(type),
            ),
        ],
      ),
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.name, required this.type});

  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.check_circle_outline,
      title: 'Konfirmasi',
      description: 'Tinjau detail sebelum universe dibuat.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Nama', value: name),
          const SizedBox(height: VoidSpacing.sm),
          _SummaryRow(label: 'Tipe', value: type),
          const SizedBox(height: VoidSpacing.sm),
          const _SummaryRow(label: 'Isolasi Canon', value: 'Aktif'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.lg),
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
              Icon(icon, size: 18, color: context.palette.primary),
              const SizedBox(width: VoidSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VoidSpacing.xs),
          Text(
            description,
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.lg),
          child,
        ],
      ),
    );
  }
}
