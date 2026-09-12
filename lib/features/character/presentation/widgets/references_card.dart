import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import '../../../project_resilience/application/project_session_manager.dart';
import '../../../projects/presentation/project_persistence_providers.dart';
import '../../application/character_reference_binder.dart';

/// Reference slot label (Face/Hair/...) plus its bound package file, when any.
class CharacterReferenceSlot {
  const CharacterReferenceSlot({required this.label, this.filePath});

  final String label;
  final String? filePath;
}

/// run243 (Choi: "lanjutkan" — parity gambar untuk area ikon-only karakter):
/// Primary References dulu merupakan enam kotak label mati dengan tombol
/// "tambah" yang hanya menampilkan snackbar. Kartu ini memuat slot nyata dari
/// tabel `character_references` (kolom filePath sudah ada sejak skema awal)
/// dan menampilkan gambar yang terikat; tombol tambah memakai file picker +
/// penyalinan ke namespace paket yang sama dipakai AssetThumbnailImporter
/// (`asset_thumbnails/`), sehingga gambar bertahan saat folder proyek pindah.
///
/// Tanpa sesi proyek, kartu jujur: label slot tetap tampil (kontrak layar
/// lama) dengan status "No image bound".
class ReferencesCard extends ConsumerStatefulWidget {
  const ReferencesCard({super.key, required this.characterId});

  final String characterId;

  @override
  ConsumerState<ReferencesCard> createState() => _ReferencesCardState();
}

class _ReferencesCardState extends ConsumerState<ReferencesCard> {
  static const List<String> slotLabels = <String>[
    'Face',
    'Hair',
    'Full Body',
    'Outfit',
    'Pose',
    'Expression',
  ];

  Future<List<CharacterReferenceSlot>>? _slots;

  late final ProviderSubscription<AsyncValue<ProjectSession?>> _sessionSub;

  @override
  void initState() {
    super.initState();
    // Session dibangun async (override/real loader); ref.read di initState
    // akan mengunci cabang no-session selamanya. Listen + reload saat siap.
    _sessionSub = ref.listenManual<AsyncValue<ProjectSession?>>(
      projectSessionProvider,
      (previous, next) {
        if ((previous?.valueOrNull) == null && next.valueOrNull != null) {
          _reload();
          setState(() {});
        }
      },
      fireImmediately: true,
    );
    _reload();
  }

  @override
  void dispose() {
    _sessionSub.close();
    super.dispose();
  }

  void _reload() {
    final session = ref.read(projectSessionProvider).valueOrNull;
    _slots = _loadSlots(session);
  }

  Future<List<CharacterReferenceSlot>> _loadSlots(
    ProjectSession? session,
  ) async {
    if (session == null) {
      return [
        for (final label in slotLabels) CharacterReferenceSlot(label: label),
      ];
    }
    final rows = await session.database.characterDao.getReferences(
      widget.characterId,
    );
    // Slot label kanonik tetap; setiap row nyata mengisi slot bertipe sama
    // (gambar basi -> kosong jujur, bukan gambar pecah).
    final byType = <String, String>{};
    for (final row in rows) {
      final type = row.type.trim();
      if (type.isEmpty) continue;
      // existsSync (bukan await exists()): path check harus selesai di zone
      // fake-async testWidgets, sama seperti pola AssetThumbnailCard.
      if (File(row.filePath).existsSync()) {
        byType.putIfAbsent(type.toLowerCase(), () => row.filePath);
      }
    }
    return [
      for (final label in slotLabels)
        CharacterReferenceSlot(
          label: label,
          filePath: byType[label.toLowerCase()],
        ),
    ];
  }

  Future<void> _addImage() async {
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Add reference to slot'),
        children: [
          for (final slot in slotLabels)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, slot),
              child: Text(slot),
            ),
        ],
      ),
    );
    if (label == null) return;
    if (!mounted) return;
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    final picked = await openFile(acceptedTypeGroups: [typeGroup]);
    final source = picked?.path;
    if (source == null) return;
    if (!mounted) return;
    try {
      await CharacterReferenceBinder(
        database: session.database,
        assetsDirectory: session.package.assetsDirectory,
      ).bind(
        characterId: widget.characterId,
        slotLabel: label,
        sourcePath: source,
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reference import failed: $error')),
      );
      return;
    }
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reference added.')));
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref.watch(projectSessionProvider).valueOrNull != null;
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Primary References',
                  style: VoidTypography.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSession)
                IconButton(
                  tooltip: 'Add reference image',
                  onPressed: _addImage,
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: context.palette.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<CharacterReferenceSlot>>(
            future: _slots,
            builder: (context, snapshot) {
              final slots =
                  snapshot.data ??
                  [
                    for (final label in slotLabels)
                      CharacterReferenceSlot(label: label),
                  ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [for (final slot in slots) _Ref(slot: slot)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Ref extends StatelessWidget {
  const _Ref({required this.slot});

  final CharacterReferenceSlot slot;

  @override
  Widget build(BuildContext context) => Container(
    width: 105,
    height: 76,
    alignment: Alignment.bottomCenter,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.palette.borderSoft),
      image: slot.filePath == null
          ? null
          : DecorationImage(
              image: FileImage(File(slot.filePath!)),
              fit: BoxFit.cover,
            ),
    ),
    child: Text(
      slot.filePath == null ? '${slot.label}\nNo image' : slot.label,
      style: VoidTypography.caption,
      textAlign: TextAlign.center,
    ),
  );
}
