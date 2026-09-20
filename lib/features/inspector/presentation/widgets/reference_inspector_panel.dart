import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class InspectorProperty {
  const InspectorProperty(this.label, this.value);
  final String label;
  final String value;
}

class InspectorAssetCount {
  const InspectorAssetCount(this.label, this.count, this.icon);
  final String label;
  final String count;
  final IconData icon;
}

class InspectorLockState {
  const InspectorLockState(this.label, this.enabled);
  final String label;
  final bool enabled;
}

/// The narrow, read-only inspector composition shared by Character, Wardrobe,
/// Item, and Ability inspectors. Keep the section order stable: it mirrors the
/// product reference and makes the panel scannable at 280px.
class ReferenceInspectorPanel extends StatelessWidget {
  const ReferenceInspectorPanel({
    super.key,
    required this.properties,
    this.tags = const [],
    this.quickNotes = '',
    this.aiPrompt = '',
    this.locks = const [],
    this.linkedAssets = const [],
    this.versionHistory = const [],
    this.actionLabels = const [],
    this.relationSection,
  });

  final List<InspectorProperty> properties;
  final List<String> tags;
  final String quickNotes;
  final String aiPrompt;
  final List<InspectorLockState> locks;
  final List<InspectorAssetCount> linkedAssets;
  final List<String> versionHistory;
  final List<String> actionLabels;
  final Widget? relationSection;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
    children: [
      const _SectionTitle('PROPERTIES'),
      for (final property in properties)
        _PropertyRow(label: property.label, value: property.value),
      _Divider(),
      const _SectionTitle('TAGS'),
      Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final tag in tags) _Tag(tag),
          if (tags.isEmpty) const _MutedText('No tags'),
        ],
      ),
      _Divider(),
      const _SectionTitle('QUICK NOTES'),
      _NotesText(quickNotes),
      _Divider(),
      const _SectionTitle('AI PROMPT (MAIN)'),
      _PromptBox(aiPrompt),
      if (locks.isNotEmpty) ...[
        _Divider(),
        const _SectionTitle('CONTINUITY LOCKS'),
        for (final lock in locks)
          _LockRow(label: lock.label, enabled: lock.enabled),
      ],
      _Divider(),
      const _SectionTitle('LINKED ASSETS'),
      _AssetGrid(items: linkedAssets),
      if (versionHistory.isNotEmpty) ...[
        _Divider(),
        const _SectionTitle('VERSION HISTORY'),
        for (final version in versionHistory) _VersionRow(version),
      ],
      _Divider(),
      if (relationSection != null) ...[relationSection!, _Divider()],
      const _SectionTitle('ACTIONS'),
      for (final action in actionLabels)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            action,
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.05,
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: TextStyle(color: context.palette.textMuted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.primary.withValues(alpha: .65)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(color: context.palette.primaryBright, fontSize: 10),
    ),
  );
}

class _NotesText extends StatelessWidget {
  const _NotesText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text.isEmpty ? '—' : text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 11,
        height: 1.35,
      ),
    ),
  );
}

class _PromptBox extends StatelessWidget {
  const _PromptBox(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: context.palette.backgroundSecondary,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.palette.borderSoft),
    ),
    child: Text(
      text.isEmpty ? '—' : text,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 10,
        height: 1.35,
      ),
    ),
  );
}

class _AssetGrid extends StatelessWidget {
  const _AssetGrid({required this.items});
  final List<InspectorAssetCount> items;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      childAspectRatio: .92,
    ),
    itemBuilder: (context, index) {
      final item = items[index];
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: context.palette.backgroundSecondary,
          border: Border.all(color: context.palette.borderSoft),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 15, color: context.palette.textMuted),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.palette.textMuted, fontSize: 9),
            ),
            const SizedBox(height: 2),
            Text(
              item.count,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _LockRow extends StatelessWidget {
  const _LockRow({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          enabled ? Icons.lock_outline : Icons.lock_open_outlined,
          size: 14,
          color: enabled
              ? context.palette.primaryBright
              : context.palette.textMuted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          enabled ? 'Locked' : 'Open',
          style: TextStyle(color: context.palette.textMuted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _VersionRow extends StatelessWidget {
  const _VersionRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.history, size: 14, color: context.palette.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: context.palette.borderSoft),
  );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: context.palette.textMuted, fontSize: 10),
  );
}
