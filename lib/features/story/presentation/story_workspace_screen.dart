import 'dart:io';

import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import '../../project_resilience/application/durable_draft_journal.dart';
import '../application/durable_autosave_coordinator.dart';
import '../application/story_docx_exporter.dart';
import 'package:flutter/services.dart';

import '../application/story_markdown_exporter.dart';
import '../application/story_txt_exporter.dart';
import '../domain/lore_link_suggester.dart';

import '../data/story_repository_impl.dart';
import '../domain/focus_writing_mode.dart';
import '../../character/domain/character_quick_ref.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    show SceneDraftSnapshot;
import '../../workspaces/application/story_cast_loader.dart';
import '../../workspaces/application/workspace_projection_cache.dart';
import '../../workspaces/domain/narrative_assignment.dart';
import '../../workspaces/presentation/workspace_export_actions.dart';
import '../../workspaces/presentation/workspace_export_options_dialog.dart';
import '../../workspaces/application/workspace_import_service.dart'
    show WorkspaceArchivePreflight;
import '../../workspaces/presentation/workspace_import_actions.dart';
import '../../workspaces/presentation/workspace_import_options_dialog.dart';
import '../../workspaces/presentation/workspace_projection_card.dart';

class StoryWorkspaceScreen extends StatefulWidget {
  const StoryWorkspaceScreen({
    super.key,
    required this.storyId,
    this.repository,
    this.sceneId,
    this.exportDirectory,
    this.workspaceProjection,
    this.novelExportActions,
    this.novelImportActions,
    this.pickImportArchive,
    this.onTapAddCharacter,
    this.loadLoreCatalog,
    this.onCreateLoreEntity,
    this.draftJournal,
    this.activeSection,
    this.onSectionRequested,
    this.loadCast,
    this.onTapCharacter,
  });
  final String storyId;
  final StoryRepositoryImpl? repository;
  final String? sceneId;
  final Directory? exportDirectory;
  final Future<WorkspaceProjection>? workspaceProjection;

  /// Optional link-creation binding (145.43 friksi #1): membuka picker
  /// karakter dan mengembalikan projection segar saat link dibuat. Null
  /// menjaga aksi absen dari kartu Linked Characters.
  final Future<WorkspaceProjection?> Function(String novelWorkspaceId)?
  onTapAddCharacter;

  /// Optional Novel workspace export binding. Null keeps the button absent —
  /// the screen never fabricates an export path without an explicit binding.
  final WorkspaceExportActions? novelExportActions;

  /// Optional Novel workspace import binding. Null keeps the button absent.
  final WorkspaceImportActions? novelImportActions;

  /// Optional archive picker for the import flow. Null disables importing
  /// honestly instead of pretending a picker exists.
  final Future<File?> Function()? pickImportArchive;

  /// Optional lore-linking binding (Step 109.10): loads the project lore
  /// catalog for inline autocomplete. Null keeps the menu disabled.
  final Future<List<LoreEntityRef>> Function()? loadLoreCatalog;

  /// Optional lore-linking binding (Step 109.10): creates a brand-new lore
  /// entity by name. Null hides the create action instead of faking it.
  final Future<LoreEntityRef> Function(String name)? onCreateLoreEntity;

  /// Step 145.30 Autosave Snapshot and Crash Recovery: durable journal
  /// untuk draf yang belum tersimpan. Null (mis. layar test tanpa paket)
  /// berarti journal tidak aktif; autosave utama tetap berjalan.
  final DurableDraftJournal? draftJournal;

  /// Optional workspace-level section selected by the surrounding shell.
  /// Null preserves the legacy all-in-one screen for standalone embeddings.
  final String? activeSection;

  /// Wiring sprint Task 1 (character-roles-support phase_one, novel-side
  /// view): read-only cast loader for the Cast section. Null keeps the
  /// section absent so screens without a project session never render a
  /// broken cast list — mirrors [loadLoreCatalog].
  final Future<List<StoryCastEntry>> Function(String novelWorkspaceId)?
  loadCast;

  /// Opens the full character workspace for the tapped cast row (novel →
  /// character direction of the two-way link). Null keeps rows read-only,
  /// mirroring how [loadCast] keeps the whole section absent without a
  /// session.
  final void Function(String characterId)? onTapCharacter;

  final ValueChanged<String>? onSectionRequested;

  @override
  State<StoryWorkspaceScreen> createState() => _StoryWorkspaceScreenState();
}

class _StoryWorkspaceScreenState extends State<StoryWorkspaceScreen> {
  final _draft = TextEditingController();
  late final DurableAutosaveCoordinator _autosave;

  /// Step 145.30 Autosave Snapshot and Crash Recovery: journal draf
  /// yang belum tersimpan durable. Null berarti tidak ada directory
  /// binding (layar test tanpa paket) - journal jujur tidak aktif.
  DurableDraftJournal? _draftJournal;
  int _words = 0;
  String? _selectedSceneId;
  String? _selectedSceneTitle;

  /// Inline lore-link autocomplete state (Step 109.10). All overlay work is
  /// driven from the draft text field; nothing renders without an explicit
  /// [StoryWorkspaceScreen.loadLoreCatalog] binding.
  final _layerLink = LayerLink();
  OverlayEntry? _loreOverlay;
  List<LoreEntityRef>? _loreCatalog;
  String? _loreQuery;
  List<LoreEntityRef> _loreSuggestions = const <LoreEntityRef>[];
  LoreEntityRef? _loreExisting;
  int? _loreHoverIndex;
  int _loreHighlight = 0;
  bool _loreCreating = false;

  /// Additive ADR-WS-001 guard: while a novel archive export/import is in
  /// flight the trigger buttons stay locked so a second tap cannot start a
  /// parallel archive write (ux rule: disable + loading state, never allow
  /// multiple submissions during processing).
  bool _novelIoBusy = false;

  /// Step 145.24 Novel Workspace Core: state pencarian novel lintas scene.
  /// Semua data diambil lewat repository.searchNovel — UI tidak pernah
  /// membaca Drift atau menulis query ad-hoc.
  List<NovelSearchResult>? _searchResults;

  /// Step 145.24 Novel Workspace Core: state snapshot draft per scene
  /// terpilih. Label snapshot manual diisi lewat field terpisah; restore
  /// selalu lewat repository.restoreSceneDraftSnapshot.
  List<SceneDraftSnapshot> _sceneSnapshots = const [];

  /// Task 1 (novel-side cast view): cast rows for this novel, loaded once
  /// per story via [StoryWorkspaceScreen.loadCast]; null = not loaded yet.
  List<StoryCastEntry>? _cast;
  String? _castStoryId;

  /// Step 145.25 Character Workspace Core: kartu quick reference kanonik
  /// karakter scene terpilih, dimuat lewat repository.quickReferenceForScene.
  List<CharacterQuickRef> _sceneQuickRefs = const [];
  String _restoringSnapshotId = '';

  /// Step 145.28 Writing Room Focus: jam simpan terakhir dari jalur
  /// autosave layar; null berarti belum pernah menyimpan lewat jalur
  /// ini (label jujur 'Belum tersimpan').
  DateTime? _lastSavedAt;

  /// True saat persist autosave sedang berjalan (save in-flight).
  bool _isSaving = false;

  /// True sejak State.dispose dimulai. Callback autosave sinkron
  /// (onSaveStarted) bisa menembak dari flush dispose ketika element
  /// sudah defunct namun mounted masih true - setState pada kondisi
  /// itu ilegal, jadi dinyatakan lewat flag ini.
  bool _disposeStarted = false;

  /// Pesan kegagalan persist autosave yang TERLIHAT (bukan silent).
  /// Di-set oleh onPersistError koordinator; dihapus saat simpan berikutnya
  /// berhasil. Draf tetap aman di journal durable selama error aktif.
  String? _autosaveError;

  /// Step 145.30 Autosave Snapshot and Crash Recovery: draf yang belum
  /// tersimpan dan menunggu keputusan pengguna saat startup. Sumber data
  /// tunggal = DurableDraftJournal.pendingEntries(); kosong berarti tidak
  /// ada yang perlu dipulihkan (panel absen, bukan panel kosong).
  List<PendingDraftEntry> _pendingRecovery = const [];
  bool _recoveryBusy = false;

  /// Step 145.28: sesi fokus menulis (domain Step 109.20) yang
  /// di-wire ke layar. Saat aktif, panel chrome samping disembunyikan
  /// dan label autosave dirender dari sesi (autosave_visible).
  FocusWritingSession? _focusSession;

  /// bug-hunt-run128 BUG-17: future hierarchy dipegang State, BUKAN
  /// dialokasi di build. FutureBuilder yang menerima future baru pada
  /// setiap rebuild membuat setiap keystroke (dua setState lewat _count)
  /// menembak query hierarchy penuh (N+1) dan mengembalikan panel
  /// CHAPTERS ke "Memuat struktur story...". Cache dibatalkan saat
  /// storyId berubah atau lewat _reloadStoryHierarchy setelah mutasi
  /// struktur (impor novel workspace).
  Future<StoryHierarchy>? _hierarchyFuture;
  String? _hierarchyStoryId;

  /// bug-hunt-run128 BUG-18: nomor urut seleksi scene. Di-bump setiap
  /// seleksi berpindah; setiap muatan (draf/snapshot/quick-ref) menangkap
  /// nomor saat diminta dan membuang hasilnya bila seleksi sudah berubah.
  /// Tanpa ini, pindah scene cepat A→B membuat muatan A yang selesai
  /// belakangan menimpa editor B, dan ketikan berikutnya ter-autosave ke
  /// scene yang salah (clobber lintas scene).
  int _sceneLoadSeq = 0;

  /// Post-frame seleksi sedang terjadwal (anti duplikasi antar rebuild).
  bool _selectionSyncScheduled = false;

  /// Mengembalikan future hierarchy yang stabil antar rebuild.
  /// Hanya dipanggil dari _buildLiveChapters setelah null-check repository.
  Future<StoryHierarchy> _ensureHierarchyFuture() {
    final storyId = widget.storyId;
    if (storyId != _hierarchyStoryId) {
      _hierarchyStoryId = storyId;
      _hierarchyFuture = null;
    }
    return _hierarchyFuture ??= widget.repository!.getStoryHierarchy(storyId);
  }

  /// bug-hunt-run128 BUG-17: refresh eksplisit setelah mutasi struktur
  /// (impor novel workspace) agar panel CHAPTERS tidak stale — cache
  /// future tidak lagi mengandalkan rebuild insidental untuk memuat ulang.
  void _reloadStoryHierarchy() {
    final repository = widget.repository;
    if (repository == null) return;
    _hierarchyStoryId = widget.storyId;
    _hierarchyFuture = repository.getStoryHierarchy(widget.storyId);
  }

  @override
  void initState() {
    super.initState();
    _selectedSceneId = widget.sceneId;
    _draftJournal = widget.draftJournal;
    _ensureCastLoaded();
    // Step 145.30: koordinator autosave yang menyatukan debounce, journal
    // durable, dan persist dengan urutan no-silent-loss. Acknowledge hanya
    // setelah persist sukses; dispose mem-flush draf yang masih menunggu.
    _autosave = DurableAutosaveCoordinator(
      debounceDelay: const Duration(milliseconds: 1500),
      persist: (sceneId, content) async {
        final repository = widget.repository;
        if (repository == null) return;
        await repository.saveSceneDraft(sceneId, content);
      },
      journal: _draftJournal,
      onSaved: (sceneId, content) {
        if (!mounted) return;
        setState(() {
          _lastSavedAt = DateTime.now();
          _autosaveError = null;
          _isSaving = false;
        });
      },
      onSaveStarted: (sceneId, content) {
        if (!mounted || _disposeStarted) return;
        setState(() => _isSaving = true);
      },
      onPersistError: (sceneId, content, error) {
        // Kontrak no-silent-loss: kegagalan persist ditampilkan, draf tetap
        // pending + entri journal durable dipertahankan (dapat di-retry atau
        // dipulihkan lewat panel DRAFT RECOVERY saat layar dibuka ulang).
        if (!mounted) return;
        setState(() {
          _autosaveError = 'Gagal menyimpan draf: $error';
          _isSaving = false;
        });
      },
    );
    _loadDraft();
    _loadPendingRecovery();
    _prefetchLoreCatalog();
  }

  Future<void> _loadDraft() async {
    final repository = widget.repository;
    final sceneId = widget.sceneId;
    if (repository == null || sceneId == null) return;
    // bug-hunt-run128 BUG-18: muat scene eksplisit memakai guard seq yang
    // sama; bila seleksi berpindah sebelum muatan selesai, hasil dibuang.
    final seq = _sceneLoadSeq;
    final content = await repository.getSceneDraft(sceneId);
    if (!mounted || content == null || seq != _sceneLoadSeq) return;
    _draft.value = TextEditingValue(text: content);
    setState(() => _updateWordCount(content));
  }

  void _updateWordCount(String value) {
    _words = value.trim().isEmpty
        ? 0
        : value.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _disposeStarted = true;
    _teardownLoreMenu();
    // Step 145.30: flush draf yang masih menunggu debounce (no silent loss)
    // alih-alih hanya membatalkan timer.
    _autosave.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _count(String value) {
    setState(() => _updateWordCount(value));
    // Step 145.28: suntingan baru membatalkan label 'Tersimpan' -
    // save state kembali 'Belum tersimpan' sampai autosave selesai.
    if (_lastSavedAt != null) {
      setState(() => _lastSavedAt = null);
    }
    final repository = widget.repository;
    final sceneId = _selectedSceneId;
    if (repository != null && sceneId != null) {
      // Step 145.30: koordinator menyatukan stage journal durable, debounce,
      // persist, dan acknowledge — urutan no-silent-loss dijaga di satu
      // tempat (crash/power-loss tidak pernah kehilangan suntingan).
      _autosave.onDraftChanged(sceneId: sceneId, content: value);
    }
  }

  // ---- Inline lore-link autocomplete (Step 109.10) -------------------------

  void _onDraftChanged(String value) {
    _count(value);
    _syncLoreMenu();
  }

  void _prefetchLoreCatalog() {
    final loader = widget.loadLoreCatalog;
    if (loader == null || _loreCatalog != null) return;
    loader().then((catalog) {
      if (!mounted) return;
      setState(() => _loreCatalog = catalog);
    });
  }

  /// Task 1: one load per story id; stale loads (story switched before the
  /// future resolves) are dropped instead of polluting the new novel's cast.
  void _ensureCastLoaded() {
    final loader = widget.loadCast;
    final storyId = widget.storyId;
    if (loader == null || _castStoryId == storyId) return;
    _castStoryId = storyId;
    _cast = null;
    loader(storyId).then((cast) {
      if (!mounted || _castStoryId != storyId) return;
      setState(() => _cast = cast);
    });
  }

  /// Read-only cast section (Task 1): the novel's characters with their
  /// narrative roles from the story's perspective. Shows an explicit loading
  /// and empty state; never renders rows without a loader.
  Widget _buildCastPanel(VoidPalette palette) {
    final cast = _cast;
    if (cast == null) {
      return _Panel(
        title: 'CAST',
        child: Text(
          'Loading cast…',
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }
    if (cast.isEmpty) {
      return _Panel(
        title: 'CAST',
        child: Text(
          'No cast assigned to this novel yet.',
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }
    return _Panel(
      title: 'CAST',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in cast) ...[
            InkWell(
              key: ValueKey('cast-row-${entry.characterId}'),
              onTap: widget.onTapCharacter == null
                  ? null
                  : () => widget.onTapCharacter!(entry.characterId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.assignment.roles.isEmpty
                              ? 'Unspecified'
                              : entry.assignment.roles
                                    .map(
                                      (role) => switch (role) {
                                        NarrativeRole.protagonist =>
                                          'Protagonist',
                                        NarrativeRole.antagonist =>
                                          'Antagonist',
                                        NarrativeRole.supporting =>
                                          'Supporting',
                                        NarrativeRole.background =>
                                          'Background',
                                      },
                                    )
                                    .join(', '),
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ],
                    ),
                    // Description summary straight from the character
                    // profile (novel → character two-way view).
                    if (entry.biography.isNotEmpty ||
                        entry.personality.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 2),
                        child: Text(
                          [
                            if (entry.biography.isNotEmpty) entry.biography,
                            if (entry.personality.isNotEmpty) entry.personality,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 16),
          ],
          Text(
            widget.onTapCharacter == null
                ? 'Roles are edited per novel in the Character Workspace.'
                : 'Tap a cast member to open their character workspace.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _syncLoreMenu() {
    if (widget.loadLoreCatalog == null) return;
    final query = LoreLinkSyntax.activeQueryAt(
      _draft.text,
      _draft.selection.baseOffset,
    );
    if (query == null || query.trim().isEmpty) {
      _teardownLoreMenu();
      return;
    }
    final catalog = _loreCatalog;
    if (catalog == null) return; // katalog masih dimuat: menu jujur absen.

    const suggester = LoreLinkSuggester();
    final suggestions = suggester.suggest(catalog, query: query);
    final existing = suggester.exactMatchOf(catalog, query: query);
    final canOfferCreation =
        widget.onCreateLoreEntity != null && existing == null;
    if (suggestions.isEmpty && !canOfferCreation) {
      _teardownLoreMenu();
      return;
    }

    if (_loreQuery != query) _loreHighlight = 0;
    _loreHoverIndex = null;
    _loreQuery = query;
    _loreSuggestions = suggestions;
    _loreExisting = existing;

    HardwareKeyboard.instance.removeHandler(_handleLoreKey);
    HardwareKeyboard.instance.addHandler(_handleLoreKey);
    if (_loreOverlay == null) {
      _loreOverlay = OverlayEntry(builder: (_) => _buildLorePanel());
      Overlay.of(context).insert(_loreOverlay!);
    } else {
      _loreOverlay!.markNeedsBuild();
    }
  }

  void _teardownLoreMenu() {
    HardwareKeyboard.instance.removeHandler(_handleLoreKey);
    _loreOverlay?.remove();
    _loreOverlay = null;
    _loreQuery = null;
    _loreHoverIndex = null;
  }

  bool _handleLoreKey(KeyEvent event) {
    if (_loreOverlay == null) return false;
    if (event is! KeyDownEvent) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveLoreHighlight(1);
        return true;
      case LogicalKeyboardKey.arrowUp:
        _moveLoreHighlight(-1);
        return true;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _acceptLoreSuggestion();
        return true;
      case LogicalKeyboardKey.escape:
        _teardownLoreMenu();
        return true;
      default:
        return false;
    }
  }

  void _moveLoreHighlight(int delta) {
    if (_loreSuggestions.isEmpty) return;
    final next = _loreHighlight + delta;
    final max = _loreSuggestions.length - 1;
    _loreHighlight = next < 0 ? 0 : (next > max ? max : next);
    _loreHoverIndex = null;
    _loreOverlay?.markNeedsBuild();
  }

  LoreEntityRef? get _effectiveLoreHighlight {
    if (_loreSuggestions.isEmpty) return null;
    final hover = _loreHoverIndex;
    if (hover != null && hover >= 0 && hover < _loreSuggestions.length) {
      return _loreSuggestions[hover];
    }
    final max = _loreSuggestions.length - 1;
    final index = _loreHighlight < 0
        ? 0
        : (_loreHighlight > max ? max : _loreHighlight);
    return _loreSuggestions[index];
  }

  void _acceptLoreSuggestion() {
    final entity = _effectiveLoreHighlight;
    if (entity != null) {
      _completeLoreLink(entity);
      return;
    }
    _createLoreEntityFromMenu();
  }

  void _completeLoreLink(LoreEntityRef entity) {
    final query = _loreQuery;
    if (query == null) return;
    final value = _draft.value;
    final caret = value.selection.baseOffset < 0
        ? 0
        : (value.selection.baseOffset > value.text.length
              ? value.text.length
              : value.selection.baseOffset);
    final start = caret - query.length - 2;
    final expected = '[[$query';
    if (start < 0 || value.text.substring(start, caret) != expected) {
      _teardownLoreMenu();
      return;
    }
    final replacement = '[[${entity.name}]]';
    final newText = value.text.replaceRange(start, caret, replacement);
    _draft.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _count(newText);
    _teardownLoreMenu();
  }

  Future<void> _createLoreEntityFromMenu() async {
    final creator = widget.onCreateLoreEntity;
    final name = _loreQuery?.trim();
    if (creator == null || name == null || name.isEmpty || _loreCreating) {
      return;
    }
    _loreCreating = true;
    try {
      final created = await creator(name);
      if (!mounted) return;
      _loreCatalog = <LoreEntityRef>[...?_loreCatalog, created];
      _completeLoreLink(created);
    } finally {
      _loreCreating = false;
    }
  }

  void _setLoreHover(int? index) {
    _loreHoverIndex = index;
    _loreOverlay?.markNeedsBuild();
  }

  Widget _buildLorePanel() {
    final scheme = Theme.of(context).colorScheme;
    final highlighted = _effectiveLoreHighlight;
    final canCreate =
        widget.onCreateLoreEntity != null &&
        _loreExisting == null &&
        (_loreQuery?.trim().isNotEmpty ?? false);

    return Positioned(
      width: 360,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(8, 8),
        showWhenUnlinked: false,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: scheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loreSuggestions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _loreSuggestions.length,
                    itemBuilder: (context, index) {
                      final entity = _loreSuggestions[index];
                      final max = _loreSuggestions.length - 1;
                      final keyboardIndex = _loreHighlight < 0
                          ? 0
                          : (_loreHighlight > max ? max : _loreHighlight);
                      final selected = _loreHoverIndex != null
                          ? _loreHoverIndex == index
                          : index == keyboardIndex;
                      return MouseRegion(
                        onEnter: (_) => _setLoreHover(index),
                        onExit: (_) => _setLoreHover(null),
                        child: InkWell(
                          onTap: () => _completeLoreLink(entity),
                          child: Container(
                            color: selected ? scheme.secondaryContainer : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(entity.name)),
                                Text(
                                  entity.kind,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (highlighted != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Text(
                    highlighted.detail.isEmpty
                        ? highlighted.kind
                        : highlighted.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_loreExisting != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: Text(
                    '${_loreExisting!.name} sudah ada di lore — '
                    'pilih untuk menautkan.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (canCreate)
                InkWell(
                  onTap: () => _createLoreEntityFromMenu(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Buat entitas "${_loreQuery!.trim()}"'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportMarkdown() async {
    final repository = widget.repository;
    final directory = widget.exportDirectory;
    if (repository == null || directory == null) return;
    final file = await const StoryMarkdownExporter().writeExport(
      repository,
      widget.storyId,
      exportDirectory: directory,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Markdown diekspor: ${file.path}')));
  }

  Future<void> _exportDocx() async {
    final repository = widget.repository;
    final directory = widget.exportDirectory;
    if (repository == null || directory == null) return;
    final file = await const StoryDocxExporter().writeExport(
      repository,
      widget.storyId,
      exportDirectory: directory,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('DOCX diekspor: ${file.path}')));
  }

  Future<void> _exportTxt() async {
    final repository = widget.repository;
    final directory = widget.exportDirectory;
    if (repository == null || directory == null) return;
    final file = await const StoryTxtExporter().writeExport(
      repository,
      widget.storyId,
      exportDirectory: directory,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('TXT diekspor: ${file.path}')));
  }

  Future<void> _exportNovelWorkspace() async {
    final actions = widget.novelExportActions;
    final directory = widget.exportDirectory;
    if (actions == null || directory == null) return;
    final options = await showWorkspaceExportOptionsDialog(context: context);
    if (!mounted || options == null) return;
    setState(() => _novelIoBusy = true);
    try {
      final file = await actions.run(
        widget.storyId,
        options,
        destination: directory,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Novel workspace diekspor: ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekspor Novel workspace gagal: $error')),
      );
    } finally {
      if (mounted) setState(() => _novelIoBusy = false);
    }
  }

  Future<void> _importNovelWorkspace() async {
    final actions = widget.novelImportActions;
    final pick = widget.pickImportArchive;
    if (actions == null || pick == null) return;
    final archive = await pick();
    if (!mounted || archive == null) return;
    // vs-hunt-20260912n BUG-10: decode the archive exactly once. The same
    // snapshot feeds the dialog's representation label and the restore, so
    // the user confirms the bytes that actually get imported.
    final WorkspaceArchivePreflight preflight;
    try {
      preflight = await actions.preflightArchive(archive);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impor Novel workspace gagal: $error')),
      );
      return;
    }
    if (!mounted) return;
    final options = await showWorkspaceImportOptionsDialog(
      context: context,
      loadRepresentation: () async => preflight.characterRepresentation,
    );
    if (!mounted || options == null) return;
    setState(() => _novelIoBusy = true);
    try {
      final result = await actions.run(archive, options, preflight: preflight);
      if (!mounted) return;
      // bug-hunt-run128 BUG-17: impor sukses = mutasi struktur (chapter/
      // scene baru). Refresh future hierarchy secara eksplisit agar panel
      // CHAPTERS tidak stale — cache future tidak lagi mengandalkan
      // rebuild insidental untuk memuat ulang.
      _reloadStoryHierarchy();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.skipped
                ? 'Impor dilewati: workspace sudah ada.'
                : 'Novel workspace diimpor: '
                      '${result.restoredLinkCount} link dipulihkan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impor Novel workspace gagal: $error')),
      );
    } finally {
      if (mounted) setState(() => _novelIoBusy = false);
    }
  }

  /// Step 145.28: label autosave yang selalu akurat terhadap keadaan
  /// (kontrak domain 109.20 autosave_visible), bukan teks statis.
  String get _autosaveLabel {
    final session = _focusSession;
    if (session != null && session.isActive) {
      return session.autosaveLabel;
    }
    if (_isSaving) return 'Menyimpan...';
    final savedAt = _lastSavedAt;
    if (savedAt == null) return 'Belum tersimpan';
    final hh = savedAt.hour.toString().padLeft(2, '0');
    final mm = savedAt.minute.toString().padLeft(2, '0');
    return 'Tersimpan $hh:$mm';
  }

  bool get _isFocusActive => _focusSession?.isActive ?? false;

  /// Step 145.28: masuk mode fokus (domain 109.20 distraction_free).
  void _enterFocusMode() {
    final session = FocusWritingSession();
    session.enter();
    setState(() => _focusSession = session);
  }

  /// Step 145.28: keluar dari sesi fokus aktif.
  void _exitFocusMode() {
    _focusSession?.exit();
    setState(() => _focusSession = null);
  }

  /// Step 145.28: tombol fokus yang selalu ada di kepala layar.
  Widget _focusToggle() {
    final session = _focusSession;
    final active = session != null && session.isActive;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const ValueKey('focus_toggle'),
        onPressed: active ? _exitFocusMode : _enterFocusMode,
        icon: Icon(active ? Icons.close_fullscreen : Icons.center_focus_strong),
        label: Text(active ? 'Keluar Fokus' : 'Mode Fokus'),
      ),
    );
  }

  Widget _exportActions() => Wrap(
    spacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: widget.repository == null || widget.exportDirectory == null
            ? null
            : _exportMarkdown,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Export Markdown'),
      ),
      OutlinedButton.icon(
        onPressed: widget.repository == null || widget.exportDirectory == null
            ? null
            : _exportTxt,
        icon: const Icon(Icons.description_outlined),
        label: const Text('Export TXT'),
      ),
      OutlinedButton.icon(
        onPressed: widget.repository == null || widget.exportDirectory == null
            ? null
            : _exportDocx,
        icon: const Icon(Icons.article_outlined),
        label: const Text('Export DOCX'),
      ),
      // Additive ADR-WS-001 Novel workspace IO. Buttons appear only when an
      // explicit binding is provided by the resolver.
      if (widget.novelExportActions != null)
        OutlinedButton.icon(
          onPressed: widget.exportDirectory == null || _novelIoBusy
              ? null
              : _exportNovelWorkspace,
          icon: const Icon(Icons.save_alt_outlined),
          label: const Text('Export Novel'),
        ),
      if (widget.novelImportActions != null)
        OutlinedButton.icon(
          onPressed: widget.pickImportArchive == null || _novelIoBusy
              ? null
              : _importNovelWorkspace,
          icon: const Icon(Icons.save_as_outlined),
          label: const Text('Import Novel'),
        ),
    ],
  );

  /// Step 145.24: panel snapshot scene terpilih — capture manual berlabel,
  /// daftar snapshot, dan restore per baris (backup otomatis di repository).
  /// Step 145.25: panel quick reference karakter scene terpilih.
  /// Step 145.30: panel DRAFT RECOVERY — status pemulihan yang terlihat
  /// (visible status) + restore/discard yang dikendalikan pengguna.
  Widget _buildRecoveryPanel(VoidPalette p) {
    if (_pendingRecovery.isEmpty) {
      return Text(
        'Tidak ada draf yang perlu dipulihkan.',
        style: TextStyle(color: p.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_pendingRecovery.length} draf belum tersimpan dipulihkan dari sesi sebelumnya.',
          style: TextStyle(color: p.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final entry in _pendingRecovery)
          if (entry.isCorrupt)
            ListTile(
              key: const ValueKey('recovery_corrupt_entry'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(
                'Scene ${entry.sceneId}',
                style: TextStyle(color: p.textPrimary),
              ),
              subtitle: const Text(
                'Isi draf tidak dapat dibaca (file journal korup atau '
                'terpotong). Draf ini tidak dapat dipulihkan otomatis.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: _recoveryBusy
                    ? null
                    : () => _discardPendingDraft(entry),
                child: const Text('Buang'),
              ),
            )
          else
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Scene ${entry.sceneId}',
                style: TextStyle(color: p.textPrimary),
              ),
              subtitle: Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _recoveryBusy
                        ? null
                        : () => _restorePendingDraft(entry),
                    child: const Text('Pulihkan Draft'),
                  ),
                  TextButton(
                    onPressed: _recoveryBusy
                        ? null
                        : () => _discardPendingDraft(entry),
                    child: const Text('Buang'),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildQuickRefs(VoidPalette p) {
    final sceneId = _selectedSceneId;
    if (sceneId == null) {
      return const Text('Pilih scene untuk melihat quick reference karakter.');
    }
    if (_sceneQuickRefs.isEmpty) {
      return Text(
        'Belum ada karakter pada scene ini.',
        style: TextStyle(color: p.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ref in _sceneQuickRefs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline),
            title: Text(ref.name, style: TextStyle(color: p.textPrimary)),
            subtitle: Text(
              ref.compactDescription,
              style: TextStyle(color: p.textSecondary),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(ref.role, style: TextStyle(color: p.textSecondary)),
          ),
      ],
    );
  }

  Widget _buildSnapshots(VoidPalette p) {
    final repository = widget.repository;
    final sceneId = _selectedSceneId;
    if (repository == null) {
      return const Text('Belum ada session project aktif.');
    }
    if (sceneId == null) {
      return const Text('Pilih scene untuk mengelola snapshot.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _showSnapshotDialog,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Snapshot'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _showRetentionDialog,
                icon: const Icon(Icons.tune),
                label: const Text('Atur Retensi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_sceneSnapshots.isEmpty)
          Text(
            'Belum ada snapshot untuk scene ini.',
            style: TextStyle(color: p.textSecondary),
          )
        else
          for (final snapshot in _sceneSnapshots)
            ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(
                snapshot.label,
                style: TextStyle(color: p.textPrimary),
              ),
              subtitle: Text(
                '${snapshot.kind} · ${snapshot.createdAt.toIso8601String()}',
                style: TextStyle(color: p.textSecondary),
              ),
              trailing: TextButton(
                onPressed: _restoringSnapshotId.isEmpty
                    ? () => _restoreSnapshot(snapshot.id)
                    : null,
                child: const Text('Restore'),
              ),
            ),
      ],
    );
  }

  Widget _buildLiveChapters(VoidPalette p) {
    final repository = widget.repository;
    if (repository == null) {
      return const Text('Belum ada session project aktif.');
    }
    return FutureBuilder<StoryHierarchy>(
      future: _ensureHierarchyFuture(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            snapshot.hasError
                ? 'Story belum memiliki struktur.'
                : 'Memuat struktur story...',
          );
        }
        final hierarchy = snapshot.data!;
        // bug-hunt-run128 BUG-18: keputusan seleksi TIDAK dimutasi di
        // dalam build — mutasi tanpa setState membuat bagian pohon lain
        // (header SCENE EDITOR) tetap stale sampai rebuild kebetulan
        // terjadi. Builder hanya MENDETEKSI kebutuhan seleksi awal /
        // backfill judul lalu menjadwalkan satu setState post-frame.
        StorySceneNode? defaultScene;
        if (_selectedSceneId == null) {
          for (final chapter in hierarchy.chapters) {
            if (chapter.scenes.isNotEmpty) {
              defaultScene = chapter.scenes.first;
              break;
            }
          }
        }
        String? resolvedTitle;
        if (_selectedSceneId != null && _selectedSceneTitle == null) {
          outer:
          for (final chapter in hierarchy.chapters) {
            for (final scene in chapter.scenes) {
              if (scene.id == _selectedSceneId) {
                resolvedTitle = scene.title;
                break outer;
              }
            }
          }
        }
        if ((defaultScene != null || resolvedTitle != null) &&
            !_selectionSyncScheduled) {
          _selectionSyncScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectionSyncScheduled = false;
            if (!mounted) return;
            final scene = defaultScene;
            if (scene != null && _selectedSceneId == null) {
              // Run62 (145.27 prioritas #1): layar Novel yang dibuka
              // tanpa scene eksplisit tetap harus punya scene aktif sejak
              // hierarchy termuat, agar suntingan pertama pengguna langsung
              // masuk jalur autosave + journal durable (no silent loss
              // saat pindah workspace).
              setState(() {
                _selectedSceneId = scene.id;
                _selectedSceneTitle = scene.title;
                _sceneLoadSeq++;
              });
              if (_draft.text.isEmpty) {
                _loadDraftFor(scene.id);
                _loadSnapshotsFor(scene.id);
                _loadQuickRefsFor(scene.id);
              } else {
                // Pengguna sempat mengetik sebelum hierarchy termuat:
                // ketikan dipertahankan lewat jalur autosave (journal
                // durable + debounce), bukan ditimpa muatan ulang draf.
                _count(_draft.text);
              }
            } else if (resolvedTitle != null && _selectedSceneTitle == null) {
              setState(() => _selectedSceneTitle = resolvedTitle);
            }
          });
        }
        final rows = <Widget>[];
        for (final chapter in hierarchy.chapters) {
          rows.add(_Row(label: chapter.title));
          for (final scene in chapter.scenes) {
            rows.add(
              _Row(
                label: scene.title,
                indent: true,
                selected: scene.id == (_selectedSceneId ?? widget.sceneId),
                onTap: () {
                  setState(() {
                    _selectedSceneId = scene.id;
                    _selectedSceneTitle = scene.title;
                    _sceneSnapshots = const [];
                    _sceneQuickRefs = const [];
                    _sceneLoadSeq++;
                  });
                  _loadDraftFor(scene.id);
                  _loadSnapshotsFor(scene.id);
                  _loadQuickRefsFor(scene.id);
                },
              ),
            );
          }
        }
        return rows.isEmpty
            ? const Text('Belum ada chapter atau scene.')
            : Column(children: rows);
      },
    );
  }

  /// Memuat draft + daftar snapshot scene terpilih (Step 145.24).
  /// bug-hunt-run128 BUG-18: hasil dibuang bila seleksi sudah berpindah
  /// sejak permintaan (muatan scene lama tidak boleh menimpa editor baru).
  Future<void> _loadDraftFor(String sceneId) async {
    final seq = _sceneLoadSeq;
    final content = await widget.repository?.getSceneDraft(sceneId);
    if (!mounted || seq != _sceneLoadSeq) return;
    _draft.value = TextEditingValue(text: content ?? '');
    setState(() => _updateWordCount(content ?? ''));
  }

  /// Step 145.25: muat kartu quick reference karakter scene terpilih.
  Future<void> _loadQuickRefsFor(String sceneId) async {
    final repository = widget.repository;
    if (repository == null) return;
    final seq = _sceneLoadSeq;
    final quickRefs = await repository.quickReferenceForScene(sceneId);
    if (!mounted || seq != _sceneLoadSeq) return;
    setState(() => _sceneQuickRefs = quickRefs);
  }

  /// Step 145.30: muat daftar draf yang belum tersimpan dari journal
  /// durable saat layar dibuka. Kosong berarti tidak ada recovery prompt.
  Future<void> _loadPendingRecovery() async {
    final journal = widget.draftJournal;
    if (journal == null) return;
    final pending = await journal.pendingEntries();
    if (!mounted) return;
    setState(() => _pendingRecovery = pending);
  }

  /// Step 145.30: pulihkan SATU entri pending (user-controlled restore).
  /// Urutan no-silent-loss: simpan dulu ke repository, baru acknowledge
  /// journal — crash di tengah meninggalkan entri journal yang masih
  /// bisa dipulihkan ulang.
  Future<void> _restorePendingDraft(PendingDraftEntry entry) async {
    final repository = widget.repository;
    if (repository == null || _recoveryBusy) return;
    setState(() => _recoveryBusy = true);
    try {
      await repository.saveSceneDraft(entry.sceneId, entry.content);
      // vs-hunt-20260912-autosave BUG-6 (Medium): acknowledge WAJIB
      // content-aware. Selama await save di atas, pengguna bisa mengetik
      // lagi dan autosave men-stage konten BARU ke jurnal; ack blind akan
      // menghapus entri yang belum pernah di-persist (silent loss). Bila
      // entri masih persis konten yang direstore, ia dihapus seperti
      // sebelumnya; bila tergantikan, entri baru dipertahankan dan autosave
      // berikutnya yang menyimpan serta meng-ack-nya. Jalur 'Buang' tetap
      // blind — keputusan eksplisit pengguna.
      await widget.draftJournal?.acknowledge(
        entry.sceneId,
        content: entry.content,
      );
      if (!mounted) return;
      if (_selectedSceneId == entry.sceneId) {
        _draft.value = TextEditingValue(text: entry.content);
        setState(() {
          _updateWordCount(entry.content);
          _pendingRecovery = List<PendingDraftEntry>.from(_pendingRecovery)
            ..removeWhere((e) => e.sceneId == entry.sceneId);
          _recoveryBusy = false;
        });
      } else {
        setState(() {
          _pendingRecovery = List<PendingDraftEntry>.from(_pendingRecovery)
            ..removeWhere((e) => e.sceneId == entry.sceneId);
          _recoveryBusy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recoveryBusy = false);
      rethrow;
    }
  }

  /// Step 145.30: buang entri pending tanpa menulis ke repository
  /// (keputusan eksplisit pengguna; acknowledge = delete journal entry).
  Future<void> _discardPendingDraft(PendingDraftEntry entry) async {
    if (_recoveryBusy) return;
    setState(() => _recoveryBusy = true);
    try {
      await widget.draftJournal?.acknowledge(entry.sceneId);
      if (!mounted) return;
      setState(() {
        _pendingRecovery = List<PendingDraftEntry>.from(_pendingRecovery)
          ..removeWhere((e) => e.sceneId == entry.sceneId);
        _recoveryBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _recoveryBusy = false);
      rethrow;
    }
  }

  /// Step 145.24: muat ulang daftar snapshot scene terpilih.
  Future<void> _loadSnapshotsFor(String sceneId) async {
    final repository = widget.repository;
    if (repository == null) return;
    final seq = _sceneLoadSeq;
    final snapshots = await repository.getSceneDraftSnapshots(sceneId);
    if (!mounted || seq != _sceneLoadSeq) return;
    setState(() => _sceneSnapshots = snapshots);
  }

  /// Step 145.24: jalankan pencarian novel lintas scene lewat repository.
  Future<void> _runNovelSearch(String query) async {
    final repository = widget.repository;
    if (repository == null) return;
    final results = await repository.searchNovel(query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  /// Step 145.24: dialog pencarian. Query dikumpulkan di dialog agar tree
  /// utama tetap memuat tepat satu TextField (kontrak editor draft).
  Future<void> _showNovelSearchDialog() async {
    final repository = widget.repository;
    if (repository == null) return;
    final queryController = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cari Novel'),
        content: TextField(
          controller: queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Query novel...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(queryController.text),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
    if (query == null || !mounted) return;
    await _runNovelSearch(query);
  }

  /// Step 145.24: atur batas retensi snapshot scene terpilih. Repository
  /// memangkas pelanggaran yang sudah ada (kontrak 109.22
  /// retention_controls; batas session-scoped mengikuti domain store).
  Future<void> _showRetentionDialog() async {
    final repository = widget.repository;
    final sceneId = _selectedSceneId;
    if (repository == null || sceneId == null) return;
    final limitController = TextEditingController();
    final limitText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Batas Retensi'),
        content: TextField(
          controller: limitController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Batas snapshot (mis. 5)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(limitController.text),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
    final limit = int.tryParse(limitText ?? '');
    if (limit == null || limit <= 0 || !mounted) return;
    await repository.setDraftSnapshotRetention(sceneId, maxSnapshots: limit);
    await _loadSnapshotsFor(sceneId);
  }

  /// Step 145.24: rekam snapshot manual berlabel untuk scene terpilih.
  /// Label dikumpulkan lewat dialog supaya tree utama tetap satu TextField.
  Future<void> _showSnapshotDialog() async {
    final repository = widget.repository;
    final sceneId = _selectedSceneId;
    if (repository == null || sceneId == null) return;
    final labelController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rekam Snapshot'),
        content: TextField(
          controller: labelController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Label snapshot',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(labelController.text),
            child: const Text('Rekam'),
          ),
        ],
      ),
    );
    if (label == null || label.trim().isEmpty || !mounted) return;
    // BUG-25: capture gagal (mis. scene belum punya draf tersimpan —
    // repository melempar StateError) wajib terlihat pengguna, bukan
    // exception asinkron senyap.
    try {
      await repository.captureSceneDraftSnapshot(sceneId, label: label.trim());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot tidak dapat direkam: $error')),
      );
      return;
    }
    await _loadSnapshotsFor(sceneId);
  }

  /// Step 145.24: pulihkan snapshot terpilih; repository membuat backup
  /// otomatis teks kini sebelum restore (kontrak 109.22). Kegagalan
  /// (mis. id ter-purge retensi) ditampilkan via SnackBar — finally tetap
  /// memuat ulang daftar snapshot sehingga tombol tidak terkunci.
  Future<void> _restoreSnapshot(String snapshotId) async {
    final repository = widget.repository;
    final sceneId = _selectedSceneId;
    if (repository == null || sceneId == null) return;
    _restoringSnapshotId = snapshotId;
    try {
      try {
        final content = await repository.restoreSceneDraftSnapshot(
          sceneId,
          snapshotId: snapshotId,
        );
        if (!mounted) return;
        _draft.value = TextEditingValue(text: content);
        setState(() => _updateWordCount(content));
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot tidak dapat dipulihkan: $error')),
        );
      }
    } finally {
      _restoringSnapshotId = '';
      await _loadSnapshotsFor(sceneId);
    }
  }

  Widget _buildDedicatedSection(VoidPalette palette, String section) {
    final content = <Widget>[
      Text(
        section,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 16),
      if (section == 'Outline' || section == 'Planning') ...[
        if (widget.workspaceProjection != null) ...[
          WorkspaceProjectionCard(
            projectionFuture: widget.workspaceProjection!,
            onTapAddCharacter: widget.onTapAddCharacter,
          ),
          const SizedBox(height: 12),
        ],
        _Panel(
          title: 'STORY STRUCTURE',
          child: Text(
            'Story → Arc → Chapter → Scene',
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        _Panel(title: 'CHAPTERS', child: _buildLiveChapters(palette)),
      ] else if (section == 'Lore Links') ...[
        _Panel(
          title: 'LORE LINKS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lore links are attached from the manuscript with [[name]]. '
                'Suggestions use the live project lore catalog.',
                style: TextStyle(color: palette.textSecondary),
              ),
              if (widget.onSectionRequested != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.onSectionRequested!('Manuscript'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Open Manuscript'),
                ),
              ],
            ],
          ),
        ),
      ] else if (section == 'Versions') ...[
        _Panel(title: 'SCENE SNAPSHOTS', child: _buildSnapshots(palette)),
      ] else if (section == 'Cast') ...[
        _buildCastPanel(palette),
      ] else if (section == 'Export') ...[
        _Panel(title: 'EXPORT NOVEL', child: _exportActions()),
      ],
    ];
    return ColoredBox(
      color: palette.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final section = widget.activeSection;
    if (section != null && section != 'Manuscript') {
      return _buildDedicatedSection(p, section);
    }
    return CallbackShortcuts(
      // Step 145.28: keyboard exit untuk sesi fokus (domain 109.20
      // keyboard_exit). Esc hanya menutup sesi yang memang aktif; di luar
      // mode fokus pintasan ini no-op agar navigasi rutin tak terganggu.
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleFocusEscape,
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: p.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String?>(
                        future: widget.repository?.getStoryTitle(
                          widget.storyId,
                        ),
                        builder: (context, titleSnapshot) {
                          final title = titleSnapshot.data;
                          // Friksi UX journey native (ledger 117f157, input
                          // 145.43): tampilkan judul cerita, fallback UUID
                          // hanya saat judul belum diketahui.
                          final label = (title == null || title.isEmpty)
                              ? 'Story Bible — ${widget.storyId}'
                              : 'Story Bible — $title';
                          return Text(
                            label,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (section == null) _exportActions(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _focusToggle(),
                  const SizedBox(height: 4),
                  if (section == null) ...[
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Bible')),
                        Chip(label: Text('Arcs')),
                        Chip(label: Text('Chapters')),
                        Chip(label: Text('Scenes')),
                        Chip(label: Text('Timeline')),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Step 145.30: recovery prompt di dekat puncak layar agar
                  // terlihat langsung saat startup (visible status, no silent
                  // loss) tanpa bergantung pada scroll.
                  if (_pendingRecovery.isNotEmpty) ...[
                    _Panel(
                      title: 'DRAFT RECOVERY',
                      child: _buildRecoveryPanel(p),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (section == null &&
                      widget.workspaceProjection != null) ...[
                    WorkspaceProjectionCard(
                      projectionFuture: widget.workspaceProjection!,
                      onTapAddCharacter: widget.onTapAddCharacter,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_isFocusActive) ...[
                    if (section == null) ...[
                      _Panel(
                        title: 'STORY STRUCTURE',
                        child: Text(
                          'Story → Arc 1 → Chapter 1 → Scene',
                          style: TextStyle(color: p.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _Panel(title: 'CHAPTERS', child: _buildLiveChapters(p)),
                    const SizedBox(height: 12),
                    _Panel(
                      title: 'SCENE EDITOR',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSceneTitle == null
                                ? 'Select a scene to start writing'
                                : 'Editing — $_selectedSceneTitle',
                            style: TextStyle(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CompositedTransformTarget(
                            link: _layerLink,
                            child: TextField(
                              controller: _draft,
                              minLines: 7,
                              maxLines: 14,
                              onChanged: _onDraftChanged,
                              decoration: const InputDecoration(
                                hintText: 'Tulis draft scene di sini...',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '$_words kata',
                                style: TextStyle(color: p.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                _autosaveLabel,
                                key: const ValueKey('autosave_label'),
                                style: TextStyle(color: p.textSecondary),
                              ),
                            ],
                          ),
                          if (_autosaveError != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              key: const ValueKey('autosave_error_banner'),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: p.danger.withValues(alpha: 0.12),
                                border: Border.all(color: p.danger),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _autosaveError!,
                                      style: TextStyle(color: p.danger),
                                    ),
                                  ),
                                  TextButton(
                                    key: const ValueKey(
                                      'autosave_retry_button',
                                    ),
                                    onPressed: () => _autosave.saveNow(),
                                    child: const Text('Simpan ulang'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (section == null) ...[
                      _Panel(
                        title: 'STORY BIBLE',
                        child: Text(
                          'Premise\nThemes\nTone\nWorld Rules\nCanon Rules',
                          style: TextStyle(color: p.textSecondary, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _Panel(
                      title: 'NOVEL SEARCH',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: widget.repository == null
                                  ? null
                                  : _showNovelSearchDialog,
                              icon: const Icon(Icons.search),
                              label: const Text('Cari Novel'),
                            ),
                          ),
                          if (_searchResults != null) ...[
                            const SizedBox(height: 8),
                            if (_searchResults!.isEmpty)
                              Text(
                                'Tidak ada hasil.',
                                style: TextStyle(color: p.textSecondary),
                              )
                            else
                              for (final result in _searchResults!)
                                ListTile(
                                  dense: true,
                                  leading: Badge(
                                    label: Text('${result.matchCount}'),
                                  ),
                                  title: Text(
                                    result.sceneTitle,
                                    style: TextStyle(color: p.textPrimary),
                                  ),
                                  subtitle: Text(
                                    result.chapterTitle,
                                    style: TextStyle(color: p.textSecondary),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedSceneId = result.sceneId;
                                      _selectedSceneTitle = result.sceneTitle;
                                      _sceneSnapshots = const [];
                                      _sceneQuickRefs = const [];
                                    });
                                    _loadDraftFor(result.sceneId);
                                    _loadSnapshotsFor(result.sceneId);
                                    _loadQuickRefsFor(result.sceneId);
                                  },
                                ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (section == null) ...[
                      _Panel(
                        title: 'SCENE SNAPSHOTS',
                        child: _buildSnapshots(p),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _Panel(
                      title: 'CHARACTER QUICK REF',
                      child: _buildQuickRefs(p),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 145.28: pintasan keyboard keluar fokus — hanya aktif saat sesi
  /// fokus berjalan; meneruskan alasannya sebagai keyboard exit.
  void _handleFocusEscape() {
    if (_isFocusActive) {
      _focusSession?.exit(viaKeyboard: true);
      setState(() {});
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.indent = false,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final bool indent;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      color: selected ? context.palette.panelSecondary : null,
      padding: EdgeInsets.only(left: indent ? 24 : 0, top: 7, bottom: 7),
      child: Row(
        children: [
          Icon(
            indent ? Icons.description_outlined : Icons.menu_book_outlined,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: context.palette.panel,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.primaryBright,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class StoryEditorDraft {
  const StoryEditorDraft({required this.sceneId, required this.content});
  final String sceneId;
  final String content;
}
