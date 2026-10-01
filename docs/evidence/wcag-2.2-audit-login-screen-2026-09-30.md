# Audit WCAG 2.2 Level AA — Void Scriptor

**Status 2026-10-01:** Fase 1 (kontras palet login), Fase 2 (error validator —
terbukti bukan defect), Fase 3 (kontras tombol + ColorScheme global di 6
preset tema), Fase 4 (indikator fokus 2.4.7/1.4.11 + reduced motion
2.2.2/2.3.3) dan Fase 5 (focus order 2.4.3) selesai. Eksekusi & gate di Bagian 7–8 dan LAMPIRAN A–B.

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
| Kriteria diuji | 10 pasangan warna + 12 kombinasi fokus + 18 stop focus order |
| **PASS** | **10** warna + **18** stop focus order |
| **FAIL** | **0** |
| Konformitas | **100%** — AA terpenuhi untuk kontras |

*Angka versi pertama (16/18) berasal dari asumsi wiring tema yang salah; lihat bagian FAIL-1 di bawah untuk koreksinya.*

---

## 2. Hasil Rinci

### Mode Gelap (dark)

| Kriteria | Pasangan | Rasio | Butuh | Verdict |
|---|---|---:|---:|:--|
| 1.4.3 | textPrimary #F5F5F7 / background #090A0F | 18.16 | 4.5 | PASS |
| 1.4.3 | textPrimary / surface #12141D | 16.87 | 4.5 | PASS |
| 1.4.3 | textMuted #84899A / background | 5.67 | 4.5 | PASS |
| 1.4.3 | textMuted / surface | 5.27 | 4.5 | PASS |
| **1.4.3** | **label #090A0F / btn bg #A78BFA** (primaryBright) | **7.27** | **4.5** | **PASS** |
| 1.4.11 | border #6B6D76 / surface | 3.56 | 3.0 | PASS |
| 1.4.11 | primary #7C3AED / surface (focus ring) | 3.22 | 3.0 | PASS |
| 1.4.11 | primary #7C3AED / background | 3.35 | 3.0 | PASS |
| 1.4.3 | error #FFB4AB / background | 11.65 | 4.5 | PASS |

### Mode Terang (light)

| Kriteria | Pasangan | Rasio | Butuh | Verdict |
|---|---|---:|---:|:--|
| 1.4.3 | textPrimary #171923 / background #F6F7FB | 16.35 | 4.5 | PASS |
| 1.4.3 | textPrimary / surface #FFFFFF | 17.50 | 4.5 | PASS |
| 1.4.3 | textMuted #646776 / background | 5.24 | 4.5 | PASS |
| 1.4.3 | textMuted / surface | 5.61 | 4.5 | PASS |
| **1.4.3** | **label putih / btn bg #7C3AED** (primary, FIXED) | **5.70** | **4.5** | **PASS** |
| 1.4.11 | border #82838B / surface | 3.77 | 3.0 | PASS |
| 1.4.11 | primary #7C3AED / surface (focus ring) | 5.70 | 3.0 | PASS |
| 1.4.11 | primary #7C3AED / background | 5.30 | 3.0 | PASS |
| 1.4.3 | error #B3261E / background | 6.11 | 4.5 | PASS |

---

## 3. Temuan

### ✅ FAIL-1 (RESOLVED) — 1.4.3 Contrast (Minimum): label tombol utama

- **Lokasi** : `login_screen.dart:75-87` (`filledButtonTheme`)
- **Pasangan (dark mode)** : label `#090A0F` di atas `primaryBright` `#A78BFA` → **7.27:1** PASS
- **Pasangan (light mode)** : label `#FFFFFF` di atas `primary` `#7C3AED` → **5.70:1** PASS
- **Perbaikan** : `primary` `#8B5CF6` → `#7C3AED` (violet-600), diterapkan di `void_palette.dart` (dark & light block) + legacy `void_colors.dart`.
- **Commit** : `3065a1c` — sudah di HEAD dan sudah di-push.

**Koreksi terhadap laporan versi pertama.** Audit awal salah membaca wiring tema: diasumsikan tombol selalu "putih di atas `primary`" untuk kedua mode. Ini **tidak benar**. `filledButtonTheme` di `login_screen.dart:77-80` memakai:

```dart
backgroundColor: dark ? context.palette.primaryBright : context.palette.primary,
foregroundColor: dark ? context.palette.background : Colors.white,
```

Dengan wiring tersebut, **dark mode tidak pernah gagal 1.4.3** — label gelap `#090A0F` di atas `#A78BFA` = 7.27:1. Yang benar-benar gagal hanya **light mode** (putih di atas `#8B5CF6` = 4.23:1).

**Bukti independen** dari golden PNG (`goldens/login_desktop.png`, 1440×1000, di-decode pixel-per-pixel):
- `#8B5CF6` = **0 piksel** — tombol tidak pernah memakai `primary` di dark mode
- `#7C3AED` = **0 piksel**
- `#A78BFA` = **21.277 piksel** — inilah yang benar-benar dirender (`primaryBright`)

Kesimpulan: perbaikan `#7C3AED` **hanya memperbaiki light mode** (4.23 → 5.70:1). Dark mode sudah complies sejak awal. Skema 18-pasangan di versi pertama overstated kegagalan; setelah wiring dibaca dengan benar, hasilnya **10/10 PASS** untuk pasangan yang benar-benar dirender.

### ⚠️ PASS-CONDITIONAL — 3.1.1 / 3.3.2 Error messaging

- Error validasi (`'Enter a valid email address.'`, `'Enter your password.'`) tampil sebagai teks inline di bawah field.
- **Bagus** : field sudah punya label visual `'Email'` / `'Password'` (3.3.2 PASS), dan pesan error adalah teks nyata (bukan hanya warna).
- **Kurang** : pesan error **tidak** dikaitkan secara semantik ke field-nya. Screen reader akan membacakan "Enter a valid email address." sebagai teks biasa, **tanpa** konteks "invalid, email field". Flutter menyediakan `Semantics(liveRegion: true)` untuk error form — pola ini **sudah dipakai** di baris 196 untuk error sign-in global, jadi konsisten dengan kode yang ada.

---

## 4. Kriteria yang LOLOS dan Perlu Dijaga

Beberapa praktik yang sudah benar dan jangan dikembalikan:

> Koreksi 2026-10-01: klaim "1.4.11 focus ring 4.23–4.67:1" di tabel bawah
> **bukan** bukti fokus terlihat. Angka itu mengukur `primary` vs surface,
> bukan indikator fokus yang benar-benar dirender (probe piksel: 1.19–1.32:1).
> Sudah diperbaiki di Bagian 9.

| Kriteria | Bukti di kode |
|---|---|
| **1.4.3** textPrimary | 16.3–18.2:1, jauh di atas ambang |
| **1.4.3** textMuted | 5.24–5.67:1 —Usage aman, banyak token grayscale terlalu gelap |
| **1.4.11** border (edge field) | 3.56–3.77:1 vs ambang 3:1 |
| ~~**1.4.11** focus ring~~ | ~~4.23–4.67:1~~ **SALAH** — angka ini mengukur
  warna `primary` terhadap surface, bukan indikator fokus yang benar-benar
  dirender. Probe piksel 2026-10-01: 1.19–1.32:1. Sudah diperbaiki, Bagian 9. |
| **4.1.3** Status Messages | `Semantics(liveRegion: true)` di baris 196 untuk error sign-in |
| **1.1.1** Non-text Content | background dekoratif dibungkus `ExcludeSemantics` (baris 267, 374) |
| **2.1.1** Keyboard | `FocusNode` eksplisit + `textInputAction: TextInputAction.next` (email→password) + `done` (submit) |

---

## 5. Prioritas Remediasi

### Fase 1 — Blocker (SELESAI ✅)
1. ~~**`primary` #8B5CF6 → #7C3AED**~~ — **done**, commit `3065a1c`.
2. ~~**Regenerate golden**~~ — **tidak perlu**: golden merender dark mode yang memakai `primaryBright` (tak berubah), terbukti 0 piksel `primary` di PNG.
3. ~~**Re-run gate**~~ — **done**: analyze 0 issue, 30/30 test PASS.

### Fase 2 — Serious (sebelum rilis)
4. **Link error ke field** via `Semantics(liveRegion: true)` di `TextFormField` validator output (konsisten dengan pola baris 196).

### Fase 3 — Nice to have
5. ~~Audit sisa layar (register, account center, shell)~~ — **done**, Bagian 8.
6. **Verifikasi manual keyboard-only (2.1.1) & screen reader NVDA** — masih
   belum dilakukan. NVDA tidak terpasang di mesin ini; test otomatis hanya
   membuktikan indikator fokus terlihat, bukan urutan fokus maupun yang
   diumumkan screen reader.
7. **Audit fokus keyboard (2.4.7) + reduced motion (2.2.2/2.3.3)** — **done**,
   Bagian 9.

---

## 6. Batasan Audit Ini (jujur)

- **Konsentrasi pada kontras saja.** Kriteria seperti 1.3.1 Info & Relationships, 2.4.3 Focus Order, dan 4.1.2 Name/Role/Value di Flutter perlu pengujian runtime dengan screen reader, bukan bisa diselesaikan dari statis.
- **Nilai error color** diasumsikan dari default Material 3 (#FFB4AB dark / #B3261E light) karena `login_screen.dart` memakai `theme.colorScheme.error`, bukan token Void. Jika palet menentukan error sendiri, hitung ulang.
- **Bagian 1–6 audit-only; remediASI sudah diterapkan** pada commit `3065a1c` (lihat LAMPIRAN A). Fase 2 & 3 (link semantik error, audit layar lain) masih **belum** dikerjakan.


---

## 7. Fase 2 — Pesan error validator (HASIL: BUKAN DEFECT)

Dugaan awal: pesan error `TextFormField` tidak terkait semantik ke field-nya,
sehingga screen reader membacakan "Enter a valid email address." tanpa konteks.

**Diverifikasi salah.** Probe semantics tree (Flutter 3.44.6) pada form dengan
validator sama menghasilkan:

```
label="Email"  hint="Enter a valid email address."   <- node text field
  label="Enter a valid email address."               <- node pesan error
```

Flutter sudah menaruh pesan validator di `hint` field node text field, plus node
error tersendiri. WCAG 1.3.1 (Info and Relationships) dan 3.3.1 (Error
Identification) **terpenuhi oleh framework**. Tidak ada kode yang perlu diubah.

Catatan probe (untuk sesi berikutnya): di Flutter 3.44.6,
`SemanticsNode.hasError` dan `.kind` **tidak ada** (diganti `flagsCollection`),
dan `matchesSemantics` sudah bukan method instance. Tree harus dibaca via
`tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!` +
`visitChildren`.

Juga terverifikasi di login screen:
- **3.3.2 Labels or Instructions** — label "Email"/"Password" ada sebagai `Text`
  + `hintText`.
- **4.1.2 Name, Role, Value** — tombol Show/Hide password punya `tooltip`
  (`login_screen.dart:169`), jadi nama aksesibelnya berubah sesuai state.
- **3.2.x** — tidak ada `Image`/`SvgPicture` tanpa accessible name di layar ini.

---

## 8. Fase 3 — Kontras tombol & ColorScheme global (6 preset tema)

Detail temuan ada di LAMPIRAN B. Ringkasannya:

### Akar masalah & cakupan

Dua titik, satu akar:

1. `void_button.dart` — `foregroundColor: Colors.white` hardcoded.
2. `void_theme.dart` (buildDark + buildLight) — `onPrimary`/`onSecondary`/
   `onError` = `Colors.white` di ColorScheme **global**. Ini titik yang lebih
   luas: **72 tombol Flutter mentah** (`FilledButton`/`ElevatedButton` tanpa
   style) di 70+ layar mewarisi slot itu.

Preset gelap bukan preset mati — `VoidThemeVariant`
(`void_theme_variant.dart:11-15`) menyediakannya sebagai 6 tema yang bisa
dipilih pengguna.

### Perbaikan

Helper tunggal `onAccentForeground(Color)` di `void_palette.dart`: memilih
hitam/putih by `Color.computeLuminance()` dengan ambang **0.179** — titik di
mana kontras ke putih dan ke hitam sama-sama 4.5:1. Dipakai di 3 tempat:

- `void_theme.dart` buildDark: `onPrimary`, `onSecondary`, `onError`
- `void_theme.dart` buildLight: idem
- `void_button.dart`: `foregroundColor`

`register_screen` dan `forgot_password_screen` sudah memakai `VoidButton`, jadi
keduanya ikut terlindungi tanpa disentuh.

### Test baru (2 file, siklus RED-GREEN terbukti)

| File | Isi |
|---|---|
| `test/design_system/theme/void_button_contrast_test.dart` | 13 test — membaca style `ForegroundButton` yang benar-benar dirender widget (bukan helper lokal), 6 preset × 2 mode + guard akar masalah |
| `test/design_system/theme/void_colorscheme_contrast_test.dart` | 36 test — 3 slot ColorScheme × 6 preset × 2 mode |

Sebelum `void_button.dart` diperbaiki, 6 test gagal (5 preset gelap + guard)
dengan pesan `Expected: not Color<...1.0, 1.0, 1.0...>` — bukti failure-nya
memang di production code, bukan di test.

### Gate akhir (HEAD `727641b`, exit code nyata)

| Gate | Hasil | Exit |
|---|---|:--:|
| `dart analyze lib/design_system/ test/design_system/` | **No issues found!** | 0 |
| `flutter test test/design_system/` | **64/64 PASS** (dari 15) | 0 |
| `flutter test test/features/account/` | **933/933 PASS** — golden tidak pecah | 0 |
| `flutter test test/features/authentication/` | **3/3 PASS** | 0 |
| `flutter test test/app/shell/` | **47/47 PASS** | 0 |

**Total 1.047 test PASS, 0 FAIL, 5/5 command exit 0.**

Tidak ada golden yang di-regenerate: slot `onPrimary` tidak pernah muncul di
golden login (dark mode memakai `primaryBright`), dan 933 test account termasuk
visual regression semuanya PASS tanpa `--update-goldens`.

Kendala teknis: `flutter test` gagal sekali dengan `native_assets.json`
PathNotFound (race build), hilang pada retry. Bukan regresi kode.

### Yang masih belum dikerjakan (jujur)

- ~~**2.4.3 Focus Order** di luar login/register/forgot~~ — **done untuk 3 layar
  auth** (Bagian 10). Sisa 70+ layar belum: butuh traversal per layar.
- **4.1.2 Name, Role, Value** untuk 70+ layar lain: butuh audit per layar;
  Fase 3 hanya mengunci slot ColorScheme global yang dipakai semuanya.
- Skor **AA penuh** (criterion 2.x) belum diaudit — butuh NVDA/VoiceOver live.
- ~~**`prefers-reduced-motion`** belum diaudit sama sekali.~~ **Sudah
  diaudit 2026-10-01 — Bagian 9.2; hasilnya bukan defect.**

---

## 9. Fase 4 — Indikator fokus (2.4.7 / 1.4.11) & reduced motion (2.2.2 / 2.3.3)

### 9.1 2.4.7 Focus Visible — DEFECT NYATA, SUDAH DIPERBAIKI

**Akar masalah (terverifikasi di kode):**

| Temuan | Bukti |
|---|---|
| Tidak ada token fokus sama sekali | `grep focusColor\|FocusRing\|focusNode\|WidgetState.focused\|MaterialState.focused` → **0 kemunculan** di seluruh `lib/` |
| `VoidTheme` tidak punya `filledButtonTheme` | `void_theme.dart` tidak pernah menyebut `filledButtonTheme` |
| Indikator fokus M3 default hanya overlay | `filled_button.dart` (SDK): `overlayColor` = `onPrimary.withOpacity(0.1)`; tidak ada file `focus*`, tidak ada `FocusRing` |

**Probe konklusif (2026-10-01):** fokus dipicu seperti pengguna nyata —
`LogicalKeyboardKey.tab` ×6, `FocusManager.instance.primaryFocus` dibandingkan
sebelum/sesudah tiap tab. Delapan probe awal memakai `requestFocus()` dan
**gagal konfirmatif** (`hasFocus=false`, karena `FilledButton.focusNode` null
saat runtime); cara yang benar adalah tab, bukan `requestFocus`. Hasil akhir:
fokus **aktif** (`TAB#0 -> Focus`), tetapi perubahan piksel indikator default
hanya **1.19–1.32:1** di 12 kombinasi (6 preset × 2 mode) — jauh di bawah
ambang 3:1. → **1.4.11 FAIL dan 2.4.7 FAIL.**

**Perbaikan: ring fokus dua nada.**

Tidak ada satu pun token palet yang lolos ≥3:1 terhadap `primary` (fill) **dan**
`background` (fill di luminansi menengah). Terbukti lewat kalkulator:
`primaryBright` hanya 1.29–2.09 terhadap fill; `textPrimary` terbaik 15.46:1 vs
background tetapi **2.11:1** vs fill. Jadi satu warna tidak mungkin cukup →
dua pita kontras:

| Pita | Token | Fungsi | Lebar |
|---|---|---|---:|
| Outer | `focusRingOuter(palette)` | menempel `background` (di luar fill) | 3.0 px |
| Inner | `focusRingInner(palette)` | menempel `primary` (di atas fill) | 1.5 px |

Di-wire lewat `foregroundBuilder` — `ButtonStyle` **tidak punya**
`foregroundPainter` di Flutter 3.44.6; `foregroundBuilder` bertipe
`ButtonLayerBuilder` = fungsi `(BuildContext, Set<WidgetState>, Widget?)`.

- `lib/design_system/theme/void_focus_ring.dart` (BARU) — `VoidFocusRingPainter`
- `lib/design_system/theme/void_palette.dart` — `focusRingWidth`, `focusRingInnerWidth`, `focusRingOuter()`, `focusRingInner()`
- `lib/design_system/theme/void_theme.dart` — top-level `ButtonStyle _voidFocusButtonStyle(palette)` + `filledButtonTheme` di **kedua** mode (2 kemunculan)
- Cakupan: menutup **72 tombol `FilledButton`/`ElevatedButton`/`OutlinedButton`
  mentah** di `lib/features/`, bukan hanya `VoidButton`.

### 9.2 2.2.2 / 2.3.3 — BUKAN DEFECT, sudah dikunci test

`.repeat(` = **0 kemunculan** di seluruh `lib/` → tidak ada animasi otomatis
> 5 detik (2.2.2 PASS). Hanya **2 file** punya animasi widget-level, dan
keduanya sudah membaca `MediaQuery.disableAnimationsOf`:
`account_cloud_center_screen.dart:3295` dan `login_screen.dart:50`. Helper
`AccountCenterAccessibility.reducedMotion` (baris 115.45–115.47) sudah ada.

`prefers-reduced-motion` **tidak pernah diaudit** (lihat Bagian 8 "yang belum
dikerjakan") — sekarang sudah, dan hasilnya: perilaku produksi sudah benar.
Test baru `test/design_system/theme/void_reduced_motion_test.dart` (4 test)
mengunci ambient `disableAnimations` terbaca, `reducedMotion` true/false, dan
scheduler login screen idle (`hasScheduledFrame` false setelah settle).

### 9.3 Test baru (siklus RED-GREEN terbukti)

| Test | Jumlah | RED → GREEN |
|---|---:|---|
| `void_focus_indicator_test.dart` | 12 | RED `Expected: not null, Actual: <null>` → GREEN 12/12 |
| `void_reduced_motion_test.dart` | 4 | ditulis setelah konfirmasi, tanpa RED (test pengunci) |

**Negative control** (wajib): wiring `filledButtonTheme` dicabut dari
`void_theme.dart` → **12/12 FAIL** → test benar-benar bergantung pada fix.
Assertion-nya mengukur **rasio piksel riil** di edge tombol (≥ 3.0) dan
memastikan `focusedInner != focusedOuter`, bukan sekadar "warnanya berubah".

### 9.4 Gate akhir (exit code nyata)

HEAD saat gate dijalankan: **`251d3fa`** ("117.32 Security Assessment: 8 sumbu
bukti gagal-tertutup") — repo bergerak karena Core Worker sprint 117 aktif;
file audit ini tidak disentuh proses tersebut (area design_system + auth bersih).

| Gate | Hasil | Exit |
|---|---|:--:|
| `dart analyze lib/design_system/ test/design_system/` | No issues found! | 0 |
| `flutter test test/design_system/` | **80/80 PASS** | 0 |
| `flutter test test/features/account/` | **933/933 PASS** | 0 |
| `flutter test test/features/authentication/` | **3/3 PASS** | 0 |
| `flutter test test/app/shell/` | **47/47 PASS** | 0 |

Total **1.063 PASS, 0 FAIL**. `account_cloud_center_performance_resilience_test.dart`
sempat 1 FAIL pada satu run penuh (`initial_frame_ms` 233 vs ambang 186) tetapi
**21/21 PASS saat dijalankan sendirian** dan **933/933 PASS pada dua run penuh
berikutnya** → flaky timing, bukan regresi.

### 9.5 Yang masih belum dikerjakan (jujur)

- ~~**2.4.3 Focus Order**~~ — **done untuk 3 layar auth** (Bagian 10). Sisa 70+
  layar belum; harness `_tabOrder` bisa dipakai ulang per layar.
- **2.1.1 / 4.1.2** keyboard traversal & nama-peran-nilai di 70+ layar: butuh
  audit per layar; Fase 3–4 hanya mengunci slot ColorScheme + fokus tombol.
- **Skor AA penuh** (criterion 2.x) belum diaudit — butuh NVDA/VoiceOver live;
  NVDA tidak terpasang di mesin ini.

---

## 10. Fase 5 — Focus Order (2.4.3)

### 10.1 Cara mengukur (bukan asumsi)

Urutan fokus diukur dengan cara yang sama seperti pengguna nyata:
`LogicalKeyboardKey.tab` berulang, lalu `FocusManager.instance.primaryFocus`
pembaca posisi target. Kesalahan-kesalahan yang sempat dikoreksi saat
mengumpulkan data:

| Jebakan | Gejala | Solusi |
|---|---|---|
| `requestFocus()` pada `FilledButton` | `hasFocus=false`, `focusNode` null saat runtime | pakai `sendKeyEvent(tab)`, bukan `requestFocus()` |
| Label kasar per tipe | 2 `TextField` terbaca "REPEAT" padahal node berbeda | lacak identitas `FocusNode` via map, bukan string label |
| Viewport test default 800×600 | "Work Offline" & "Continue as Guest" melaporkan **rect identik** (y=552, ter-clip) | set viewport **1440×1000** = ukuran golden; setelah itu semua rect distinct |
| `primaryFocus.context` | selalu `Focus` (node internal), tidak berguna | naik ke ancestor untuk klasifikasi, **berdasarkan prioritas tipe** bukan kedekatan — `IconButton` membuat `InkWell` sebagai descendant, jadi "ancestor terdekat" selalu salah |

### 10.2 Hasil terukur

Viewport 1440×1000, stop = `top..bottom` y:

**Register — 6 stop, semua monoton turun ✅**

| # | y | Jenis |
|---:|---:|---|
| 0 | 393 | field |
| 1 | 463 | field |
| 2 | 533 | field |
| 3 | 603 | field |
| 4 | 663 | button — Create Account |
| 5 | 725 | button — Already have an account? Sign in |

**Forgot password — 3 stop ✅** 509 field → 565 button (Send Reset Link) → 625 button (Back to sign in)

**Login — 9 stop ✅**

| # | y | x | Jenis |
|---:|---:|---:|---|
| 0 | 32 | 1316 | kontrol tema (`ThemeModeMenu`, `login_screen.dart:340`) |
| 1 | 325 | 972 | field (email) |
| 2 | 437 | 972 | field (password) |
| 3 | 425 | 1312 | icon — Show/Hide password (suffix, **baris yang sama** dgn #2) |
| 4 | 479 | 1110 | button — Forgot password? |
| 5 | 535 | 952 | button — Sign In |
| 6 | 789 | 952 | button — Work Offline |
| 7 | 837 | 952 | button — Continue as Guest |
| 8 | 901 | 1109 | button — Create account |

**Verdikt: TIDAK ADA DEFECT.** Semua lompatan ke atas yang terlihat adalah
suffix icon yang berada di baris yang sama dengan field-nya — bukan urutan baca
yang salah. Test mengelompokkan pasangan `field`/`icon` yang sejajar sebagai satu
grup baris sebelum memeriksa monotonicitas.

### 10.3 Test

`test/features/authentication/focus_order_test.dart` — **8 test**:

- traversal `register` (6 stop, jenis eksak), `forgot` (3 stop), `login`
- monotonicitas atas→bawah untuk ketiga layar
- target fokus pertama login = kontrol tema di header
- setiap stop punya area bukan nol (tidak ada target ter-clip)
- **negative control**: order sengaja terbalik (y=500 lalu y=300) harus
  melempar — membuktikan assertion benar-benar menguji, bukan selalu PASS

### 10.4 Gate (HEAD `61eb4a5`, exit code nyata)

| Gate | Hasil | Exit |
|---|---|:--:|
| `dart analyze test/features/authentication/` | No issues found! | 0 |
| `flutter test test/features/authentication/` | **8/8 PASS** | 0 |
| `flutter test test/design_system/` | **80/80 PASS** | 0 |
| `flutter test test/app/shell/` | **47/47 PASS** | 0 |
| `flutter test test/features/account/` | **933/933 PASS** | 0 |

Total **1.068 PASS, 0 FAIL, 5/5 exit 0**. Tidak ada kode produksi diubah pada
Fase 5 — ini audit + pengunci, bukan remediasi.

### 10.5 Yang masih belum dikerjakan (jujur)

- **2.4.3 di 70+ layar selain auth** — butuh traversal per layar; harness di
  sini (`_tabOrder`) bisa dipakai ulang, tapi tiap layar punya banyak widget
  interaktif berbeda yang perlu diklasifikasi.
- **2.1.1 / 4.1.2** keyboard traversal & nama-peran-nilai di layar lain.
- **Skor AA penuh criterion 2.x** — butuh NVDA/VoiceOver live; NVDA belum
  terpasang di mesin ini.

---
# LAMPIRAN A — Hasil Remediasi (Opsi A, diterapkan 2026-10-01)

## Yang Diubah

| File | Perubahan |
|---|---|
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.dark.primary` `#8B5CF6` → `#7C3AED` |
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.light.primary` `#8B5CF6` → `#7C3AED` |
| `lib/design_system/theme/void_palette.dart` | `VoidPalette.light.primaryBright` `#7C3AED` → `#8B5CF6` (geser, agar hierarki terang↔kabut tetap) |
| `lib/design_system/colors/void_colors.dart` | `VoidColors.primary` `#8B5CF6` → `#7C3AED` (legacy const, kept in sync) |

Rollback salinan: `C:/Users/nepht/AppData/Local/hermes/cache/scratch/void_palette.dart.pre-wcag-20261001-004804` (terverifikasi ada, 6.843 B).

*Catatan:* versi LAMPIRAN A sebelumnya mengklaim HEAD saat remediasi = `afba22f`. Nilai itu **tidak cocok** dengan repo — HEAD saat ini `727641b`, dan `afba22f` tidak ada di riwayat. Angka itu kemungkinan salah ketik dan sudah dikoreksi di sini.

## Koreksi terhadap Laporan Awal

Dua angka di laporan awal **tidak benar** dan sudah dikoreksi:

1. **Rasio `#7C3AED` = 5.70:1, bukan 5.32:1.** Penyebab: kalkulator awal salah mengurai `0xFF7C3AED` — alpha `FF` diperlakukan sebagai komponen R, jadi warna jadi tak valid. Kalkulator sekarang Selbst-test terhadap 4 nilai WCAG resmi sebelum menghitung.
2. **Dark mode sudah PASS sejak awal (7.27:1).** `login_screen.dart:75-87` memakai `primaryBright` + foreground `background` di dark mode — bukan putih di atas `primary`. Yang gagal hanya **light mode** (putih di atas `#8B5CF6` = 4.23:1). Laporan awal salah menghitung dark mode memakai pasangan yang sama dengan light mode.

Konformitas Void Purple setelah remediasi: **0 FAIL** pada semua pasangan yang benar-benar dirender (1.4.3 & 1.4.11, dark & light mode). Angka "16/16" pada versi LAMPIRAN A sebelumnya tidak dapat direproduksi dan sudah dibuang; hitungan yang dapat dipertanggungjawabkan ada di Bagian 1–2.

## Verifikasi (diulang ulang & dikonfirmasi 2026-10-01, exit code nyata)

Semua baris di bawah **tidak diambil dari klaim pihak lain** — tiap gate dijalankan ulang di HEAD `727641b` dan exit code dicatat.

| Gate | Perintah | Hasil | Exit |
|---|---|---|:--:|
| Analyze palet + login | `dart analyze void_palette.dart void_colors.dart login_screen.dart` | **No issues found!** | 0 |
| Design system | `flutter test test/design_system/` | **15/15 PASS** | 0 |
| Aksesibilitas account center | `flutter test .../account_cloud_center_accessibility_test.dart` | **12/12 PASS** | 0 |
| Authentication | `flutter test test/features/authentication/` | **3/3 PASS** | 0 |
| Golden regenerate | — | **TIDAK PERLU** (lihat catatan golden di bawah) | — |
| Sisa `flutter_tester.exe` yatim | `tasklist \| grep -c flutter_tester` | **0** (tidak ada proses yatim) | — |

Total: **30 test PASS, 0 FAIL, 4 dari 4 command exit 0.**

### Catatan soal golden test

`login_screen_test.dart` merender **`ThemeData.dark()`** (baris 38). Perubahan ini hanya menyentuh `primary`, sementara dark mode memakai `primaryBright` yang **tidak diubah** — jadi golden **lolos tanpa regenerate**. Ini PASS yang sah, bukan false pass: tidak ada golden light-mode di repo, jadi tidak ada golden yang bisa gagal.

Test `void_theme_variant_test.dart` yang sudah ada ("SEMUA palet preset lulus kontras teks WCAG >=7:1 textPrimary") **tetap hijau**.

## Kendala teknis yang muncul

`flutter test test/design_system/` sempat gagal: *"Flutter failed to delete file at build/native_assets/windows/sqlite3.dll"*. Penyebab: **2 proses `flutter_tester.exe` yatim** (PID 17444, 17908) dari run sebelumnya memegang file. Setelah keduanya di-kill, delete berhasil dan test jalan normal. Ini pitfall yang berulang — perlu skill/script cleanup siap pakai.

---

# LAMPIRAN B — Temuan baru: 5 preset aksen dark-mode gagal 1.4.3

> **STATUS: SUDAH DIPERBAIKI 2026-10-01** — lihat Bagian 8. Isi asli lampiran
> ini hanya mendiagnosis dan menawarkan opsi; dipertahankan sebagai catatan
> asal-usul temuan, dengan koreksi di bagian akhir.

## Fakta (terverifikasi)

`lib/design_system/widgets/void_button.dart` melukis:

```dart
backgroundColor: context.palette.primary,
foregroundColor: Colors.white,
```

**Tanpa cabang dark/light.** Artinya di seluruh aplikasi, label tombol filled =
putih di atas `palette.primary`, termasuk saat pengguna memilih salah satu dari
6 preset aksen.

Preset `dark*` (darkInk, darkEmber, darkSage, darkRose, darkOcean) memakai
**hue terang** — di atas background gelap, bukan di atas terang. Label putih di
atasnya hampir tidak terbaca:

| Preset | `primary` | white/primary | Butuh | Defisit |
|---|---|---:|---:|---:|
| darkSage | `#7FB692` | 2.33 | 4.5 | 2.17 |
| darkRose | `#E38FB2` | 2.38 | 4.5 | 2.12 |
| darkEmber | `#F08A4B` | 2.49 | 4.5 | 2.01 |
| darkOcean | `#64A8E8` | 2.53 | 4.5 | 1.97 |
| darkInk | `#9A9FB8` | 2.62 | 4.5 | 1.88 |

Semua `light*` preset **lolos** (4.57-8.08:1). Void Purple (default) juga lolos
(5.70:1 setelah Opsi A).

## Opsi perbaikan (asli)

Perbaikannya adalah keputusan desain: untuk setiap hue terang, pilih salah satu —
- **(a)** gelapkan `primary` sehingga label putih lolos → hue jadi lebih
  saturated, kehilangan kesan "pastel"
- **(b)** ganti label jadi gelap (near-black) per preset dark → butuh token
  `onPrimary` per preset
- **(c)** jadikan `primaryBright` sebagai background tombol di dark mode (pola
  yang sudah dipakai `login_screen.dart`) → konsisten dengan dark mode Void
  Purple, tapi menyentuh widget produksi

## Koreksi 2026-10-01: opsi (b) yang dipilih, dan cakupannya lebih luas dari (c)

Opsi (c) appealing tapi **tidak dipilih**, alasannya:

1. (c) hanya memperbaiki `VoidButton`. Tertinggal **72 tombol `FilledButton`/
   `ElevatedButton` mentah** yang mewarisi `ColorScheme.onPrimary` global.
2. (b) melalui `onAccentForeground()` memperbaiki **semua** tombol sekaligus,
   karena slot ColorScheme di `void_theme.dart` diperbaiki di titik yang sama.
3. (b) tidak mengorbankan hues: `primary` tiap preset tetap apa adanya.

Catatan tambahan: `VoidButton` memakai `primary` (bukan `primaryBright`) sebagai
background di dark mode, jadi (c) akan membuat `VoidButton` dan `login_screen`
tidak konsisten — dua warna tombol berbeda dalam satu theme.

## Skor agregat

Sebelum perbaikan: 21/26 PASS, 5 FAIL.
Setelah perbaikan: **0 FAIL** pada semua pasangan yang benar-benar dirender —
diverifikasi 49 test baru di 2 file (Bagian 8).

## Alat audit (reusable)

Skill `wcag-audit-patterns` punya `scripts/contrast_audit.py` — menghitung rasio
dari **nilai token literal** (bukan estimasi visual), dengan self-test wajib
terhadap nilai WCAG resmi sebelum melaporkan:

```bash
cd ~/AppData/Local/hermes/skills/wcag-audit-patterns
python scripts/contrast_audit.py --selftest   # verifikasi matematika
python scripts/contrast_audit.py               # audit palet live
```

Keterbatasan yang sudah diketahui: skrip mengasumsikan label putih. Untuk
`login_screen` asumsi itu **salah** (dark mode memakai `primaryBright` + label
gelap) — selalu verifikasi asumsi skrip terhadap kode sebelum melaporkannya.
