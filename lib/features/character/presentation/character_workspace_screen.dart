// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/character_model.dart';
import '../domain/character_identity_profile.dart';
import 'character_workspace_controller.dart';
import 'character_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import 'widgets/accessories_card.dart';
import 'widgets/character_empty_state.dart';
import 'widgets/character_deletion_review_dialog.dart';
import 'widgets/character_header.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_portrait_card.dart';
import 'widgets/character_scope_status_card.dart';
import 'widgets/character_private_notes_card.dart';
import 'widgets/color_palette_card.dart';
import 'widgets/identity_preservation_card.dart';
import 'widgets/references_card.dart';
import 'widgets/silhouette_card.dart';
import 'widgets/turnaround_card.dart';
import '../../character_mode/presentation/widgets/character_mode_section.dart';
import '../../character_mode/domain/loadout_slot.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterWorkspaceScreen extends ConsumerStatefulWidget {
  const CharacterWorkspaceScreen({
    super.key,
    required this.characterId,
    this.activeSection,
  });
  final String characterId;
  final String? activeSection;
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
      color: context.palette.backgroundSecondary,
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
      CharacterHeader(
        name: character.displayName,
        alias: character.alias,
        onDelete: () => _confirmDelete(character),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1100;
            final body = SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: desktop ? 1180 : double.infinity,
                ),
                child: desktop
                    ? _content(character, identity, true)
                    : Column(
                        children: [
                          // Narrow layout: the mode section joins the scroll
                          // area so the fixed header column cannot overflow
                          // on phone-sized viewports.
                          CharacterModeSection(characterId: character.assetId),
                          const SizedBox(height: 16),
                          _content(character, identity, false),
                        ],
                      ),
              ),
            );
            final showIdentityTools =
                widget.activeSection == null ||
                widget.activeSection == 'Identity';
            return desktop && showIdentityTools
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: CharacterModeSection(
                          characterId: character.assetId,
                        ),
                      ),
                      Expanded(child: body),
                    ],
                  )
                : body;
          },
        ),
      ),
    ],
  );
  Future<void> _confirmDelete(CharacterModel character) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    final database = session?.database;
    if (database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active project session.')),
      );
      return;
    }
    final actions = CharacterActions(ref, character.projectId, database);
    final decision = await showCharacterDeletionReviewDialog(
      context: context,
      loadReview: () => actions.reviewDeletion(character.assetId),
    );
    if (!mounted || decision == null) return;
    await actions.delete(character.assetId, decision: decision);
  }

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
      voice: character.voice,
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
    final identityPreservation = IdentityPreservationCard(
      faceLock: identity.faceLock,
      hairLock: identity.hairLock,
      bodyLock: identity.bodyLock,
      colorLock: identity.colorLock,
      outfitLock: identity.outfitLock,
      onFaceChanged: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(faceLock: value),
      ),
      onHairChanged: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(hairLock: value),
      ),
      onBodyChanged: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(bodyLock: value),
      ),
      onColorChanged: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(colorLock: value),
      ),
      onOutfitChanged: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(outfitLock: value),
      ),
    );
    final notes = CharacterPrivateNotesCard(
      initialNotes: identity.notes,
      onSave: (value) => _updateIdentity(
        identity,
        (profile) => profile.copyWith(notes: value),
      ),
    );
    final relationships = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Character Relationships',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        CharacterScopeStatusCard(characterId: character.assetId),
      ],
    );
    final section = widget.activeSection;
    if (section == 'Profile') return Column(children: [top]);
    if (section == 'Identity') {
      return Column(
        children: [
          identityCard,
          const SizedBox(height: 16),
          identityPreservation,
        ],
      );
    }
    if (section == 'Relationships') return relationships;
    if (section == 'Appearance & Gear') {
      return Column(
        children: [
          const CharacterPortraitCard(),
          const SizedBox(height: 16),
          const TurnaroundCard(),
          const SizedBox(height: 16),
          visual,
          const SizedBox(height: 16),
          const ReferencesCard(),
          const SizedBox(height: 16),
          CharacterModeSection(
            characterId: character.assetId,
            title: 'Appearance & Gear',
            showModeDetails: false,
            slots: const [
              LoadoutSlot.wardrobe,
              LoadoutSlot.armor,
              LoadoutSlot.primaryWeapon,
              LoadoutSlot.secondaryWeapon,
              LoadoutSlot.accessory,
              LoadoutSlot.hairVariant,
            ],
          ),
        ],
      );
    }
    if (section == 'Companions & Carry') {
      return CharacterModeSection(
        characterId: character.assetId,
        title: 'Companions & Carried Items',
        showModeDetails: false,
        slots: const [LoadoutSlot.companion, LoadoutSlot.carriedItem],
      );
    }
    if (section == 'Notes') return notes;
    return Column(
      children: [
        top,
        const SizedBox(height: 16),
        const TurnaroundCard(),
        const SizedBox(height: 16),
        visual,
        const SizedBox(height: 16),
        identityPreservation,
        const SizedBox(height: 16),
        notes,
        const SizedBox(height: 16),
        const ReferencesCard(),
        const SizedBox(height: 16),
        relationships,
      ],
    );
  }

  Future<void> _updateIdentity(
    CharacterIdentityProfile current,
    CharacterIdentityProfile Function(CharacterIdentityProfile) update,
  ) => CharacterIdentityActions(ref).update(update(current));
}
