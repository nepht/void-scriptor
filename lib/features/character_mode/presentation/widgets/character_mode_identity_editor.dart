import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/effective_identity_profile.dart';
import '../character_mode_controller.dart';
import '../../data/character_mode_identity_repository.dart';
import '../../../projects/presentation/project_persistence_providers.dart';

class CharacterModeIdentityEditor extends ConsumerWidget {
  const CharacterModeIdentityEditor({super.key, required this.modeId});

  final String modeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    return FutureBuilder<CharacterModeIdentityOverride?>(
      future: CharacterModeIdentityRepository(
        session.database,
      ).getOverride(modeId),
      builder: (context, snapshot) {
        final value =
            snapshot.data ?? CharacterModeIdentityOverride(modeId: modeId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IDENTITY OVERRIDES'),
                for (final item in [
                  ('Face Lock', value.faceLock),
                  ('Hair Lock', value.hairLock),
                  ('Body Lock', value.bodyLock),
                  ('Color Lock', value.colorLock),
                  ('Outfit Lock', value.outfitLock),
                  ('Weapon Lock', value.weaponLock),
                ])
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.$1),
                    subtitle: Text(
                      item.$2 == null
                          ? 'Inherit from Character'
                          : 'Mode override',
                    ),
                    value: item.$2 ?? false,
                    onChanged: (enabled) async {
                      final next = CharacterModeIdentityOverride(
                        modeId: modeId,
                        faceLock: item.$1 == 'Face Lock'
                            ? enabled
                            : value.faceLock,
                        hairLock: item.$1 == 'Hair Lock'
                            ? enabled
                            : value.hairLock,
                        bodyLock: item.$1 == 'Body Lock'
                            ? enabled
                            : value.bodyLock,
                        colorLock: item.$1 == 'Color Lock'
                            ? enabled
                            : value.colorLock,
                        outfitLock: item.$1 == 'Outfit Lock'
                            ? enabled
                            : value.outfitLock,
                        weaponLock: item.$1 == 'Weapon Lock'
                            ? enabled
                            : value.weaponLock,
                      );
                      await CharacterModeIdentityRepository(
                        session.database,
                      ).saveOverride(next);
                      ref.invalidate(characterModesProvider);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
