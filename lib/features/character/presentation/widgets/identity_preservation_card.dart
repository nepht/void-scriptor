import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class IdentityPreservationCard extends StatelessWidget {
  const IdentityPreservationCard({
    super.key,
    required this.faceLock,
    required this.hairLock,
    required this.bodyLock,
    required this.colorLock,
    required this.outfitLock,
    required this.onFaceChanged,
    required this.onHairChanged,
    required this.onBodyChanged,
    required this.onColorChanged,
    required this.onOutfitChanged,
  });
  final bool faceLock, hairLock, bodyLock, colorLock, outfitLock;
  final ValueChanged<bool> onFaceChanged,
      onHairChanged,
      onBodyChanged,
      onColorChanged,
      onOutfitChanged;
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identity Preservation',
          style: VoidTypography.headingMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Control which character traits must remain consistent.',
          style: VoidTypography.caption,
        ),
        const SizedBox(height: 14),
        _LockRow('Face Lock', faceLock, onFaceChanged),
        _LockRow('Hair Geometry Lock', hairLock, onHairChanged),
        _LockRow('Body Topology Lock', bodyLock, onBodyChanged),
        _LockRow('Color Lock', colorLock, onColorChanged),
        _LockRow('Outfit Geometry Lock', outfitLock, onOutfitChanged),
      ],
    ),
  );
}

class _LockRow extends StatelessWidget {
  const _LockRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: VoidTypography.body)),
      Text(
        value ? 'ON' : 'OFF',
        style: TextStyle(
          color: value ? context.palette.success : context.palette.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}
