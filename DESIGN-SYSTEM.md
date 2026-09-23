# DESIGN-SYSTEM.md — Void Scriptor

Sumber kebenaran token: `lib/design_system/`. Dokumen ini peta & aturan pemakaian; kode tetap otoritatif.
Brand mark: `assets/brands/own_brands/void_scriptor/BRAND_SPEC.md`.

## 1. Struktur modul

```text
lib/design_system/
├── colors/    void_colors.dart (dark), void_colors_light.dart
├── theme/     void_palette.dart, void_theme.dart, void_theme_variant.dart,
│              void_theme_presets.dart, void_theme_context.dart
├── typography/ void_typography.dart
├── spacing/   void_spacing.dart
├── radius/    void_radius.dart
├── widgets/   void_button.dart, void_card.dart, branding/{void_logo,brand_assets}.dart
```

## 2. Mode & varian tema

`VoidThemeVariant` (`theme/void_theme_variant.dart`) = keluarga aksen × kecerahan:

| Varian | Aksen | Karakter |
|---|---|---|
| `voidPurple` | Void Purple `#8B5CF6` | **DEFAULT**, identitas Void |
| `ink` | abu-arang kebiruan | monokrom, tenang, fokus naskah |
| `ember` | amber/bara | hangat |
| `sage` | hijau herbal | lembut, alami |
| `rose` | merah mawar | ekspresif |
| `ocean` | biru laut | sejuk |

- Setiap varian punya pasangan `darkPalette` + `lightPalette` → 6 × 2 = 12 tema.
- Akses: `variant.lightTheme` / `variant.darkTheme`; default `VoidTheme.dark` / `VoidTheme.light` tetap valid.
- Pilihan tema disimpan per pengguna (`ThemeStorage`); keputusan estetika = Choirudin.

## 3. Token warna (`VoidPalette`, ThemeExtension)

Semua varian memakai struktur field yang sama; hanya aksen & netral yang di-shift agar kontras tidak turun.

**Surface ladder (dark default):**
`background #090A0F` → `backgroundSecondary #0E1017` → `surface #12141D` → `surfaceElevated #171A25` → `surfaceHover #1D2030` (+ `panel`, `panelSecondary`).

**Aksen & status:** `primary #8B5CF6`, `primaryBright #A78BFA`, `primaryDark #6D3DEB`, `secondary #6366F1`; status `success #31C48D`, `warning #F4B740`, `danger #F05252`, `info #3F83F8`.

**Teks:** `textPrimary` → `textSecondary` → `textMuted` → `textDisabled` (4 level, jangan dilompati).

**Garis:** `border`, `borderSoft`, `divider` — pemisah = `divider`; outline kontrol = `border`.

**Aturan kontras (dari gate yang sudah lolos):**
- Teks vs surface memenuhi WCAG AA pada kedua brightness (diuji `accessibility gate` 112.47).
- Segmen grafik ≥ 3:1 terhadap tetangganya.
- Jangan hardcode warna di widget; ambil dari `VoidPalette` / `SemanticColors`.

## 4. Brand mark (BRAND_SPEC.md)

- Emblem master + varian transparan/purple/white/ink + lockup dark/light (PNG & SVG).
- Clear space minimum ¼ lebar render; monokrom wajib untuk mark < 64 px.
- Wordmark masih **provisional** — pergantian font butuh persetujuan Choirudin.

## 5. Spacing, radius, tipografi

- `VoidSpacing.*` (scale resmi) — dipakai konsisten; variasi rhythm dilakukan dengan memilih LEVEL scale, bukan nilai acak.
- `VoidRadius.*` — sedikit radius disengaja per jenis elemen (input ≠ card ≠ pill), bukan satu radius untuk semua.
- `VoidTypography.*` — family dari brand character; label kategori/UX memakai token, bukan `fontSize` inline.
- Pitfall tercatat di `AGENTS.md`: `VoidSpacing`/`VoidTextStyles` adalah `static final` → tidak boleh dalam konteks `const`; `SemanticColors` mutable static → jangan dalam `const`.

## 6. Komponen inti

- `VoidButton` — properti `isEnabled` / `isLoading` (bukan `loading`).
- `VoidCard` — container standar; elevasi hanya bila memang perlu naik.
- `VoidLogo` / `brand_assets` — akses emblem sesuai surface.

## 7. Layout adaptif

- Breakpoints & resolver: `lib/app/adaptive/{void_breaks,void_resolver,void_device_type}`.
- Shell terpisah: `app/shell/desktop/*` dan `app/shell/mobile/*`.
- Kontrak widget test: selalu uji **desktop width + narrow 390px**, dan `tester.takeException()` harus null (overflow = gagal).

## 8. Checklist antislop saat mengubah UI

- Palet dari token, bukan gradient default biru-ungu.
- Aksen dipakai di momen kunci saja, tidak disebar.
- Tidak ada emoji dekoratif di teks UI.
- Empty/loading/error state menyebab + aksi berikutnya (bukan "No data").
- Nav/kontrol mati wajib label "Coming soon" atau dihapus.
- Angka/delta harus data nyata atau placeholder berlabel.
- Motion ada tujuan UX tertulis; tanpa loop abadi.
