import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/features/release/application/release_controller.dart';

/// Step 49.78 — Public Project Page.
///
/// QOWNER: RISE OF THE VOID — Trailer, About, Characters, Gallery,
/// Episodes, Game Updates, Credits + Follow/Watch/Play.
class PublicProjectPageScreen extends ConsumerWidget {
  const PublicProjectPageScreen({super.key});

  static const _tabs = <String>[
    'About',
    'Characters',
    'Gallery',
    'Episodes',
    'Game Updates',
    'Credits',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(releaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QOWNER: RISE OF THE VOID'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: _tabs.length,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(VoidSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('Follow'),
                      ),
                    ),
                    const SizedBox(width: VoidSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Watch'),
                      ),
                    ),
                    const SizedBox(width: VoidSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Play'),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabs: [for (final t in _tabs) Tab(text: t)],
              ),
              Expanded(
                child: TabBarView(
                  children: [for (final t in _tabs) _Placeholder(label: t)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label content',
        style: VoidTypography.body.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}
