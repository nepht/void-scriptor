// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../domain/character_model.dart';
import '../domain/character_identity_profile.dart';
import 'character_workspace_controller.dart';
import 'widgets/accessories_card.dart';
import 'widgets/character_empty_state.dart';
import 'widgets/character_header.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_portrait_card.dart';
import 'widgets/color_palette_card.dart';
import 'widgets/identity_preservation_card.dart';
import 'widgets/references_card.dart';
import 'widgets/silhouette_card.dart';
import 'widgets/turnaround_card.dart';

class CharacterWorkspaceScreen extends ConsumerStatefulWidget {
  const CharacterWorkspaceScreen({super.key, required this.characterId});
  final String characterId;
  @override
  ConsumerState<CharacterWorkspaceScreen> createState() =>
      _CharacterWorkspaceScreenState();
}

class _CharacterWorkspaceScreenState
    extends ConsumerState<CharacterWorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterWorkspaceProvider(widget.characterId));
    final identity = ref.watch(characterIdentityProvider(widget.characterId));
    return Container(
      color: VoidColors.backgroundSecondary,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (character) => character == null
            ? const CharacterEmptyState()
            : _buildWorkspace(
                character,
                identity.valueOrNull ??
                    CharacterIdentityProfile(characterId: widget.characterId),
              ),
      ),
    );
  }

  Widget _buildWorkspace(
    CharacterModel character,
    CharacterIdentityProfile identity,
  ) => Column(
    children: [
      CharacterHeader(name: character.displayName, alias: character.alias),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1100;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: desktop ? 1180 : double.infinity,
                ),
                child: _content(character, identity, desktop),
              ),
            );
          },
        ),
      ),
    ],
  );
  Widget _content(
    CharacterModel character,
    CharacterIdentityProfile identity,
    bool desktop,
  ) {
    final identityCard = CharacterIdentityCard(
      name: character.displayName,
      alias: character.alias,
      age: character.age?.toString() ?? '—',
      height: character.heightCm == null ? '—' : '${character.heightCm} cm',
      hair: character.hair,
      eyes: character.eyes,
    );
    final top = desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 280, child: CharacterPortraitCard()),
              const SizedBox(width: 16),
              Expanded(child: identityCard),
            ],
          )
        : Column(
            children: [
              const CharacterPortraitCard(),
              const SizedBox(height: 16),
              identityCard,
            ],
          );
    final visual = desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(child: SilhouetteCard()),
              SizedBox(width: 16),
              Expanded(child: ColorPaletteCard()),
              SizedBox(width: 16),
              Expanded(child: AccessoriesCard()),
            ],
          )
        : const Column(
            children: [
              SilhouetteCard(),
              SizedBox(height: 16),
              ColorPaletteCard(),
              SizedBox(height: 16),
              AccessoriesCard(),
            ],
          );
    return Column(
      children: [
        top,
        const SizedBox(height: 16),
        const TurnaroundCard(),
        const SizedBox(height: 16),
        visual,
        const SizedBox(height: 16),
        IdentityPreservationCard(
          faceLock: identity.faceLock,
          hairLock: identity.hairLock,
          bodyLock: identity.bodyLock,
          colorLock: identity.colorLock,
          outfitLock: identity.outfitLock,
          onFaceChanged: (value) => _updateIdentity(
            identity,
            (profile) => CharacterIdentityProfile(
              characterId: profile.characterId,
              faceLock: value,
              hairLock: profile.hairLock,
              bodyLock: profile.bodyLock,
              colorLock: profile.colorLock,
              outfitLock: profile.outfitLock,
            ),
          ),
          onHairChanged: (value) => _updateIdentity(
            identity,
            (profile) => CharacterIdentityProfile(
              characterId: profile.characterId,
              faceLock: profile.faceLock,
              hairLock: value,
              bodyLock: profile.bodyLock,
              colorLock: profile.colorLock,
              outfitLock: profile.outfitLock,
            ),
          ),
          onBodyChanged: (value) => _updateIdentity(
            identity,
            (profile) => CharacterIdentityProfile(
              characterId: profile.characterId,
              faceLock: profile.faceLock,
              hairLock: profile.hairLock,
              bodyLock: value,
              colorLock: profile.colorLock,
              outfitLock: profile.outfitLock,
            ),
          ),
          onColorChanged: (value) => _updateIdentity(
            identity,
            (profile) => CharacterIdentityProfile(
              characterId: profile.characterId,
              faceLock: profile.faceLock,
              hairLock: profile.hairLock,
              bodyLock: profile.bodyLock,
              colorLock: value,
              outfitLock: profile.outfitLock,
            ),
          ),
          onOutfitChanged: (value) => _updateIdentity(
            identity,
            (profile) => CharacterIdentityProfile(
              characterId: profile.characterId,
              faceLock: profile.faceLock,
              hairLock: profile.hairLock,
              bodyLock: profile.bodyLock,
              colorLock: profile.colorLock,
              outfitLock: value,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const ReferencesCard(),
      ],
    );
  }

  Future<void> _updateIdentity(
    CharacterIdentityProfile current,
    CharacterIdentityProfile Function(CharacterIdentityProfile) update,
  ) => CharacterIdentityActions(ref).update(update(current));
}
