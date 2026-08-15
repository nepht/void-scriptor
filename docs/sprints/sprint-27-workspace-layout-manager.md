# Sprint 27 — Workspace Layout Manager + Docking Panels + Multi-Tab + Multi-Window

**Sumber arah (verbatim dari ChatGPT share kanonik):**
> Sprint 27 sebaiknya menjadi **Workspace Layout Manager + Docking Panels + Multi-Tab + Multi-Window Desktop System**. Kita akan membuat layout seperti aplikasi profesional: panel Explorer/Inspector bisa resize dan collapse, workspace tabs, split editor, saved layouts, fullscreen preview, detachable window untuk Reference Compare/Timeline, keyboard focus navigation, dan restoration layout per project.

**Status:** BLUEPRINT DETAIL — disusun oleh nephthys (arsitek) dari arah di atas + pola Sprint 1–26. Menunggu persetujuan Choirudin sebelum implementasi.

---

## Target akhir

```
┌─────────────────────────────────────────────────────────────┐
│ Top Bar (menu, undo/redo, save)                             │
├──────────┬──────────────────────────────┬───────────────────┤
│ Explorer │  Workspace                   │ Inspector         │
│ (resize, │  ├── Tab Bar (multi-tab)     │ (resize,          │
│  collapse)│  ├── Content (asset)        │  collapse)        │
│          │  └── Split editor (opsional) │                   │
│          │                              │                   │
├──────────┴──────────────────────────────┴───────────────────┤
│ Status Bar                                                   │
└─────────────────────────────────────────────────────────────┘
```

- Panel Explorer/Inspector **bisa di-resize** (drag border) dan **di-collapse**.
- Workspace **multi-tab**: buka banyak asset sekaligus, pindah via tab.
- **Split editor**: dua workspace berdampingan (mis. Timeline + Reference).
- **Saved layouts**: simpan/muat preset layout (nama, ukuran panel, tab aktif).
- **Fullscreen preview**: workspace penuh tanpa Explorer/Inspector/StatusBar.
- **Detachable window**: Reference Compare & Timeline bisa dilepas ke jendela OS sendiri.
- **Keyboard focus navigation**: Ctrl+1/2/3 fokus Explorer/Workspace/Inspector.
- **Layout restoration per project**: layout tersimpan & dipulihkan saat buka project.

---

## Struktur file target

```text
lib/features/workspace_layout/
├── domain/
│   ├── layout_model.dart          # PanelLayout, WorkspaceLayoutState
│   ├── workspace_tab.dart          # WorkspaceTab (id, assetId, assetType, title)
│   ├── layout_preset.dart          # LayoutPreset (nama + ukuran + tab aktif)
│   └── panel_side.dart             # enum PanelSide { left, right }
├── application/
│   ├── layout_controller.dart      # LayoutController (Notifier) — state layout
│   ├── workspace_tab_controller.dart # tab open/close/activate/close-others
│   ├── layout_preset_repository.dart # simpan/muat preset + per-project restore
│   └── layout_keyboard_navigation.dart # map keyboard → fokus panel
├── presentation/
│   ├── resizable_panel.dart         # ResizablePanel (drag border resize)
│   ├── collapsible_panel.dart       # collapse/expand wrapper
│   ├── workspace_tab_bar.dart       # tab bar multi-tab (dengan close button)
│   ├── workspace_layout_shell.dart  # komposisi Explorer/Workspace/Inspector
│   ├── split_editor.dart            # dua workspace berdampingan
│   ├── fullscreen_preview.dart      # overlay fullscreen
│   └── layout_preset_menu.dart      # UI simpan/muat layout
└── infra/
    └── detachable_window_service.dart # buka jendela OS terpisah (plugin)
```

---

## Step 27.1 — Domain: panel state model

Buat `layout_model.dart`:

```dart
enum PanelSide { left, right }

class PanelLayout {
  const PanelLayout({
    required this.leftWidth,
    required this.rightWidth,
    required this.leftCollapsed,
    required this.rightCollapsed,
    required this.splitRatio,
    this.activeTabIndex = 0,
  });

  final double leftWidth;   // default 245
  final double rightWidth;  // default 310
  final bool leftCollapsed;
  final bool rightCollapsed;
  final double splitRatio;  // 0.5 = split merata
  final int activeTabIndex;

  PanelLayout copyWith({...});  // immutable
  static const defaults = PanelLayout(
    leftWidth: 245, rightWidth: 310,
    leftCollapsed: false, rightCollapsed: false,
    splitRatio: 0.5,
  );
}
```

## Step 27.2 — Domain: workspace tab model

Buat `workspace_tab.dart`:

```dart
class WorkspaceTab {
  const WorkspaceTab({
    required this.id,
    required this.assetId,
    required this.assetType,
    required this.title,
  });

  final String id;          // unik, untuk reorder/dedup
  final String assetId;
  final AssetType assetType;
  final String title;

  // equality by id
}
```

## Step 27.3 — Domain: layout preset model

Buat `layout_preset.dart`:

```dart
class LayoutPreset {
  const LayoutPreset({
    required this.name,
    required this.layout,
  });

  final String name;
  final PanelLayout layout;
}
```

## Step 27.4 — LayoutController (Riverpod Notifier)

Buat `layout_controller.dart`. State = `PanelLayout`. Method:
- `setLeftWidth(double)`, `setRightWidth(double)`
- `toggleLeft()`, `toggleRight()`
- `setSplitRatio(double)`
- `setActiveTab(int)`
- `applyPreset(LayoutPreset)`

Constraint (diuji): lebar dibatasi `minWidth` (200) dan `maxWidth` (0.45 × total), ratio dibatasi [0.25, 0.75].

## Step 27.5 — WorkspaceTabController (Riverpod Notifier)

State = `List<WorkspaceTab>` + `activeTabId`. Method:
- `open(WorkspaceTab)` — dedup by id (jika sudah ada → activate, bukan duplikat)
- `close(String id)` — hapus tab; jika tab aktif → pindah ke tetangga
- `closeOthers(String id)`
- `closeAll()`
- `activate(String id)`

## Step 27.6 — LayoutPresetRepository

Buat `layout_preset_repository.dart`. Interface:
```dart
abstract interface class LayoutPresetRepository {
  Future<List<LayoutPreset>> list(String projectId);
  Future<void> save(String projectId, LayoutPreset preset);
  Future<void> delete(String projectId, String name);
  Future<PanelLayout?> restore(String projectId); // layout aktif terakhir
  Future<void> persist(String projectId, PanelLayout layout);
}
```

Implementasi `DriftLayoutPresetRepository` — table `layout_presets` + table `project_layout_state` (schema migration v39).

## Step 27.7 — Schema migration v39

Tambah table:
```dart
class LayoutPresets extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get json => text()(); // PanelLayout serialized
  @override Set<Column<Object>> get primaryKey => {id};
}

class ProjectLayoutStates extends Table {
  TextColumn get projectId => text()();
  TextColumn get json => text()(); // PanelLayout aktif
  @override Set<Column<Object>> get primaryKey => {projectId};
}
```

Naikkan `currentSchemaVersion` 38 → 39 + migration `createTable`.

## Step 27.8 — Layout keyboard navigation

Buat `layout_keyboard_navigation.dart`. Map:
- `Ctrl+1` → fokus Explorer
- `Ctrl+2` → fokus Workspace
- `Ctrl+3` → fokus Inspector
- `Ctrl+W` → close tab aktif
- `Ctrl+Shift+W` → close others
- `F11` → toggle fullscreen preview
- `Ctrl+Shift+L` → buka layout preset menu

Daftarkan di `Shortcuts`/`Actions` pada `WorkspaceLayoutShell` (bukan di `VoidDesktopShell` yang sudah penuh).

## Step 27.9 — ResizablePanel (drag border)

Buat `resizable_panel.dart`. Widget generic:
```dart
class ResizablePanel extends StatefulWidget {
  const ResizablePanel({
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.onResize,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.child,
  });
}
```

Implementasi: `MouseRegion` + `GestureDetector` pada border kanan/kiri; update width saat drag horizontal.

## Step 27.10 — Wire ExplorerPanel jadi resizable

Ganti `ExplorerPanel` hardcode `width: 245` → baca dari `LayoutController`, bungkus `ResizablePanel`. Collapse tombol di header.

## Step 27.11 — Wire InspectorPanel jadi resizable

Sama untuk `InspectorPanel` (`width: 310`).

## Step 27.12 — CollapsiblePanel wrapper

Buat `collapsible_panel.dart` — saat collapsed, tampilkan strip tipis (ikon saja) yang bisa diklik untuk expand.

## Step 27.13 — WorkspaceTabBar (multi-tab)

Buat `workspace_tab_bar.dart`. Ganti `_WorkspaceTabs` hardcode (di `workspace_panel.dart`) dengan tab bar dinamis:
- Render satu tab per `WorkspaceTab` (title + close ✕)
- Tab aktif disorot
- Scroll horizontal bila banyak tab
- Klik tab → `activate`
- Klik ✕ → `close`

## Step 27.14 — WorkspaceLayoutShell

Buat `workspace_layout_shell.dart` — komposisi baru:
```dart
Row(
  children: [
    ResizablePanel(ExplorerPanel()),
    Expanded(WorkspacePanel(tabs: multi-tab)),
    ResizablePanel(InspectorPanel()),
  ],
)
```

## Step 27.15 — Refactor VoidDesktopShell

Ganti `Row(ExplorerPanel, WorkspacePanel, InspectorPanel)` di `void_desktop_shell.dart` dengan `WorkspaceLayoutShell()`. `Shortcuts` layout dipindah ke shell layout. StatusBar tetap.

## Step 27.16 — Split editor

Buat `split_editor.dart`. State `splitRatio` + `splitActive` (bool). Saat aktif, Workspace area menampilkan dua `WorkspaceResolver` berdampingan (tab aktif di kiri, tab kedua di kanan) dipisah divider yang bisa digeser.

## Step 27.17 — Fullscreen preview

Buat `fullscreen_preview.dart`. Saat aktif, overlay menutupi seluruh shell (hanya konten workspace), dengan tombol exit. Toggle via F11.

## Step 27.18 — Saved layouts (UI)

Buat `layout_preset_menu.dart`. Menu untuk:
- Simpan layout saat ini (nama)
- Daftar preset tersimpan → klik untuk apply
- Hapus preset

## Step 27.19 — Detachable window service (infra)

Buat `detachable_window_service.dart`. Interface:
```dart
abstract interface class DetachableWindowService {
  Future<void> openDetached(String title, Widget Function() builder);
}
```

Implementasi awal: **no-op yang jujur** (menampilkan SnackBar "Detached window requires desktop-multi-window plugin"). Tandai eksplisit, JANGAN silent no-op (sesuai konvensi repo).

## Step 27.20 — Layout restoration per project

Saat `projectSessionProvider` berubah (buka project), panggil `LayoutPresetRepository.restore(projectId)` → apply ke `LayoutController`. Saat project ditutup → `persist`.

## Step 27.21 — DoD Sprint 27

```
✓ Explorer & Inspector bisa resize (drag border)
✓ Explorer & Inspector bisa collapse/expand
✓ Workspace multi-tab: open/close/activate/close-others
✓ Tab dedup (buka asset sama → activate, bukan duplikat)
✓ Split editor dengan divider yang bisa digeser
✓ Fullscreen preview (F11) toggle
✓ Saved layouts (simpan/muat/hapus)
✓ Layout restoration per project
✓ Keyboard focus navigation (Ctrl+1/2/3, Ctrl+W, F11)
✓ Detachable window = no-op jujur (SnackBar), bukan silent
```

---

## Regression gates (wajib setiap step commit)

```text
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
git diff --check
```

## Catatan risiko (jujur)

1. **Detachable window (multi-window)** memerlukan plugin `desktop_multi_window` (atau `bitsdojo_window`) — belum ada di pubspec. Fase ini saya tandai sebagai **infra scaffold + no-op jujur**, bukan fitur penuh, sampai plugin disetujui untuk ditambahkan.
2. **Persistensi layout** butuh migration schema v39 (table `layout_presets` + `project_layout_state`) — konsisten dengan pola migration v37/v38.
3. **Responsive**: pada viewport sempit (mobile/tablet), `ResizablePanel` tidak dipakai — collapse otomatis; multi-tab tetap jalan. Harus diuji via widget test narrow viewport (pola `auth_flow_test` yang ada).

---

## Status: ✅ SELESAI (27.1 → 27.21) — 2026-08-15

Seluruh step Sprint 27 diimplementasikan via TDD RED→GREEN, `flutter analyze` bersih,
commit + push per unit fitur. Bukti gate (live, bukan klaim):

```text
dart format --set-exit-if-changed lib test   PASS (667 files, 0 changed)
flutter analyze                               PASS (0 issues)
flutter test                                  458 PASS  ← naik dari 437
flutter build web --release                   PASS (62.4s, ✓ Built build/web)
git diff --check                              PASS
```

Commit (terbaru dulu):

```text
a0117ec feat(sprint-27): add layout preset menu, detachable window scaffold, per-project restoration
ae3ae0d feat(sprint-27): add split editor and fullscreen preview
6dc30a7 refactor(sprint-27): wire desktop shell through workspace layout shell
cf5d5a6 feat(sprint-27): add workspace tab bar and dockable layout shell
c0cf54d feat(sprint-27): add resizable and collapsible panel widgets
1ae5cee feat(sprint-27): add layout keyboard navigation intents
70e7dee feat(sprint-27): add layout preset persistence via schema v39
ce37074 feat(sprint-27): add layout and workspace tab controllers
6cd1347 feat(sprint-27): add workspace layout domain models
```

### Catatan risiko yang tersisa (bukan blocker Sprint 27)
- **Detachable window** = scaffold jujur (SnackBar) — butuh plugin multi-window di sprint mendatang.
- **Narrow viewport responsive** — `ResizablePanel` belum punya test viewport sempit khusus; dicatat sebagai follow-up.
- **Build web advisory** "CupertinoIcons" adalah warning pre-existing, tidak menggagalkan build.

