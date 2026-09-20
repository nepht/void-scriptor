// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import '../../../design_system/widgets/void_button.dart';
import '../../assets/application/asset_thumbnail_importer.dart';
import '../domain/character_model.dart';
import '../domain/character_identity_profile.dart';
import 'character_workspace_controller.dart';
import 'character_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import 'widgets/accessories_card.dart';
import 'widgets/character_empty_state.dart';
import 'widgets/character_deletion_review_dialog.dart';
import 'widgets/character_header.dart';
import 'widgets/character_design_sheet_layout.dart';
import 'widgets/character_identity_card.dart';
import 'widgets/character_portrait_card.dart';
import 'widgets/character_trait_extraction_sheet.dart';
import 'widgets/character_scope_status_card.dart';
import 'widgets/character_private_notes_card.dart';
import 'widgets/narrative_assignment_card.dart';
import 'widgets/references_card.dart';
import 'widgets/color_palette_card.dart';
import 'widgets/identity_preservation_card.dart';
import 'widgets/silhouette_card.dart';
import 'widgets/turnaround_card.dart';
import '../../character_mode/presentation/widgets/character_mode_section.dart';
import '../../character_mode/domain/loadout_slot.dart';
import '../../inspector/presentation/widgets/relation_section.dart';
import '../../inspector/presentation/widgets/support_relationship_section.dart';
import '../../workspace/application/workspace_section_controller.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterWorkspaceScreen extends ConsumerStatefulWidget {
  const CharacterWorkspaceScreen({
    super.key,
    required this.characterId,
    this.activeSection,
    this.sectionBuilders = const {},
  });
  final String characterId;
  final String? activeSection;

  /// Extension seam for project-specific or future canonical sections.
  /// Keys use canonical section names after legacy alias normalization.
  final Map<String, WidgetBuilder> sectionBuilders;
  @override
  ConsumerState<CharacterWorkspaceScreen> createState() =>
      _CharacterWorkspaceScreenState();
}

class _CharacterWorkspaceScreenState
    extends ConsumerState<CharacterWorkspaceScreen> {
  String _characterSheetSection = 'Design Sheet';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterWorkspaceProvider(widget.characterId));
    final identity = ref.watch(characterIdentityProvider(widget.characterId));
    final portrait = ref.watch(characterPortraitProvider(widget.characterId));
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
                portrait.valueOrNull,
              ),
      ),
    );
  }

  Widget _buildWorkspace(
    CharacterModel character,
    CharacterIdentityProfile identity,
    String? portraitPath,
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
            final desktop = constraints.maxWidth >= 820;
            final body = SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: double.infinity),
                child: _content(character, identity, desktop, portraitPath),
              ),
            );
            return body;
          },
        ),
      ),
    ],
  );
  VoidButton _traitTrigger(CharacterModel character) => VoidButton(
    key: const ValueKey('trait-extract-trigger'),
    icon: Icons.auto_awesome,
    label: 'Ekstraksi ciri dari naskah',
    onPressed: () => CharacterTraitExtractionSheet.show(
      context,
      characterId: character.assetId,
      characterName: character.displayName,
    ),
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

  /// Portrait import: pick a local image and copy it into the project
  /// package via [AssetThumbnailImporter] (same durable path the asset
  /// browser uses), then refresh the bound portrait. External files are
  /// never referenced in place, so the portrait survives moving folders.
  Future<void> _importPortrait(String characterId) async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active project session.')),
      );
      return;
    }
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final importer = AssetThumbnailImporter(
      database: session.database,
      assetsDirectory: session.package.assetsDirectory,
    );
    try {
      await importer.importFromFile(
        assetId: characterId,
        sourcePath: file.path,
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Portrait import failed: $error')));
      return;
    }
    ref.invalidate(characterPortraitProvider(characterId));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Portrait updated.')));
  }

  Widget _content(
    CharacterModel character,
    CharacterIdentityProfile identity,
    bool desktop,
    String? portraitPath,
  ) {
    final identityCard = CharacterIdentityCard(
      compact: widget.activeSection == 'Appearance',
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
              SizedBox(
                width: 280,
                child: CharacterPortraitCard(
                  imagePath: portraitPath,
                  onAddPortrait: () => _importPortrait(character.assetId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: identityCard),
            ],
          )
        : Column(
            children: [
              CharacterPortraitCard(
                imagePath: portraitPath,
                onAddPortrait: () => _importPortrait(character.assetId),
              ),
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
        const SizedBox(height: 16),
        RelationSection(assetId: character.assetId),
        const SizedBox(height: 16),
        SupportRelationshipSection(assetId: character.assetId),
        const SizedBox(height: 16),
        CharacterModeSection(
          characterId: character.assetId,
          title: 'Companions',
          showModeDetails: false,
          slots: const [LoadoutSlot.companion],
        ),
      ],
    );
    final section = widget.activeSection == null
        ? null
        : canonicalWorkspaceSection(
            WorkspaceKind.character,
            widget.activeSection!,
          );
    final extensionBuilder = section == null
        ? null
        : widget.sectionBuilders[section];
    if (extensionBuilder != null) return extensionBuilder(context);

    if (section == 'Overview') {
      return CharacterDesignSheetLayout(
        summary: identityCard,
        portrait: CharacterPortraitCard(
          imagePath: portraitPath,
          onAddPortrait: () => _importPortrait(character.assetId),
        ),
        turnaround: const TurnaroundCard(),
        details: visual,
      );
    }
    if (section == 'Character Sheet') {
      final portrait = CharacterPortraitCard(
        imagePath: portraitPath,
        onAddPortrait: () => _importPortrait(character.assetId),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CharacterSheetNavigation(
            activeSection: _characterSheetSection,
            onSelected: (value) => setState(() {
              _characterSheetSection = value;
            }),
          ),
          const SizedBox(height: 8),
          switch (_characterSheetSection) {
            'Turnaround' => const TurnaroundCard(),
            'Silhouette' => const SilhouetteCard(),
            'Portrait' => portrait,
            'Details' => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                visual,
                const SizedBox(height: 16),
                ReferencesCard(characterId: character.assetId),
              ],
            ),
            'Expression Reference' ||
            'Pose' => _UnavailableSheetSection(title: _characterSheetSection),
            _ => CharacterDesignSheetLayout(
              summary: identityCard,
              portrait: portrait,
              turnaround: const TurnaroundCard(),
              details: visual,
            ),
          },
        ],
      );
    }
    if (section == 'Relations' || section == 'Relationships') {
      return relationships;
    }
    if (section == 'Weapons') {
      return CharacterModeSection(
        characterId: character.assetId,
        title: 'Weapon',
        slots: const [LoadoutSlot.primaryWeapon, LoadoutSlot.secondaryWeapon],
      );
    }
    if (section == 'Abilities') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Abilities are managed from the character profile.'),
            ),
          ),
        ],
      );
    }
    if (section == 'Wardrobe' || section == 'Appearance') {
      return Column(
        children: [
          CharacterDesignSheetLayout(
            summary: identityCard,
            portrait: CharacterPortraitCard(
              imagePath: portraitPath,
              onAddPortrait: () => _importPortrait(character.assetId),
            ),
            turnaround: const TurnaroundCard(),
            details: visual,
          ),
          const SizedBox(height: 16),
          identityPreservation,
          const SizedBox(height: 16),
          CharacterModeSection(
            characterId: character.assetId,
            title: 'Appearance & Gear',
            slots: const [
              LoadoutSlot.wardrobe,
              LoadoutSlot.armor,
              LoadoutSlot.primaryWeapon,
              LoadoutSlot.secondaryWeapon,
              LoadoutSlot.accessory,
              LoadoutSlot.hairVariant,
              LoadoutSlot.carriedItem,
              LoadoutSlot.vehicle,
            ],
          ),
        ],
      );
    }
    if (section == 'Story') {
      return NarrativeAssignmentCard(
        key: ValueKey<String>('narrative-${character.assetId}'),
        characterId: character.assetId,
      );
    }
    if (section == 'AI Assets') {
      return Align(
        alignment: Alignment.topLeft,
        child: _traitTrigger(character),
      );
    }
    if (section == 'Notes') return notes;
    if (const ['Expressions Library', 'Timeline'].contains(section)) {
      return _UnavailableSheetSection(title: section ?? 'Character section');
    }
    return CharacterDesignSheetLayout(
      summary: identityCard,
      portrait: CharacterPortraitCard(
        imagePath: portraitPath,
        onAddPortrait: () => _importPortrait(character.assetId),
      ),
      turnaround: const TurnaroundCard(),
      details: visual,
    );
  }

  Future<void> _updateIdentity(
    CharacterIdentityProfile current,
    CharacterIdentityProfile Function(CharacterIdentityProfile) update,
  ) => CharacterIdentityActions(ref).update(update(current));
}

class _CharacterSheetNavigation extends StatelessWidget {
  const _CharacterSheetNavigation({
    required this.activeSection,
    required this.onSelected,
  });

  static const sections = [
    'Design Sheet',
    'Turnaround',
    'Silhouette',
    'Portrait',
    'Expression Reference',
    'Pose',
    'Details',
  ];

  final String activeSection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.panel,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final section in sections)
            InkWell(
              key: ValueKey('character-sheet-section-$section'),
              onTap: () => onSelected(section),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: section == activeSection
                          ? context.palette.primaryBright
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  section,
                  style: TextStyle(
                    color: section == activeSection
                        ? context.palette.textPrimary
                        : context.palette.textSecondary,
                    fontSize: 12,
                    fontWeight: section == activeSection
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _UnavailableSheetSection extends StatelessWidget {
  const _UnavailableSheetSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '$title belum memiliki data khusus untuk karakter ini.',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
    ),
  );
}
