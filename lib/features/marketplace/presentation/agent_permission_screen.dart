import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.12 — Agent Permission Screen.
///
/// Daftar permission agent (File Access, Network, AI Provider).
/// User harus dapat menolak optional permission.
class AgentPermissionScreen extends StatelessWidget {
  const AgentPermissionScreen({
    super.key,
    this.onAllowAll,
    this.onDenyOptional,
  });

  final VoidCallback? onAllowAll;
  final VoidCallback? onDenyOptional;

  static const _permissions = <(String, String, bool)>[
    ('File Access', 'Read project files', true),
    ('Network', 'Access internet', true),
    ('AI Provider', 'Use AI provider credentials', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Permissions'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This agent requests the following permissions:',
                style: VoidTypography.body.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (name, desc, required) in _permissions)
                _PermissionTile(name: name, desc: desc, isRequired: required),
              const SizedBox(height: VoidSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onAllowAll,
                      child: const Text('Allow All'),
                    ),
                  ),
                  const SizedBox(width: VoidSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDenyOptional,
                      child: const Text('Deny Optional'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatefulWidget {
  const _PermissionTile({
    required this.name,
    required this.desc,
    required this.isRequired,
  });

  final String name;
  final String desc;
  final bool isRequired;

  @override
  State<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<_PermissionTile> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: Icon(
          widget.isRequired ? Icons.lock_outline : Icons.lock_open_outlined,
          color: context.palette.primary,
        ),
        title: Text(widget.name),
        subtitle: Text(widget.desc),
        trailing: widget.isRequired
            ? const Text('Required')
            : Switch(
                value: _checked,
                onChanged: (v) => setState(() => _checked = v),
              ),
      ),
    );
  }
}
