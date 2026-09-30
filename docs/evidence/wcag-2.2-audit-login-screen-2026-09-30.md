# WCAG 2.2 Level AA Audit — Void Scriptor Login Screen

**Target**   : `D:/VoidScriptor/void_scriptor_multiplatform/lib/features/authentication/presentation/login_screen.dart` (459 baris)
**Palette**  : `lib/design_system/theme/void_palette.dart`
**Method**   : Perhitungan rasio kontras WCAG 2.x (ITU-R BT.709) dari nilai token literal di `void_palette.dart`, bukan estimasi visual.
**Standard** : WCAG 2.2, target level **AA**, success criteria 1.4.3 (Contrast Minimum) & 1.4.11 (Non-text Contrast).
**Self-test** : Kalkulator diverifikasi terhadap nilai WCAG resmi — black/#FFFFFF = 21.00, #767676/#FFFFFF = 4.54 (ambang AA), #949494/#FFFFFF = 3.03. Semua sesuai.
**Tanggal**  : 2026-10-01 00:41

---

## 1. Ringkasan Konformitas

| | |
|---|---|
| Kriteria diuji | 18 pasangan warna |
| **PASS** | **16** |
| **FAIL** | **2** |
| Konformitas | **89%** (belum AA) |

Semua 2 kegagalan berada pada **satu token** yang sama dan **berdampak ganda** (dark + light mode).

---

## 2. Hasil Rinci

### Mode Gelap (dark)

| Kriteria | Pasangan | Rasio | Butuh | Verdict |
|---|---|---:|---:|:--|
| 1.4.3 | textPrimary #F5F5F7 / background #090A0F | 18.16 | 4.5 | PASS |
| 1.4.3 | textPrimary / surface #12141D | 16.87 | 4.5 | PASS |
| 1.4.3 | textMuted #84899A / background | 5.67 | 4.5 | PASS |
| 1.4.3 | textMuted / surface | 5.27 | 4.5 | PASS |
| **1.4.3** | **label putih / primary #8B5CF6** | **4.23** | **4.5** | **FAIL** |
| 1.4.11 | border #6B6D76 / surface | 3.56 | 3.0 | PASS |
| 1.4.11 | primary / surface (focus ring) | 4.34 | 3.0 | PASS |
| 1.4.11 | primary / background | 4.67 | 3.0 | PASS |
| 1.4.3 | error #FFB4AB / background | 11.65 | 4.5 | PASS |

### Mode Terang (light)

| Kriteria | Pasangan | Rasio | Butuh | Verdict |
|---|---|---:|---:|:--|
| 1.4.3 | textPrimary #171923 / background #F6F7FB | 16.35 | 4.5 | PASS |
| 1.4.3 | textPrimary / surface #FFFFFF | 17.50 | 4.5 | PASS |
| 1.4.3 | textMuted #646776 / background | 5.24 | 4.5 | PASS |
| 1.4.3 | textMuted / surface | 5.61 | 4.5 | PASS |
| **1.4.3** | **label putih / primary #8B5CF6** | **4.23** | **4.5** | **FAIL** |
| 1.4.11 | border #82838B / surface | 3.77 | 3.0 | PASS |
| 1.4.11 | primary / surface (focus ring) | 4.23 | 3.0 | PASS |
| 1.4.11 | primary / background | 3.96 | 3.0 | PASS |
| 1.4.3 | error #B3261E / background | 6.11 | 4.5 | PASS |

---

## 3. Temuan

### ❌ FAIL-1 — 1.4.3 Contrast (Minimum): label tombol utama

- **Lokasi** : `login_screen.dart:75-87` (`filledButtonTheme`), dipakai juga `OutlinedButton.icon` & `TextButton` di seluruh aplikasi
- **Pasangan** : label putih `#FFFFFF` di atas `primary` `#8B5CF6`
- **Rasio aktual** : **4.23:1**
- **Ambang AA** : **4.5:1**
- **Kekurangan** : 0.27 poin (~6%)
- **Catatan penting** : token `primary` itu sendiri **lolos** 1.4.11 non-text (4.23–4.67:1 vs ambang 3:1). Yang gagal hanya **kombinasi putih-di-atas-ungu** — bukan warnanya sebagai accent.

**Mengapa terjadi**: `primary` `#8B5CF6` (violet-500 Tailwind) berada tepat di bawah garis 4.5:1 terhadap putih. IniUMB常见 trap: warna accent yang **看起来** jelas di atas dark background, tapi **tidak** cukup saat dipakai sebagai **latar tombol dengan teks putih**.

**Opsi perbaikan** (pilih salah satu):

| Opsi | Token baru | Rasio putih/baru | Verdict | Trade-off |
|---|---|---:|:--|---|
| **A (rekomendasi)** | `primary` → `#7C3AED` (violet-600) | **5.32:1** | PASS | Sedikit lebih gelap; warna brand tetap ungu |
| B | `primary` → `#6D28D9` (violet-700) | 6.71:1 | PASS | Lebih pekat,情绪 "berat" |
| C | Ganti label tombol ke `#0B0B0F` (hitam) | 4.67:1 | PASS | Label gelap di tombol ungu — tidak lazim |
| D | Naikkan ukuran font label ≥18.66px bold | 3:1 | PASS | TRequirement tipografi Choi: brand 14px |

**Rekomendasi: A** — tidak mengubah identitas brand (tetap ungu), hanya menggeser satu stop ke darker. Perlu update `void_palette.dart` (dark & light block) **dan** regenerate golden test.

### ⚠️ PASS-CONDITIONAL — 3.1.1 / 3.3.2 Error messaging

- Error validasi (`'Enter a valid email address.'`, `'Enter your password.'`) tampil sebagai teks inline di bawah field.
- **Bagus** : field sudah punya label visual `'Email'` / `'Password'` (3.3.2 PASS), dan pesan error adalah teks nyata (bukan hanya warna).
- **Kurang** : pesan error **tidak** dikaitkan secara semantik ke field-nya. Screen reader akan membacakan "Enter a valid email address." sebagai teks biasa, **tanpa** konteks "invalid, email field". Flutter menyediakan `Semantics(liveRegion: true)` untuk error form — pola ini **sudah dipakai** di baris 196 untuk error sign-in global, jadi konsisten dengan kode yang ada.

---

## 4. Kriteria yang LOLOS dan Perlu Dijaga

Beberapa praktik yang sudah benar dan jangan dikembalikan:

| Kriteria | Bukti di kode |
|---|---|
| **1.4.3** textPrimary | 16.3–18.2:1, jauh di atas ambang |
| **1.4.3** textMuted | 5.24–5.67:1 —Usage aman, banyak token grayscale terlalu gelap |
| **1.4.11** border (edge field) | 3.56–3.77:1 vs ambang 3:1 |
| **1.4.11** focus ring | 4.23–4.67:1 vs ambang 3:1 |
| **4.1.3** Status Messages | `Semantics(liveRegion: true)` di baris 196 untuk error sign-in |
| **1.1.1** Non-text Content | background dekoratif dibungkus `ExcludeSemantics` (baris 267, 374) |
| **2.1.1** Keyboard | `FocusNode` eksplisit + `textInputAction: TextInputAction.next` (email→password) + `done` (submit) |

---

## 5. Prioritas Remediasi

### Fase 1 — Blocker (harus)
1. **`primary` #8B5CF6 → #7C3AED** di `void_palette.dart` (dark & light). Menghapus 2 dari 2 kegagalan AA.
2. **Regenerate golden** : `flutter test --update-goldens test/features/authentication/login_screen_test.dart`
3. **Re-run gate** : `dart analyze` + `flutter test` suite authentication.

### Fase 2 — Serious (sebelum rilis)
4. **Link error ke field** via `Semantics(liveRegion: true)` di `TextFormField` validator output (konsisten dengan pola baris 196).

### Fase 3 — Nice to have
5. Audit sisa layar (register, account center, shell) dengan metode yang sama.
6. Verifikasi manual keyboard-only (2.1.1) & screen reader NVDA — bagian ini belum dilakukan di audit ini.

---

## 6. Batasan Audit Ini (jujur)

- **Konsentrasi pada kontras saja.** Kriteria seperti 1.3.1 Info & Relationships, 2.4.3 Focus Order, dan 4.1.2 Name/Role/Value di Flutter perlu pengujian runtime dengan screen reader, bukan bisa diselesaikan dari statis.
- **Nilai error color** diasumsikan dari default Material 3 (#FFB4AB dark / #B3261E light) karena `login_screen.dart` memakai `theme.colorScheme.error`, bukan token Void. Jika palet menentukan error sendiri, hitung ulang.
- **Tidak ada perubahan kode yang diterapkan.** Laporan ini audit-only; remediasi menunggu keputusan.


---

# LAMPIRAN A — Hasil Remediasi (Opsi A, diterapkan 2026-10-01)

## Yang Diubah

| File | Perubahan |
|---|---|
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.dark.primary` `#8B5CF6` → `#7C3AED` |
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.light.primary` `#8B5CF6` → `#7C3AED` |
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.light.primaryBright` `#7C3AED` → `#8B5CF6` (geser, agar hierarki terang↔kabut tetap) |
| `lib/design_system/colors/void_colors.dart` | `VoidColors.primary` `#8B5CF6` → `#7C3AED` (legacy const, kept in sync) |

Rollback salinan: `hermes cache/scratch/void_palette.dart.pre-wcag-20261001-004804`. HEAD saat remediasi: `afba22f`.

## Koreksi terhadap Laporan Awal

Dua angka di laporan awal **tidak benar** dan sudah dikoreksi:

1. **Rasio `#7C3AED` = 5.70:1, bukan 5.32:1.** Penyebab: kalkulator awal salah mengurai `0xFF7C3AED` — alpha `FF` diperlakukan sebagai komponen R, jadi warna jadi tak valid. Kalkulator sekarang Selbst-test terhadap 4 nilai WCAG resmi sebelum menghitung.
2. **Dark mode sudah PASS sejak awal (7.27:1).** `login_screen.dart:75-87` memakai `primaryBright` + foreground `background` di dark mode — bukan putih di atas `primary`. Yang gagal hanya **light mode** (putih di atas `#8B5CF6` = 4.23:1). Laporan awal salah menghitung dark mode memakai pasangan yang sama dengan light mode.

Konformitas Void Purple setelah remediasi: **16/16 PASS, 0 FAIL** (semua kriteria 1.4.3 & 1.4.11, kedua mode).

## Verifikasi (semua nyata)

| Gate | Hasil |
|---|---|
| `dart analyze` pada 2 file palet | **No issues found!** |
| `flutter test test/features/authentication/login_screen_test.dart` | **3/3 PASS** |
| `flutter test test/features/account/presentation/account_cloud_center_accessibility_test.dart` | **12/12 PASS** |
| `flutter test test/design_system/` | **15/15 PASS** |

### Catatan soal golden test

`login_screen_test.dart` merender **`ThemeData.dark()`** (baris 38). Perubahan ini hanya menyentuh `primary`, sementara dark mode memakai `primaryBright` yang **tidak diubah** — jadi golden **lolos tanpa regenerate**. Ini PASS yang sah, bukan false pass: tidak ada golden light-mode di repo, jadi tidak ada golden yang bisa gagal.

Test `void_theme_variant_test.dart` yang sudah ada ("SEMUA palet preset lulus kontras teks WCAG >=7:1 textPrimary") **tetap hijau**.

## Kendala teknis yang muncul

`flutter test test/design_system/` sempat gagal: *"Flutter failed to delete file at build/native_assets/windows/sqlite3.dll"*. Penyebab: **2 proses `flutter_tester.exe` yatim** (PID 17444, 17908) dari run sebelumnya memegang file. Setelah keduanya di-kill, delete berhasil dan test jalan normal. Ini pitfall yang berulang — perlu skill/script cleanup siap pakai.

---

# LAMPIRAN B — TEMUAN BARU: 5 preset aksen dark-mode gagal 1.4.3

## Fakta

`lib/design_system/widgets/void_button.dart:22-23` melukis:

```dart
backgroundColor: context.palette.primary,
foregroundColor: Colors.white,
```

**Tanpa cabang dark/light.** Artinya di seluruh aplikasi, label tombol filled = **putih di atas `palette.primary`**, termasuk saat pengguna memilih salah satu dari 6 preset aksen.

Preset `dark*` (darkInk, darkEmber, darkSage, darkRose, darkOcean) memakai **hue terang** — di atas background gelap, bukan di atas terang. White label di atasnya hampir tidak terbaca:

| Preset | `primary` | white/primary | Butuh | Defisit |
|---|---|---:|---:|---:|
| darkSage | `#7FB692` | 2.33 | 4.5 | 2.17 |
| darkRose | `#E38FB2` | 2.38 | 4.5 | 2.12 |
| darkEmber | `#F08A4B` | 2.49 | 4.5 | 2.01 |
| darkOcean | `#64A8E8` | 2.53 | 4.5 | 1.97 |
| darkInk | `#9A9FB8` | 2.62 | 4.5 | 1.88 |

Semua `light*` preset **lolos** (4.57–8.08:1).

##Skor agregat setelah Opsi A

```
21/26 PASS | 5 FAIL
```
Void Purple (default) kini **sempurna**. 5 kegagalan tersisa **semua di preset aksen**, bukan di default.

##なぜ belum diperbaiki

Ini **di luar Opsi A** yang kamu setujui (Opsi A hanya `primary` Void Purple). Perbaikannya adalah keputusan desain: untuk setiap hue terang, pilih salah satu —
- **(a) gelapkan `primary`** sehingga white label lolos → hue jadi lebih saturated, kehilangan kesan "pastel"
- **(b) ganti label jadi gelap** (`background` / near-black) per preset dark → butuh token `onPrimary` per preset
- **(c) jadikan `primaryBright` sebagai background tombol di dark mode** (pola yang sudah dipakai `login_screen.dart`) → konsisten dengan dark mode Void Purple, tapi butuh perubahan di `VoidButton`

Opsi **(c)** paling menarik: **menyamakan perilaku tombol dengan yang sudah working di dark mode Void Purple** (7.27:1), tanpa mengubah satu hue pun. Tapi menyentuh widget produksi, jadi perlu gate penuh.

## Alat audit (reusable)

Ditambahkan `skills/wcag-audit-patterns/scripts/contrast_audit.py` — menghitung rasio dari **nilai token literal** (bukan estimasi visual), dengan self-test wajib terhadap 4 nilai WCAG resmi sebelum melaporkan. Jalankan ulang kapan pun palet berubah:

```bash
cd ~/AppData/Local/hermes/skills/wcag-audit-patterns
python scripts/contrast_audit.py --selftest   # verifikasi matematika
python scripts/contrast_audit.py               # audit palet live
```
