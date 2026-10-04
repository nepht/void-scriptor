import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../design_system/theme/void_palette.dart';
import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/widgets/void_button.dart';
import '../../../ai/presentation/ai_generation_queue_screen.dart'
    show aiGenerationRuntimeProvider;
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../application/character_model_fields.dart' show applyTraitToModel;
import '../../application/character_trait_extractor.dart';
import '../../application/character_trait_extraction_service.dart';
import '../../application/update_character_command.dart';
import '../../data/character_repository_impl.dart';

/// Consent-gated sheet that extracts character traits from a novel manuscript
/// via the configured AI provider and shows them as TICKED-BY-NOTHING
/// proposals. Text only leaves the app after the user taps "Analisis";
/// nothing is written unless the user selects proposals and taps "Terapkan".
class CharacterTraitExtractionSheet extends ConsumerStatefulWidget {
  const CharacterTraitExtractionSheet({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  final String characterId;
  final String characterName;

  static Future<void> show(
    BuildContext context, {
    required String characterId,
    required String characterName,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CharacterTraitExtractionSheet(
      characterId: characterId,
      characterName: characterName,
    ),
  );

  @override
  ConsumerState<CharacterTraitExtractionSheet> createState() =>
      _CharacterTraitExtractionSheetState();
}

enum _Phase { consent, loading, proposals, failed }

class _CharacterTraitExtractionSheetState
    extends ConsumerState<CharacterTraitExtractionSheet> {
  static const _providerIds = ['openai', 'gemini', 'ollama'];

  _Phase _phase = _Phase.consent;
  List<NovelOption> _novels = const [];
  bool _novelsLoading = false;
  String? _novelId;
  String _providerId = _providerIds.first;
  TraitProposalResult? _result;
  final Set<int> _selected = {};
  String? _error;

  Future<void> _loadNovels() async {
    final session = ref.read(projectSessionProvider).value;
    if (session == null) return;
    final novels = await CharacterTraitExtractionService.listNovels(
      session.database,
      session.manifest.id,
    );
    if (!mounted) return;
    setState(() {
      _novels = novels;
      _novelId = novels.isEmpty ? null : novels.first.storyId;
    });
  }

  Future<void> _analyze() async {
    final session = ref.read(projectSessionProvider).value;
    final novelId = _novelId;
    if (session == null || novelId == null) {
      setState(() {
        _error = 'Buka proyek dengan minimal satu novel untuk ekstraksi.';
        _phase = _Phase.failed;
      });
      return;
    }
    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _selected.clear();
    });
    try {
      final manuscript = await CharacterTraitExtractionService.buildManuscript(
        session.database,
        projectId: session.manifest.id,
        storyId: novelId,
        characterName: widget.characterName,
      );
      if (manuscript.trim().isEmpty) {
        setState(() {
          _error =
              'Nama "${widget.characterName}" tidak muncul di naskah novel '
              'ini, jadi tidak ada yang bisa dianalisis.';
          _phase = _Phase.failed;
        });
        return;
      }
      final runtime = await ref.read(aiGenerationRuntimeProvider.future);
      if (runtime == null) {
        throw StateError('AI runtime unavailable for the active project.');
      }
      final result = await CharacterTraitExtractionService.extractProposals(
        generate: (prompt) =>
            runtime.generateText(prompt: prompt, providerId: _providerId),
        characterName: widget.characterName,
        manuscript: manuscript,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.proposals;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _phase = _Phase.failed;
      });
    }
  }

  Future<void> _applySelected() async {
    final result = _result;
    final session = ref.read(projectSessionProvider).value;
    if (result == null || session == null || _selected.isEmpty) return;
    final repository = CharacterRepositoryImpl(
      database: session.database,
      projectId: session.manifest.id,
      paths: ref.read(projectPathsProvider),
    );
    final current = await repository.getCharacter(widget.characterId);
    if (current == null || current.projectId != session.manifest.id) {
      setState(() {
        _error = 'Karakter tidak ditemukan di proyek aktif.';
        _phase = _Phase.failed;
      });
      return;
    }
    var updated = current;
    for (final index in _selected) {
      updated = applyTraitToModel(
        updated,
        result.traits[index].field,
        result.traits[index].value,
      );
    }
    // User-ticked proposals only: unselected fields (including ones the AI
    // proposes to clear) are never touched. Undoable as one command.
    await session.mutationRuntime.bus.execute(
      UpdateCharacterCommand(
        id: const Uuid().v4(),
        projectId: session.manifest.id,
        repository: repository,
        oldValue: current,
        newValue: updated,
        label: 'Apply extracted traits',
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Session provider bisa masih loading saat sheet dibuka (pola bug run244):
    // muat novel lewat post-frame tiap kali session berubah dari kosong ->
    // terisi, bukan sekali di initState.
    final session = ref.watch(projectSessionProvider).value;
    if (session != null && _novels.isEmpty && !_novelsLoading) {
      _novelsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadNovels());
    }
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: switch (_phase) {
          _Phase.consent => _consent(palette),
          _Phase.loading => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          _Phase.failed => _failed(palette),
          _Phase.proposals => _proposals(palette),
        },
      ),
    );
  }

  Widget _consent(VoidPalette palette) => Column(
    key: const ValueKey('trait-consent'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ekstraksi ciri dari naskah — ${widget.characterName}',
        style: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Potongan naskah yang menyebut karakter ini akan DIKIRIM ke '
        'provider AI yang dipilih di bawah. Hasilnya hanya proposal '
        'ber-kutipan: tidak ada field yang berubah sampai kamu mencentang '
        'dan menekan Terapkan.',
        style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
      ),
      const SizedBox(height: 14),
      if (_novels.isEmpty)
        Text(
          'Belum ada novel di proyek ini.',
          style: TextStyle(color: palette.danger, fontSize: 12.5),
        )
      else
        DropdownButtonFormField<String>(
          key: const ValueKey('trait-novel'),
          initialValue: _novelId,
          decoration: const InputDecoration(labelText: 'Novel sumber'),
          items: [
            for (final novel in _novels)
              DropdownMenuItem(value: novel.storyId, child: Text(novel.title)),
          ],
          onChanged: (value) => setState(() => _novelId = value),
        ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const ValueKey('trait-provider'),
        initialValue: _providerId,
        decoration: const InputDecoration(labelText: 'Provider AI'),
        items: const [
          DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
          DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
          DropdownMenuItem(value: 'ollama', child: Text('Ollama (lokal)')),
        ],
        onChanged: (value) =>
            setState(() => _providerId = value ?? _providerIds.first),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: VoidButton(
              key: const ValueKey('trait-cancel'),
              label: 'Batal',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VoidButton(
              key: const ValueKey('trait-analyze'),
              label: 'Analisis',
              onPressed: _novels.isEmpty ? null : _analyze,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _failed(VoidPalette palette) => Column(
    key: const ValueKey('trait-failed'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ekstraksi gagal',
        style: TextStyle(color: palette.danger, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        _error ?? 'Kesalahan tidak dikenal.',
        style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: VoidButton(
              label: 'Tutup',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VoidButton(label: 'Coba lagi', onPressed: _analyze),
          ),
        ],
      ),
    ],
  );

  Widget _proposals(VoidPalette palette) {
    final result = _result!;
    return Column(
      key: const ValueKey('trait-proposals'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proposal (${result.traits.length}) — centang yang benar',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final (index, trait) in result.traits.indexed)
                CheckboxListTile(
                  key: ValueKey('trait-proposal-$index'),
                  value: _selected.contains(index),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${trait.field}: ${trait.value}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final citation in trait.citations)
                        Text(
                          'Bab ${citation.chapter}: "${citation.quote}"',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                    ],
                  ),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(index);
                    } else {
                      _selected.remove(index);
                    }
                  }),
                ),
              if (result.unknownFields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final field in result.unknownFields)
                        Chip(
                          label: Text('unknown: $field'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: VoidButton(
                label: 'Batal',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VoidButton(
                key: const ValueKey('trait-apply'),
                label: 'Terapkan (${_selected.length})',
                onPressed: _selected.isEmpty ? null : _applySelected,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
