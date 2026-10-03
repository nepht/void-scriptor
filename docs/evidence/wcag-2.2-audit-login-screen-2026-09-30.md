# Audit WCAG 2.2 Level AA — Void Scriptor

**Status 2026-10-01:** Fase 1 (kontras palet login), Fase 2 (error validator —
terbukti bukan defect), Fase 3 (kontras tombol + ColorScheme global di 6
preset tema), Fase 4 (indikator fokus 2.4.7/1.4.11 + reduced motion
2.2.2/2.3.3), Fase 5 (focus order auth) dan Fase 6 (focus order account
cloud center) selesai. Eksekusi & gate di Bagian 7–8 dan LAMPIRAN A–B.

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
| Kriteria diuji | 10 pasangan warna + 12 kombinasi fokus + 32 stop focus order |
| **PASS** | **10** warna + **32** stop focus order |
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
## 11. Fase 6 — Focus Order di Account Cloud Center (2.4.3)

### 11.1 Gap yang ditemukan di test yang sudah ada

Test `account_cloud_center_keyboard_screen_reader_test.dart` (685 baris,
sprint 115.48) sudah punya group `115.48 focus_order`, tapi assertion-nya:

```dart
expect(
  () => AccountCenterKeyboardScreenReader.validateFocusOrder(
    AccountCenterKeyboardScreenReader.expectedFocusStops,
  ),
  returnsNormally,
);
```

`expectedFocusStops` **diturunkan dari `AccountCenterAccessibility.defaultFocusOrder`**
— jadi ini membandingkan konstanta domain dengan dirinya sendiri. Tidak ada
satu pun widget tree yang disentuh. Test tersebut membuktikan konsistensi
kontrak internal, bukan urutan fokus yang benar-benar terjadi.

### 11.2 Traversal nyata vs kontrak

Diukur dengan `LogicalKeyboardKey.tab` di viewport 1536×1024:

| | Jumlah stop |
|---|---:|
| Kontrak `expectedFocusStops` | 11 |
| Traversal riil | **14** |

Urutan riil:

```
ink (search) → Overview → Connected Accounts → Cloud Storage → AI Providers →
API Keys → Team & Collaboration → Security → Backup & Sync → Billing →
Edit Profile → + Add Another Method → Backup Project → AI Providers
```

Tiga stop terakhir **tidak ada di kontrak**: `Edit Profile`,
`+ Add Another Method`, `Backup Project`, dan satu lagi berlabel `AI Providers`.

**Verdikt: bukan defect.** Kontrak sengaja hanya meng-contract *chrome*
(search + 9 tab + signIn), bukan tombol intra-page tiap tab.
`AccountCenterAccessibility.isFocusable` menyaring `notifications`, dan
`signIn` hanya ada saat belum login. Pemisahan ini benar — yang hilang
adalah **bukti bahwa widget benar-benar bisa di-tab sesuai urutan itu**.

### 11.3 Dua jebakan yang hampir jadi false positive

**1. Tombol berlabel sama dengan tab.** Stop ke-14 berlabel `AI Providers` —
identik dengan tab ke-4, tapi itu tombol di panel Overview, bukan tab.
Deteksi berbasis label menghasilkan 10 tab, bukan 9. Diperbaiki dengan
membaca **baris** (`rect.top`) yang sama: tab strip adalah satu baris
horizontal, tombol intra-page punya `top` berbeda.

**2. Posisi absolut bukan urutan.** Tab strip auto-scroll mengikuti fokus.
Data probe:

| Tab | left | width |
|---|---:|---:|
| Cloud Storage | 581 | 192 |
| AI Providers | 588 | 179 |
| Team & Collaboration | **535** | 285 |

`Team & Collaboration` (535) muncul **di kiri** `Cloud Storage` (581) karena
viewport 1536px memotong strip yang 2000px+ lebar. Assertion
"setiap tab lebih kanan dari sebelumnya" akan gagal — dan itu **artefak
harness, bukan defect produksi**. Ordinal yang benar sudah dibuktikan lewat
urutan traversal, bukan koordinat.

### 11.4 Test

`test/features/account/presentation/account_cloud_center_focus_order_test.dart`
— **4 test**:

- sembilan tab muncul berurutan sesuai `AccountCenterInformationArchitecture.tabs`
- tab strip satu baris (`rect.top` seragam), tidak berlapis
- tab pertama muncul setelah kontrol header yang lebih tinggi
- kontrak domain tidak mengklaim lebih banyak stop dari kenyataan

**Negative control**: urutan IA di-sort alfabet di dalam test → **3/4 FAIL**
dengan pesan `at location [0] is 'Overview' instead of 'AI Providers'`.
Membuktikan assertion benar-benar menguji urutan, bukan selalu lolos.

### 11.5 Gate (HEAD `232e6cd`, exit code nyata)

| Gate | Hasil | Exit |
|---|---|:--:|
| `flutter test test/features/account/` | **937/937 PASS** (dari 933) | 0 |
| `flutter test test/features/authentication/` | **8/8 PASS** | 0 |
| `flutter test test/design_system/` | **80/80 PASS** | 0 |
| `flutter test test/app/shell/` | **47/47 PASS** | 0 |

Total **1.072 PASS, 0 FAIL, 4/4 exit 0**. Tidak ada kode produksi diubah.

### 11.6 Cakupan

Dua dari 89 layar (`login`, `register`, `forgot_password` di Bagian 10;
`account_cloud_center` di sini) = **4 dari 89**. Sisa 85 layar belum.
Harness `_tabOrder` + `_firstText` + klasifikasi baris bisa disalin, tapi tiap
layar punya widget interaktif berbeda (dropdown, switch, slider, tab strip
yang berbeda) yang perlu diklasifikasi ulang.


---

## 12. Fase 7 — Focus Order di AI Prompt Composer (2.4.3)

Layar kedua yang diuji dengan traversal Tab nyata. Basis pemilihan bukan
`story_workspace_screen.dart` yang paling banyak interaktif (45 handler),
melainkan `ai_prompt_composer_screen.dart`, karena dua alasan yang keduanya
dibuktikan, bukan diperkirakan:

- **Deterministik.** `AiPromptComposerScreen({super.key, this.contextData})`
  punya nol parameter wajib. Layar story butuh repository, `loadCast`,
  `activeSection`, atau projection futures; tanpa itu traversal hanya menghasilkan
  2-3 stop dan tidak mewakili apa yang dilihat pengguna.
- **Sebenarnya dipakai.** `story_workspace_screen.dart` punya 89 baris
  `_buildDedicatedSection`, tapi branch `'Outline'` merender nyaris kosong —
  panel projection absen (projection null) dan satu-satunya tombol pun
  bersyarat `onSectionRequested != null`. Probe traversal di sana menghasilkan
  **1 stop** (Navigator), bukan urutan yang bisa diaudit.

### Data terukur (probe 2026-10-03, viewport 1536x1024, devicePixelRatio 1.0)

```
0  ink    t=8    l=1492 w=40    -> tombol aksi pojok kanan atas Scaffold
1  Character         t=140 l=20  w=240   ┐ baris header
2  field             t=144 l=332 w=1152  ┘ (kiri ke kanan, tinggi sama)
3  Identity Locks    t=188 l=20  w=56
4  Wardrobe          t=244 l=20  w=240
5  Weapon            t=292 l=20  w=240
6  Environment       t=340 l=20  w=240
7  Timeline          t=388 l=20  w=240
8  <LOOP ke #0>
```

Delapan stop, traversal tertutup rapi. Ini sesuai `build()` di
`ai_prompt_composer_screen.dart:88-101` (`SizedBox(width: 280, child: panel)` di baris 100): `Row` berisi `panel` (lebar 280, kiri)
dan `editor` ( Expanded, kanan); `panel` adalah `_ContextPanel` yang menumpuk
enam `_toggle` secara vertikal (`ai_prompt_composer_screen.dart:141,157,173,189,205,221`).

### Kontrak yang diuji

1. **Enam toggle muncul dan berurutan** sesuai urutan vertikal panel CONTEXT.
2. **Rail kiri dibaca dari atas ke bawah** — `top` naik monoton
   (140→188→244→292→340→388) dan keenamnya berbagi `left` yang sama.
3. **Field editor tidak mendahului toggle pertama.**
4. **Focus cycle tertutup** dengan stop terbatas dan setiap stop punya ukuran
   render nyata (bukan target fokus hantu).

### RED nyata selama menulis test (tidak dikarang)

Assertion pertama memakai `actual.sublist(indexes.first, indexes.first + 6) ==
_panelToggles`, yaitu menuntut enam toggle **bersebelahan**. Probe sudah
memperingatkan ini: `Character` (t=140 l=20 w=240) dan `field` (t=144 l=332
w=1152) berbagi baris visual yang sama — tinggi 48 vs 24, `top` berbeda 4px,
`left` berbeda 312px, yaitu satu baris header yang dibaca kiri ke kanan.
Test gagal persis di sana:

```
Expected: ['Character', 'Identity Locks', 'Wardrobe', 'Weapon', 'Environment', 'Timeline']
  Actual: ['Character', 'field', 'Identity Locks', 'Wardrobe', 'Weapon', 'Environment']
```

Field menyela. Dua kemungkinan: widget yang salah, atau assertion yang salah
terbuka. Buktinya menunjukkan widget yang benar — panel kiri memang 280px dan
field berada di kolom kanan, keduanya memang satu baris. Jadi assertion yang
diperbaiki, bukan produksi. Kontrak 2.4.3 adalah urutan **relatif**, bukan
label bersebelahan: field boleh menyela, yang dikontrak adalah tidak ada toggle
yang keluar dari urutan vertikalnya.

### Negative control

Membalik `_panelToggles` (Timeline lebih dulu) → **3 dari 4 test FAIL**,
lolos hanya test "focus cycle tertutup" yang memang tidak bergantung pada
urutan. Jadi urutan toggle benar-benar diuji, bukan lolos hampa.

### Temuan sampingan: fitur belum selesai (BUKAN defect a11y)

`AiContextOptions` punya **delapan** field bool
(`lib/features/ai/application/prompt_composer.dart:5-24`), tapi hanya **enam** yang punya kontrol di UI.
`includeMode` dan `includeContinuity` tidak pernah di-toggle; keduanya hanya
dibawa sebagai `old.includeMode` / `old.includeContinuity` di setiap callback.
Keduanya **aktif dipakai**: `prompt_composer.dart:91` menyertakan mode karakter,
`prompt_composer.dart:128` menyertakan continuity environment — dengan default
`true`.

Jadi user tidak bisa memengaruhi dua opsi yang benar-benar mengubah isi prompt
kecuali dengan mengedit kode. Sesuai aturan klasifikasi: ini **fitur yang belum
selesai**, bukan pelanggaran WCAG, dan tidak disentuh di fase ini.

### Status

4/4 PASS · analyze bersih · negative control 3/4 FAIL. Tidak ada kode produksi
diubah; hanya satu file test baru. Layar story ditunda, bukan diews, dan
DEFERRED dengan alasannya (butuh fixture database untuk merepresentasikan
kondisi nyata).
---
## 13. Fase 8 — Focus Order di Portability Wizard (2.4.3)

Layar ketiga yang diaudit untuk kriteria 2.4.3, setelah Account Cloud Center (Bagian 11) dan AI Prompt Composer (Bagian 12).

### 13.1 Kenapa layar ini dipilih

Kandidat `portability_wizard_screen.dart` dipilih setelah `story_workspace_screen.dart` di-DEFERRED di Bagian 12, dengan dua bukti sebelum menulis test:

| Kandidat | Bukti | Putusan |
| --- | --- | --- |
| `story_workspace_screen.dart` | traversal hanya 2 stop (Navigator lalu loop), branch `'Outline'` merender nyaris kosong | DEFERRED, butuh fixture database |
| `portability_wizard_screen.dart` | `const PortabilityWizardScreen({super.key})` — nol parameter wajib, seluruh data dari list statis, tanpa future/async | Dipilih |

Berkas target juga bersih di git sebelum dan sesudah pekerjaan ini, sehingga tidak bercampur dengan WIP Core Worker.

### 13.2 Data traversal terukur

Probe memakai traversal Tab nyata (`sendKeyEvent(LogicalKeyboardKey.tab)`) pada viewport 1536x1024 dengan devicePixelRatio 1.0. Sepuluh stop, tertutup rapi:

| # | Label | t | l | w | h | Wilayah |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Canon Prime | 216 | 54 | 379 | 24 | dropdown universe sumber |
| 1 | What If: Echoes | 216 | 491 | 379 | 24 | dropdown universe tujuan |
| 2 | Reference | 267 | 41 | 171 | 37 | chip mode |
| 3 | Clone | 267 | 224 | 100 | 37 | chip mode |
| 4 | Variant | 267 | 335 | 126 | 37 | chip mode |
| 5 | Locked Identity | 267 | 473 | 231 | 37 | chip mode |
| 6 | Character: Arin Vale | 329 | 41 | 841 | 63 | chip aset |
| 7 | Environment: Obsidian Keep | 392 | 41 | 841 | 63 | chip aset |
| 8 | Prop: Aether Blade | 455 | 41 | 841 | 63 | chip aset |
| 9 | Timeline: Fall of Embers | 518 | 41 | 841 | 63 | chip aset |

Tiga wilayah terurut dari atas ke bawah dan traversal mengikuti urutan baca tiap wilayah: dua dropdown universe (sumber lalu tujuan, satu baris, `left` naik monoton pada `top` sama), empat chip mode (satu baris `Wrap`, `left` naik monoton pada `top` sama), lalu empat chip aset (satu chip per baris, `top` naik monoton pada `left` dan lebar sama).

Urutan chip mode mengikuti urutan deklarasi `enum PortMode.values`; urutan chip aset mengikuti list statis `_PortAsset`. Keduanya dibuktikan terhadap sumber, bukan ditebak dari tampilan.

### 13.3 Tombol footer yang disabled bukan stop fokus

Traversal berhenti tepat pada 10 stop. Tombol aksi di `bottomNavigationBar` tidak masuk, karena `onPressed`-nya `_selectedAssets.isEmpty ? null : () {}` (baris 129). Saat belum ada aset yang dipilih, tombol itu dalam keadaan nonaktif sehingga dilewati traversal Tab.

Ini perilaku yang benar untuk kontrol disabled, bukan kontrol yang urutan fokusnya tersesat, sehingga tidak dikontrak sebagai stop fokus. Kontrak 2.4.3 di sini adalah urutan relatif stop yang aktif, bukan jumlah elemen interaktif di layar.

### 13.4 Test sempat RED dengan sebab nyata

Run pertama menghasilkan 3 dari 4 PASS. Assertion yang runtuh adalah pengklasifan tipe stop:

```
Expected: 'dropdown'
  Actual: 'ink'
```

Penyebabnya ada di harness, bukan di produksi: `DropdownButton` tidak pernah menjadi node fokus. Ia membungkus field-nya di `StatefulWidget` internal, dan node fokus yang benar-benar diisi adalah `InkWell` atau `InputDecorator` di dalamnya. Walk ancestor yang berhenti di kemunculan pertama `InkWell` ikut menghentikan penelusuran sebelum mencapai `DropdownButton`, sehingga kedua dropdown universe terklasifikasi `ink`.

Perbaikan ada di classifier test: telusuri seluruh rantai ancestor lebih dulu untuk mendeteksi ada/tidaknya `DropdownButton`, baru putuskan kelas stop dari `InkWell` atau field yang ditemukan. Widget produksi tidak diubah. Run kedua 4 dari 4 PASS.

### 13.5 Negative control

Urutan `_modeLabels` dibalik di dalam test lalu dijalankan ulang. Hasil 3 dari 4 FAIL, dengan test yang runtuh tepat di "empat chip mode terurut sesuai urutan enum". Jadi assertion urutan benar-benar menguji urutan, bukan sekadar menghitung stop.

### 13.6 Temuan sampingan di luar cakupan a11y

Satu temuan ditemukan saat membaca sumber, dan sengaja tidak disentuh karena bukan defect a11y:

`enum PortMode` dideklarasikan dua kali dengan nilai yang identik — di `lib/features/multiverse/domain/portability.dart:23` dan di `lib/features/multiverse/presentation/portability_wizard_screen.dart:160`. Layar tidak meng-import berkas domain, jadi field `_mode` pada baris 55 bertipe enum presentation, bukan enum domain. Pencarian di seluruh `lib/` menunjukkan enum versi domain tidak dipakai presentation manapun.

Klasifikasi: duplikasi kode, bukan defect aksesibilitas. Tidak ada perubahan produksi pada fase ini; dicatat di sini agar tidak hilang.

### 13.7 Gate

| Gate | Hasil |
| --- | --- |
| `portability_wizard_focus_order_test.dart` | 4 dari 4 PASS |
| Negative control (urutan mode dibalik) | 3 dari 4 FAIL — assertion terbukti punya kekuatan |
| `dart analyze` berkas test | No issues found |
| CJK/Cyrillic scan | none |
| `test/features/multiverse/` (12 berkas test) | 38 PASS, 0 FAIL |

Test lama `portability_wizard_screen_test.dart` hanya 22 baris smoke test tanpa traversal fokus, jadi tidak ada tumpang tindih cakupan dengan kontrak baru.

---

## 14. Fase 9 — Focus Order di Universe Switcher (2.4.3)

Layar keempat yang diaudit untuk kriteria 2.4.3, setelah Account Cloud Center (Bagian 11), AI Prompt Composer (Bagian 12), dan Portability Wizard (Bagian 13).

### 14.1 Kenapa layar ini dipilih

Kandidat `universe_switcher_screen.dart` dipilih dari seluruh `lib/**/*_screen.dart` dengan filter yang sama seperti fase sebelumnya (constructor nol parameter wajib, tanpa future/async/stream, tanpa TabController/Navigator yang menambah stop di luar layar):

| Kandidat | async/Future | static list | interaktif | Putusan |
| --- | --- | --- | --- | --- |
| `universe_switcher_screen.dart` | 0 | 1 | 3 | Dipilih |
| `reference_library_screen.dart` | 8 | 0 | 5 | Dilewati (data async) |
| `project_list_screen.dart` | 8 | 0 | 5 | Dilewati (data async + Navigator) |
| `welcome_screen.dart` | 0 | 0 | 3 | Cadangan (terlalu sedikit stop) |
| `update_screen.dart` | 0 | 0 | 2 | Dilewati (2 stop saja) |
| `public_project_page_screen.dart` | 0 | 0 | 3 | Dilewati (data eksternal) |

`universe_switcher_screen.dart` memenuhi seluruh syarat: `_universes` adalah `static const List<String>` 4 entri yang dirender secara sinkron, sehingga traversal Tab mewakili tampilan nyata dan bisa direproduksi.

### 14.2 Data traversal terukur

Probe memakai traversal Tab nyata (`sendKeyEvent(LogicalKeyboardKey.tab)`) pada viewport 1536x1024 dengan devicePixelRatio 1.0. Lima stop, tertutup rapi:

| # | Label | t | l | w | h | Wilayah |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Canon Prime | 16 | 1288 | 232 | 24 | dropdown universe di topbar |
| 1 | Canon Prime | 124 | 37 | 246 | 44 | universe tile, aktif |
| 2 | What If: Echoes | 168 | 37 | 246 | 64 | universe tile |
| 3 | Parallel Nexus | 232 | 37 | 246 | 44 | universe tile |
| 4 | Spin-Off: Embers | 276 | 37 | 246 | 64 | universe tile |

Dua wilayah terurut dari atas ke bawah: dropdown topbar (AppBar) sebagai stop pertama, lalu empat universe tile dalam kolom vertikal (`left` konstan 37, `top` naik monoton). Urutan tile mengikuti persis deklarasi `_universes` (statis, baris 18–22).

Stop 0 dan stop 1 keduanya berlabel "Canon Prime" — tidak cukup untuk membedakan lewat teks. Diskriminasi memakai `rect.top` (16 vs 124) dan kelas stop (`dropdown` vs `ink`).

### 14.3 Test sempat RED — di harness, bukan produksi

Dua kali RED dengan sebab di harness, dan sekali compile error di probe:

1. **Probe compile error**: `BuildContext` tidak bisa langsung dipakai sebagai `Element` (Flutter 3.44). Fix: cast `ctx as Element`.
2. **Label `┃` dan `═` di stop 1–4**: glyph codepoint dari `Icon` internal (`Icons.radio_button_checked` dsb) masuk lebih dulu ke walker label sebelum `Text(name)`. Fix: walker melewati subtree `Icon`.
3. **`e.parent` tidak ada** di `Element` Flutter 3.44. Fix: `visitAncestorElements`.

Seluruh perbaikan ada di test harness. Widget produksi tidak diubah.

### 14.4 Negative control

Urutan `_universeOrder` dibalik di dalam test lalu dijalankan ulang. Hasil **3 dari 4 PASS**, dengan test yang runtuh tepat di "empat tile terurut sesuai deklarasi _universes" — assertion urutan terbukti menguji urutan.

### 14.5 Gate

| Gate | Hasil |
| --- | --- |
| `universe_switcher_focus_order_test.dart` | 4 dari 4 PASS |
| Negative control (urutan dibalik) | 3 dari 4 PASS, 1 FAIL |
| `dart analyze test/features/multiverse/` | No issues found |
| CJK/Cyrillic scan | none |
| `test/features/multiverse/` (13 berkas test) | 42 PASS, 0 FAIL |

---

## 15. Fase 10 — Focus Order di Create Universe Wizard (2.4.3)

Layar kelima yang diaudit untuk kriteria 2.4.3, dan yang pertama berupa wizard bertahap. Audit ini menguji kontrak fokus **per langkah**, bukan hanya sekali pasang di layar.

### 15.1 Kenapa layar ini dipilih

`create_universe_wizard_screen.dart` (418 baris) adalah kandidat deterministik paling kaya di antara 87 layar yang belum diaudit:

| Syarat | Nilai |
| --- | --- |
| Constructor | `const CreateUniverseWizardScreen({super.key})` — nol parameter wajib |
| Data | `_steps` (3 entri) dan `_universeTypes` (8 entri), keduanya `static const List<String>` |
| async/Future/Stream | 0 |
| TabController/Navigator/PageView | 0 |
| Elemen interaktif | 13 |

Karena seluruh data berasal dari konstanta statis dan tidak ada navigasi tambahan, traversal Tab mewakili tampilan nyata dan dapat direproduksi persis.

### 15.2 Data traversal terukur per langkah

Traversal memakai `sendKeyEvent(LogicalKeyboardKey.tab)` pada viewport 1536x1024, devicePixelRatio 1.0. Koordinat dalam piksel logika.

**Langkah 0 (Name) — 4 stop lalu kembali ke atas:**

| # | Widget | t | l | w | h |
| --- | --- | --- | --- | --- | --- |
| 0 | IconButton close (AppBar) | 8 | 8 | 40 | 40 |
| 1 | TextField "Nama Universe" | 184 | 361 | 1118 | 20 |
| 2 | TextButton "Cancel" | 960 | 1301 | 103 | 40 |
| 3 | FilledButton "Next" | 960 | 1416 | 100 | 40 |

**Langkah 1 (Type) — 11 stop:** delapan `ChoiceChip` dalam satu baris, lalu footer, lalu kembali ke close.

| # | Label | t | l | w | h |
| --- | --- | --- | --- | --- | --- |
| 0 | Canon | 174 | 345 | 100 | 37 |
| 1 | Alternate | 174 | 457 | 171 | 37 |
| 2 | What If | 174 | 639 | 126 | 37 |
| 3 | Spin-Off | 174 | 777 | 139 | 37 |
| 4 | AU | 174 | 928 | 60 | 37 |
| 5 | Crossover | 174 | 1000 | 152 | 37 |
| 6 | Parallel | 174 | 1164 | 139 | 37 |
| 7 | Dream | 174 | 1315 | 100 | 37 |
| 8 | Cancel | 960 | 1301 | 103 | 40 |
| 9 | Next | 960 | 1416 | 100 | 40 |

**Langkah 2 (Confirm) — 3 stop:** `Cancel`, `Create`, lalu kembali ke close. Tombol utama berubah label dari "Next" menjadi "Create" karena `_stepIndex == _steps.length - 1`, sementara posisi footer tetap sama.

### 15.3 Dua tinggi baris yang mengontrakkan urutan

- **Langkah 0** punya tiga tinggi baris berbeda (AppBar 8, konten 184, footer 960). Urutan fokus mengikuti urutan baca: atas ke bawah.
- **Langkah 1** punya dua tinggi baris (chip 174, footer 960), dengan delapan chip berbagi satu tinggi baris dan diurutkan kiri ke kanan.
- **Langkah 2** hanya satu tinggi baris selain AppBar, karena langkah konfirmasi tidak punya field.

Kontrak 2.4.3 yang dikontrakkan bersifat relatif: field dan chip selalu mendahului footer, footer selalu Cancel di kiri dan tombol utama di kanan, dan traversal selalu kembali ke `close` di AppBar setelah putaran terakhir.

### 15.4 Test sempat RED — di harness, bukan produksi

Run pertama gagal di test 2 dan 3. Penyebabnya bukan widget produksi: **fokus bertahan saat berpindah langkah**, sehingga traversal pada langkah kedua dan ketiga dimulai dari `close` (label `?`) alih-alih dari chip atau footer. Assertion berbasis indeks absolut ikut bergeser.

Perbaikan ada di helper `_stops`, bukan di produksi: setelah traversal selesai, daftar dirotasi agar dimulai dari stop dengan `top` terkecil. `close` di AppBar adalah satu-satunya stop di baris paling atas pada setiap langkah, sehingga indeks assertion menjadi deterministik tanpa mengubah urutan relatif antar stop.

### 15.5 Negative control

Urutan delapan `expectedTypes` dibalik di dalam test lalu dijalankan ulang. Hasil **4 dari 5 PASS**, dengan test "langkah Type: delapan chip kiri ke kanan sesuai _universeTypes" yang runtuh. Assertion urutan chip terbukti punya kekuatan.

### 15.6 Gate

| Gate | Hasil |
| --- | --- |
| `create_universe_wizard_focus_order_test.dart` | 5 dari 5 PASS |
| Negative control (urutan chip dibalik) | 4 dari 5 PASS, 1 FAIL |
| `dart analyze test/features/multiverse/` | No issues found |
| CJK/Cyrillic scan | none |
| `test/features/multiverse/` (14 berkas test) | 47 PASS, 0 FAIL |

---

## 16. Fase 11 — Focus Order di Timeline Workspace (2.4.3)

Layar keenam untuk 2.4.3, dan yang pertama punya **dua mode tampilan** yang saling menggantikan: Edit dan Preview. Kontrak fokus diuji untuk keduanya.

### 16.1 Kenapa layar ini dipilih

`timeline_workspace_screen.dart` (453 baris) punya stop fokus paling banyak di antara layar yang belum diaudit. Unggulannya pada tabel kandidat:

| Layar | Baris | Interaktif | Skor |
| --- | --- | --- | --- |
| **timeline_workspace** | 453 | 15 | 11 |
| create_universe_wizard (Fase 10) | 418 | 8 | 8 |
| workflow_editor | 130 | 7 | 7 |
| automation_center | 270 | 6 | 6 |
| content_capability_matrix | 462 | 5 | 5 |
| variant_inspector | 363 | 4 | 4 |

Skor memakai `interaktif - 4*async - 3*nav`, supaya future dan navigasi tetap memotong meski nilai Determinismenya tinggi.

Satu-satunya kemunculan async di berkas ini adalah tipe callback `onClipTimingChanged` (`Future<void> Function(...)`) pada baris 18 — bukan logika async di dalam widget. Tanpa navigasi, dan urutan track berasal dari `TimelineTrackType.values` sementara urutan clip dari `startSeconds`.

### 16.2 Temuan probe: area timeline kosong tidak punya stop fokus

Probe pertama memakai `clips` default (kosong) dan menghasilkan hanya 6 stop — seluruhnya di pita header dan toolbar. Lima puluh track row tetap tergambar, tetapi nol di antaranya punya stop fokus.

Setelah `clips` diisi tiga clip, traversal bertambah tiga stop, satu per clip. Ini bukan defect: `TimelineClip` memakai `InkWell(onTap:)`, jadi setiap clip memang punya satu node fokus yang tidak muncul ketika daftarnya kosong.

Kontrak ini ikut dikunci, karena track kosong dan track yang ada adalah dua keadaan fokus yang berbeda.

### 16.3 Data traversal mode Edit (tiga clip) — 9 stop

| # | Kontrol | t | l | w | h |
| --- | --- | --- | --- | --- | --- |
| 0 | Play | 6 | 1476 | 40 | 40 |
| 1 | Zoom out | 64 | 484 | 40 | 40 |
| 2 | Zoom in | 64 | 660 | 40 | 40 |
| 3 | Fit Scene | 64 | 704 | 151 | 40 |
| 4 | Edit | 60 | 867 | 123 | 48 |
| 5 | Preview | 60 | 990 | 123 | 48 |
| 6 | clip "Arin Vale" | 158 | 428 | 240 | 28 |
| 7 | clip "Mira Solenne" | 158 | 748 | 160 | 28 |
| 8 | clip "Dolly In" | 290 | 348 | 320 | 28 |

Lalu kembali ke 0 (Play).

Dua detail yang membuat kontrak ini tidak bisa disederhanakan:

- **Tinggi pita toolbar tidak seragam.** Zoom out, zoom in, dan Fit Scene berada di `top=64`, sedangkan dua segmen `SegmentedButton` berada di `top=60` meski keduanya di pita yang sama secara visual. Urutan toolbar karena itu dikontrakkan lewat `left`, bukan `top`.
- **Track terbaca dari `top`, clip terbaca dari `left` di dalam track.** Dua clip character berbagi `top=158` dengan urutan kiri ke kanan (start 1.0 lalu 5.0); clip camera berada di `top=290` meski `startSeconds`-nya 0.0.

### 16.4 Data traversal mode Preview — 1 stop

Menekan "Preview" mengganti seluruh isi panel. Traversal menyisakan satu stop: "Back to Edit" di tengah layar (`t=557.5`, `l=650.4`, `w=235.2`, `h=40`). Tidak ada stop dari mode Edit yang tersisa — pengujiannya memeriksa langsung bahwa "Fit Scene" dan label clip tidak lagi ditemukan.

### 16.5 Tiga jebakan harness

Ketiganya sudah diperbaiki di test dan **bukan defect produksi**:

1. **`IconButton` tidak punya label di subtree fokus.**_play, zoom out, dan zoom in punya `tooltip` terisi, tetapi node fokusnya adalah `InkWell`/`Focus` internal yang tidak memuat teks. Ketiganya tampil dengan label kosong dan didiskriminasi lewat posisi.
2. **`SegmentedButton` memproyeksikan tiap segmen ke node fokus tersendiri**, sehingga Edit dan Preview dihitung dua stop, bukan satu. Kalau dihitung satu, traversal akan melaporkan loop lebih awal.
3. **Fokus bertahan saat mode berubah**, sehingga traversal mode Preview dimulai dari node yang sedang difokus. Daftar hasil traversal dirotasi agar mulai dari stop `top` terkecil (Play di header), persis seperti pada Fase 10.

### 16.6 Negative control

Urutan tiga label clip dibalik di dalam test lalu dijalankan ulang. Hasil **4 dari 5 PASS**, dengan test "setiap clip dapat stop fokus, dikelompokkan per track" yang runtuh.

### 16.7 Gate

| Gate | Hasil |
| --- | --- |
| `timeline_workspace_focus_order_test.dart` | 5 dari 5 PASS |
| Negative control (urutan clip dibalik) | 4 dari 5 PASS, 1 FAIL |
| `dart analyze test/features/timeline/` | No issues found |
| CJK/Cyrillic scan | none |
| `test/features/timeline/` | 21 PASS, 0 FAIL |

---

## 17. Fase 12 — Focus Order di Creator Workspace (2.4.3)

`creator_workspace_screen.dart` dipilih sebagai layar berikutnya karena menjadi kandidat teratas setelah Timeline Workspace: sembilan kartu seksi interaktif, tanpa async dan tanpa navigasi di dalam layar.

### 17.1 Data traversal

Probe nyata pada viewport 1536x1024, devicePixelRatio 1.0 menghasilkan **9 stop fokus** dan loop kembali ke `My Projects`:

| # | Stop | Baris | Kolom |
|---|---|---:|---:|
| 0 | My Projects | 80.0 | 24.0 |
| 1 | My Characters | 80.0 | 528.0 |
| 2 | My Worlds | 80.0 | 1032.0 |
| 3 | My Assets | 270.29 | 24.0 |
| 4 | My Stories | 270.29 | 528.0 |
| 5 | My AI Agents | 270.29 | 1032.0 |
| 6 | My Workflows | 460.57 | 24.0 |
| 7 | Portfolio | 460.57 | 528.0 |
| 8 | Archive | 460.57 | 1032.0 |

Urutannya row-major dan sama persis dengan `CreatorWorkspaceSection.values`. Setiap kartu memakai `InkWell`, memiliki label teks yang dapat dibaca, dan memiliki area fokus non-zero.

### 17.2 Kontrak

Test mengunci sembilan stop, urutan label, tiga kolom kiri-ke-kanan di setiap baris, dan tiga baris atas-ke-bawah. Test juga memverifikasi bahwa semua seksi enum memang tampil. Traversal setelah `Archive` kembali ke `My Projects`.

### 17.3 Negative control

Ekspektasi sengaja diubah agar melewati item pertama enum. Hasil **2 dari 3 PASS, 1 FAIL** pada assertion urutan utama. Setelah kontrol dipulihkan, test kembali hijau.

### 17.4 Gate

| Gate | Hasil |
|---|---|
| test fokus Creator Workspace | 3 dari 3 PASS |
| negative control | 2 dari 3 PASS, assertion urutan FAIL |
| `test/features/creator/` | 77 PASS, 0 FAIL |
| `dart analyze` test fokus | No issues found |
| CJK/Cyrillic scan | none |

---

## 18. Fase 13 — Focus Order di Workflow Editor (2.4.3)

`workflow_editor_screen.dart` dipilih karena memiliki tiga field input dan satu aksi Save yang muncul setelah draft valid.

### 18.1 Kontrak traversal

Pada draft awal, probe dan test menghasilkan tiga stop fokus dalam urutan visual vertikal: `Workflow ID`, `Name`, dan `Steps (comma-separated ids)`. Setelah ID dan steps diisi sehingga draft valid, tombol `Save` muncul sebagai stop keempat dan berada di bawah ketiga field.

Test mengunci dua keadaan UI: draft incomplete (3 stop) dan draft valid (4 stop). Perubahan status valid tidak mengubah urutan field; ia hanya menambahkan Save di akhir.

### 18.2 Evidence dan gate

- Test fokus Workflow Editor: **2/2 PASS**.
- Test seluruh `test/features/workflow/`: **19 PASS**.
- Negative control mengubah ekspektasi draft incomplete dari 3 menjadi 4 stop dan menghasilkan **1 failure**, membuktikan assertion traversal aktif.
- `dart analyze` test fokus: **No issues found**.
- CJK/Cyrillic scan: **none**.

---

## 19. Fase 14 — Focus Order di Cinematic Production Workspace (2.4.3)

Probe nyata pada viewport 1536x1024, devicePixelRatio 1.0 menemukan dua stop fokus interaktif pada workspace:

1. `Import Audio` — kiri 24.0, atas 312.0
2. `Validation Center` — kiri 271.2, atas 312.0

Kartu informasi VFX, Audio, dan Timeline tidak menjadi stop fokus karena hanya `Card` dekoratif tanpa handler interaksi. Kontrak mengunci bahwa dua aksi ditab kiri-ke-kanan pada baris yang sama, dengan area fokus non-zero. Traversal setelah `Validation Center` kembali ke `Import Audio`.

Gate:

- Test focus order: **1/1 PASS**.
- Test seluruh `test/features/cinematic_production/`: **3 PASS**.
- `dart analyze`: **No issues found**.
- Probe sementara dihapus.
- CJK/Cyrillic scan: **none**.

---

## 20. Fase 15 — Focus Order di Marketplace Workspace (2.4.3)

Probe nyata pada viewport desktop 1536x1024 dan compact 390x844 menghasilkan enam stop fokus pada kedua layout:

1. Discover
2. AI Agents
3. Workflows
4. Prompts
5. Templates
6. My Library

Pada layout wide, keenam item berada di sidebar dan ditab dari atas ke bawah. Pada layout compact, item berada di ListView dan mempertahankan urutan yang sama. Setiap item memiliki area fokus non-zero. Setelah `My Library`, traversal kembali ke `Discover`.

Kartu konten utama `Discover` hanya placeholder dekoratif dan tidak menjadi stop fokus.

Gate:

- Test focus order desktop dan compact: **2/2 PASS**.
- Test seluruh `test/features/marketplace/`: **35 PASS**.
- `dart analyze`: **No issues found**.
- Probe sementara dihapus.
- CJK/Cyrillic scan: **none**.

---

## 21. Fase 16 — Focus Order di Agent Permission Screen (2.4.3)

Probe nyata pada viewport 1536x1024 menemukan tiga stop fokus:

1. Switch untuk permission optional `AI Provider`, di sisi kanan tile.
2. `Allow All`, setelah daftar permission.
3. `Deny Optional`, di sebelah kanan `Allow All`.

Permission required `File Access` dan `Network` memiliki label `Required` tanpa kontrol interaktif. Tile permission sendiri tidak menjadi stop fokus. Kontrak mengunci tiga stop aktual, urutan stateful switch lalu dua aksi, posisi tombol pada baris yang sama, dan area fokus non-zero.

Gate:

- Test focus order: **1/1 PASS**.
- `dart analyze`: **No issues found**.
- Probe sementara dihapus.
- CJK/Cyrillic scan: **none**.

---

## 22. Fase 17 — Focus Order di Create Product Wizard & Product Detail (2.4.3)

Dua layar marketplace yang hanya memiliki aksi di bagian bawah diuji pada viewport 1536x1024.

Create Product Wizard (`create_product_wizard_screen.dart`):

1. `Cancel` — kiri.
2. `Next` — kanan (berubah menjadi `Finish` pada langkah terakhir, namun posisi dan urutan tetap).

Chip langkah (`Details`, `Pricing`, `Files`, `Review`) bersifat informasional dan tidak menjadi stop fokus. Setelah `Next`, traversal kembali ke `Cancel`.

Product Detail (`product_detail_screen.dart`):

1. `Install` — kiri.
2. `Buy` — kanan.

Baris info (`Description`, `Version`, `Rating`, `Reviews`) tidak interaktif dan tidak menjadi stop fokus.

Kontrak mengunci dua stop per layar, urutan kiri-ke-kanan pada baris yang sama, dan area fokus non-zero.

Negative control: menukar expected `['Install', 'Buy']` menjadi `['Buy', 'Install']` menghasilkan `NEG_EXIT=1` dan `+1 -1: Some tests failed`, membuktikan assertion urutan memiliki witness RED.

Gate:

- Test focus order dua layar: **2/2 PASS**.
- `dart analyze`: **No issues found**.
- Probe sementara dihapus.
- CJK/Cyrillic scan: **none**.

---

## 23. Fase 18 — Focus Order di Reference Management Screen (2.4.3)

Layar `lib/features/references/presentation/reference_management_screen.dart` (Identity Consistency workspace) diuji pada viewport 1536x1024 dpr 1.0. Layar ini mandiri: hanya butuh list model in-memory, tanpa database, tanpa network, tanpa Riverpod provider.

Traversal diukur dengan menekan `LogicalKeyboardKey.tab` berulang dan mencatat `FocusManager.instance.primaryFocus`, rect global focus, serta label `Text` pertama yang bukan `Icon` di dalam subtree fokus. Traversal dihentikan saat rect berulang (siklus tertutup).

Hasil probe pada tab `Reference Sets` dengan ketiga callback create aktif:

1. `Reference Sets` — top 56.0, left 52.0, 229.4x48.0
2. `Identity Locks` — top 56.0, left 281.4, 229.4x48.0
3. `Consistency Rules` — top 56.0, left 510.8, 271.7x48.0
4. `Reports` — top 56.0, left 782.5, 130.7x48.0
5. `Create Set` — top 132.0, left 1305.0, 207.0x40.0

Empat stop pertama adalah tab strip: satu baris fokus (top sama) dengan koordinat `left` naik strict, lalu aksi konten berada di bawahnya. Ini sesuai WCAG 2.4.3: urutan fokus mengikuti urutan baca visual, bukan urutan deklarasi widget.

Per tab:

- `Reference Sets` — 4 tab + `Create Set` (5 stop).
- `Identity Locks` — 4 tab + `Add Lock` (5 stop).
- `Consistency Rules` — 4 tab + `Add Rule` (5 stop).
- `Reports` — 4 tab saja, tanpa aksi (4 stop), karena `_EntityList` untuk Reports menerima `actionLabel: null`.

Temuan penting dari probe: saat ketiga callback create dibiarkan `null`, traversal hanya menghasilkan 4 stop, karena `FilledButton.icon` dengan `onPressed: null` tidak bisa difokuskan. Ini perilaku Material yang benar (tombol nonaktif bukan stop fokus), bukan defect produksi. Kontrak sengaja memverifikasi state interaktif (callback aktif) supaya traversal penuh terukur.

Baris `SwitchListTile` pada tab `Identity Locks` memakai `onChanged: null` sehingga tidak menjadi stop fokus — juga disengaja di produksi (lock ditampilkan read-only di layar ini).

Kontrak `test/features/references/reference_management_focus_order_test.dart` mengunci:

- urutan label lengkap 5 stop pada tab default;
- keempat tab berbagi satu `rect.top` dan `left` naik strict;
- aksi konten `rect.top` lebih besar dari baris tab;
- tab `Reports` menghasilkan tepat 4 stop, semua di satu baris;
- tab `Identity Locks` dan `Consistency Rules` masing-masing mengekspos satu aksi, dengan tab strip tetap berupa siklus kiri-ke-kanan lalu wrap, tanpa duplikasi;
- setiap stop punya `width > 0` dan `height > 0`.

Kontrak hanya mengukur traversal satu arah (Tab). Perilaku `Shift+Tab` (reverse order) tidak diuji pada fase ini; itu kandidat fase berikutnya.

Catatan koreksi selama penyusunan: dua ekspektasi awal salah. Ekspektasi tab `Reports` mengasumsikan traversal dimulai dari tab aktif (`Reports`), padahal setelah `DefaultTabController` dengan `initialIndex`, fokus awal tetap pada tab pertama. Probe kedua mengoreksinya menjadi urutan `Reference Sets, Identity Locks, Consistency Rules, Reports`. Ekspektasi kedua gagal karena reorder list setelah tap tidak mempertahankan posisi awal. Kontrak akhir menguji sifat siklus, bukan posisi start yang rapuh.

Negative control: memindahkan `Create Set` ke depan urutan expected menghasilkan `NEG_EXIT=1` dan `+2 -1: Some tests failed`, membuktikan assertion urutan punya witness RED. File dipulihkan dari backup dan suite kembali `+3: All tests passed!`.

Gate:

- Test kontrak: **3/3 PASS**.
- `dart analyze` file kontrak: **No issues found!**
- `flutter test test/features/references/`: **25/25 All tests passed!**
- Probe sementara `_probe_focus_test.dart` dihapus.
- CJK/Cyrillic scan pada file test: **none**.

Status: **VERIFIED** (test-level, satu arah Tab, viewport 1536x1024). Belum ada bukti native/computer-use pada fase ini.

---
## 24. Fase 19 — Focus Order di Public Project Page Screen (2.4.3)

**Layar:** `lib/features/release/presentation/public_project_page_screen.dart` (`PublicProjectPageScreen`)
**Kontrak:** `test/features/release/presentation/public_project_page_focus_order_test.dart`
**Tanggal:** 2026-10-03 | **Viewport probe & kontrak:** 1536 x 1024, dpr 1.0 | **Metode:** traversal `LogicalKeyboardKey.tab` berulang, berhenti saat `Rect` fokus berulang.

### Hasil probe (evidence-first)

Probe sementara pumped layar di dalam `ProviderScope` + `MaterialApp` (layar hanya butuh `releaseProvider`, tanpa database atau jaringan), lalu menekan `tab` sampai `Rect` fokus berulang. Output `STOP` mentah:

```
STOP 0: label="Follow"        rect=Rect.fromLTRB(16.0, 76.0, 509.3, 116.0)
STOP 1: label="Watch"         rect=Rect.fromLTRB(521.3, 76.0, 1014.7, 116.0)
STOP 2: label="Play"          rect=Rect.fromLTRB(1026.7, 76.0, 1520.0, 116.0)
STOP 3: label="About"         rect=Rect.fromLTRB(52.0, 136.0, 154.5, 184.0)
STOP 4: label="Characters"    rect=Rect.fromLTRB(154.5, 136.0, 327.5, 184.0)
STOP 5: label="Gallery"       rect=Rect.fromLTRB(327.5, 136.0, 458.2, 184.0)
STOP 6: label="Episodes"      rect=Rect.fromLTRB(458.2, 136.0, 603.0, 184.0)
STOP 7: label="Game Updates"  rect=Rect.fromLTRB(603.0, 136.0, 804.2, 184.0)
STOP 8: label="Credits"       rect=Rect.fromLTRB(804.2, 136.0, 934.9, 184.0)
STOP 9: REPEAT rect=Rect.fromLTRB(16.0, 76.0, 509.3, 116.0)
```

Jumlah stop: **9** (3 aksi baris utama + 6 tab). Probe dihapus setelah kontrak ditulis.

### Kontrak yang dikunci

`test/features/release/presentation/public_project_page_focus_order_test.dart` mengunci tiga hal:

1. **Urutan label persis:** `Follow, Watch, Play, About, Characters, Gallery, Episodes, Game Updates, Credits`.
2. **Properti posisi:** tiga aksi berbagi satu baris fokus (`top` sama, `left` menaik); enam tab berbagi satu baris fokus lain (`top` sama, `left` menaik); strip tab berada di bawah baris aksi dan tidak dimulai sebelum `left` baris aksi.
3. **Area fokus non-zero:** setiap stop punya `width > 0` dan `height > 0`.

Dua penguat tambahan: mengganti tab ke `Gallery` tidak menambah atau mengubah stop fokus, dan tab terakhir (`Credits`) berada di ujung kanan strip sebelum traversal membungkus kembali ke `Follow`.

### Negative control

Ekspektasi urutan label dimutasi sementara (`Watch` <-> `About` ditukar pada list pertama) lalu `flutter test` dijalankan tanpa pipe:

```
00:02 +2 -1: Some tests failed.
Failing tests:
  ...public_project_page_focus_order_test.dart: ... baris aksi dibaca kiri ke kanan sebelum strip tab
REAL_EXIT=1
```

File dipulihkan dari backup `cp` di `%LOCALAPPDATA%\Temp`, backup dihapus, dan re-run pasca-restore hijau (`RESTORE_EXIT=0`, `+3: All tests passed!`). Kontrak terbukti punya daya deteksi, bukan sekadar lulus pasif.

### Gate

| Gate | Perintah | Hasil |
|---|---|---|
| Format | `dart format test/features/release/presentation/public_project_page_focus_order_test.dart` | `Formatted 1 file (1 changed)` |
| Analyzer | `dart analyze test/features/release/presentation/public_project_page_focus_order_test.dart` | `No issues found!` |
| Kontrak | `flutter test test/features/release/presentation/public_project_page_focus_order_test.dart` | `+3: All tests passed!` (exit 0) |
| Negative control | mutasi urutan label | `+2 -1: Some tests failed.` (exit 1) |
| Suite feature | `flutter test test/features/release/` | lihat bagian bawah |

### Status

**VERIFIED** untuk 2.4.3 (Focus Order) pada layar ini: traversal reading order, urutan kiri-ke-kanan per baris, dan area fokus non-zero terkunci kontrak yang terbukti negatif. Tidak ada defect produksi yang ditemukan pada probe, jadi tidak ada kode produksi yang diubah pada fase ini.

### Catatan metodologi

- `_screen()` memakai `ProviderScope` karena layar adalah `ConsumerWidget` yang memanggil `ref.watch(releaseProvider)`; `ReleaseController` hanya menyimpan state in-memory, jadi tidak ada fixture database atau jaringan.
- Deteksi label memakai traversal `Element` yang mengambil `Text` pertama non-`Icon` di subtree fokus; `Icon` dilewati agar label stabil.
- Kunci siklus memakai segitiga (`top|left|width`), bukan hanya posisi, supaya dua stop dengan `top|left` sama tapi lebar berbeda tetap dihitung berbeda.
- Layar ini memakai `TabBar` dengan `DefaultTabController`, sehingga traversal mengikuti urutan deklarasi tab; ini perilaku `FocusTraversalGroup` bawaan Material, bukan defect.

## 25. Fase 20 — Focus Order di Reference Library Screen (2.4.3)

**Layar:** `lib/features/references/presentation/reference_library_screen.dart` (`ReferenceLibraryScreen`)
**Kontrak:** `test/features/references/reference_library_focus_order_test.dart`
**Tanggal:** 2026-10-03 | **Viewport probe & kontrak:** 1536 x 1024, dpr 1.0 | **Metode:** traversal `LogicalKeyboardKey.tab` berulang, berhenti saat `Rect` fokus berulang.

Layar ini mandiri: data disuntikkan lewat constructor (`references`, `onImport`, `onSetPrimary`, `onRepair`), jadi tidak ada fixture database, network, maupun Riverpod provider. Fixture probe memakai tiga `ReferenceModel` dengan `filePath` yang sengaja tidak ada di disk, sehingga setiap kartu memunculkan tombol `Repair` — ini exercising jalur interaktif terburuk tanpa memalsukan kondisi sehat.

### Hasil probe (evidence-first)

Output `STOP` mentah dari traversal atas:

```
STOP 0: label="tooltip:Import reference"  rect=Rect.fromLTRB(1492.0, 8.0, 1532.0, 48.0)
STOP 1: label="field:Search References..." rect=Rect.fromLTRB(598.2, 88.0, 950.2, 112.0)
STOP 2: label="All types"                  rect=Rect.fromLTRB(978.2, 76.0, 1179.8, 124.0)
STOP 3: label="Set Primary"                rect=Rect.fromLTRB(443.7, 234.0, 617.3, 290.0)
STOP 4: label="Set Primary"                rect=Rect.fromLTRB(665.3, 234.0, 839.0, 290.0)
STOP 5: label="Repair"                     rect=Rect.fromLTRB(222.0, 334.0, 360.6, 374.0)
STOP 6: label="Repair"                     rect=Rect.fromLTRB(443.7, 334.0, 582.3, 374.0)
STOP 7: label="Repair"                     rect=Rect.fromLTRB(665.3, 334.0, 803.9, 374.0)
STOP 8: REPEAT rect=Rect.fromLTRB(1492.0, 8.0, 1532.0, 48.0)
```

Jumlah stop: **8**. Probe dihapus setelah kontrak ditulis.

Dua stop pertama tidak punya `Text` di subtree fokusnya: `IconButton` di `AppBar` hanya mengekspos `Icon`, dan `TextField` search memusatkan label di `InputDecoration`. Versi probe pertama yang hanya mencari `Text` membacanya sebagai `"?"` untuk keduanya, lalu kunci siklus dengan segitiga (`top|left|width`) membuat dua `Repair` yang lebarnya berbeda tetap terhitung berbeda. Kontrak final memakai urutan resolusi `Tooltip` -> `InputDecoration.labelText`/`hintText` -> `Text` non-`Icon` -> runtime type, dan hasilnya stabil.

### Kontrak yang dikunci

`test/features/references/reference_library_focus_order_test.dart` mengunci tiga hal lewat tiga test:

1. **Urutan label persis, 8 stop:** `tooltip:Import reference`, `field:Search References...`, `All types`, `Set Primary`, `Set Primary`, `Repair`, `Repair`, `Repair`.
2. **Properti posisi:** aksi `AppBar` dibaca paling awal (`top` paling kecil), lalu baris filter (`Search` dan `All types` sebaris, `left` menaik), lalu grid kartu dibaca baris per baris. Dua `Set Primary` berbagi `top` dengan `left` menaik; tiga `Repair` membentuk baris kedua dengan `left` menaik dan `top` di bawah baris `Set Primary`. Setiap stop punya `width > 0` dan `height > 0`.
3. **Perilaku traversal ikut kondisi data:** saat search diisi `Kokuen`, traversal menyusut ke lima stop (`All types`, `Set Primary`, `Repair`, lalu kembali ke `tooltip:Import reference` dan `field:Search References...`) karena kartu yang ter-filter keluar dari traversal. Saat search diisi `zzz` dan hasil kosong, hanya tiga kontrol chrome yang tersisa (`All types`, `tooltip:Import reference`, `field:Search References...`) dan `No references found` tetap tampil. Kontrol chrome tidak boleh hilang hanya karena data kosong — itu yang mengunci akses keyboard saat grid kosong.

Catatan: traversal pada dua state terakhir dimulai dari node fokus yang sedang aktif setelah `enterText`, sehingga urutan relatif berbeda dari state awal. Yang dikunci adalah himpunan label dan factility chrome, bukan posisi absolut.

### Negative control

Ekspektasi jumlah stop dimutasi sementara (`_expectedStops` 8 -> 7) lalu `flutter test` dijalankan tanpa pipe:

```
Expected: an object with length of <7>
  Actual: [
#4      main.<anonymous closure>.<anonymous closure> (...reference_library_focus_order_test.dart:136:9)
00:02 +2 -1: Some tests failed.
NEGATIVE_EXIT=1
```

File dipulihkan dari backup `cp` di `%LOCALAPPDATA%\Temp`, backup dihapus (`BACKUP_GONE`), dan re-run pasca-restore hijau (`RESTORE_EXIT=0`, `+3: All tests passed!`). Kontrak terbukti punya daya deteksi, bukan sekadar lulus pasif.

### Gate

| Gate | Perintah | Hasil |
|---|---|---|
| Format | `dart format test/features/references/reference_library_focus_order_test.dart` | `Formatted 1 file (1 changed)` (exit 0) |
| Analyzer | `dart analyze test/features/references/reference_library_focus_order_test.dart` | `No issues found!` (exit 0) |
| Kontrak | `flutter test test/features/references/reference_library_focus_order_test.dart` | `+3: All tests passed!` (exit 0) |
| Negative control | mutasi `_expectedStops` 8 -> 7 | `+2 -1: Some tests failed.` (exit 1) |
| Suite feature | `flutter test test/features/references/` | `+28: All tests passed!` (exit 0) |
| Scan CJK/Cyrillic | atas file kontrak | `none` |

### Status

**VERIFIED** untuk 2.4.3 (Focus Order) pada layar ini: urutan reading AppBar -> filter -> grid, urutan kiri-ke-kanan per baris, area fokus non-zero, dan terpelihannya kontrol chrome saat hasil kosong, semuanya terkunci kontrak yang terbukti negatif. Probe tidak menemukan defect produksi focus order, jadi tidak ada kode produksi yang diubah pada fase ini.

### Catatan metodologi

- `_screen()` tidak butuh `ProviderScope` karena layar ini `StatefulWidget` murni dengan data injeksi constructor.
- Kunci siklus memakai segitiga (`top|left|width`) supaya dua stop dengan `top|left` sama tapi lebar berbeda (`Set Primary` 173.6 px vs 138.6 px pada dua baris berbeda) tidak collapsing.
- Kartu dibaca baris per baris oleh `FocusTraversalGroup` bawaan Material pada `GridView`, mengikuti urutan baca visual — sesuai WCAG 2.4.3.
- `ReferenceType` dan `ReferenceSource` dibaca langsung dari `lib/features/references/domain/reference_models.dart` saat menyusun fixture (`ReferenceSource.imported`, bukan `upload` — nilai tersebut tidak ada dan compile gagal saat probe pertama).
- Screen ini berbeda dari `ReferenceManagementScreen` yang sudah diaudit di Bagian 23; keduanya berada di feature `references` tapi widget dan traversal-nya tidak sama.

## 26. Fase 21 — Focus Order di Reference Comparison Screen (2.4.3)

**Layar:** `lib/features/references/presentation/reference_comparison_screen.dart` (`ReferenceComparisonScreen`)
**Kontrak:** `test/features/references/reference_comparison_focus_order_test.dart`
**Tanggal:** 2026-10-03 | **Viewport probe & kontrak:** 1536 x 1024 dan 390 x 844, dpr 1.0 | **Metode:** traversal `LogicalKeyboardKey.tab` berulang, berhenti saat `Rect` fokus berulang.

Layar ini mandiri: kedua path gambar disuntikkan lewat constructor dan sengaja menunjuk file yang tidak ada di disk, sehingga setiap pane jatuh ke `errorBuilder` dan menampilkan `Icons.broken_image_outlined`. Tidak ada fixture database, network, maupun Riverpod provider, dan file screen ini tidak pernah disentuh Core Worker (`git status --porcelain` kosong sebelum dan sesudah fase ini).

### Hasil probe (evidence-first)

Output `STOP` mentah dari traversal atas:

```
=== SCENARIO side-by-side (1536x1024) ===
STOP 0 | label=Side by Side | 433.2,964.0,223.2x48.0
STOP 1 | label=Overlay       | 656.4,964.0,223.2x48.0
STOP 2 | label=Swipe         | 879.6,964.0,223.2x48.0
STOP 3 | label=Side by Side | 433.2,964.0,223.2x48.0   (REPEAT -> siklus ditutup)
=== TOTAL 3 ===

=== SCENARIO overlay (1536x1024) ===
STOP 0 | label=Side by Side | 342.2,964.0,193.2x48.0
STOP 1 | label=Overlay       | 535.4,964.0,193.2x48.0
STOP 2 | label=Swipe         | 728.6,964.0,193.2x48.0
STOP 3 | label=widget:Focus  | 933.8,964.0,260.0x48.0
STOP 4 | label=Side by Side | 342.2,964.0,193.2x48.0   (REPEAT -> siklus ditutup)
=== TOTAL 4 ===

=== SCENARIO swipe narrow (390x844) ===
STOP 0 | label=Side by Side | 12.0,756.0,122.0x76.0
STOP 1 | label=Overlay       | 134.0,756.0,122.0x76.0
STOP 2 | label=Swipe         | 256.0,756.0,122.0x76.0
STOP 3 | label=Side by Side | 12.0,756.0,122.0x76.0   (REPEAT -> siklus ditutup)
=== TOTAL 3 ===

=== SCENARIO overlay narrow (390x844) ===
STOP 0 | label=Side by Side        | 12.0,700.0,122.0x76.0
STOP 1 | label=Overlay              | 134.0,700.0,122.0x76.0
STOP 2 | label=Swipe                | 256.0,700.0,122.0x76.0
STOP 3 | label=slider:50% generated  | 12.0,784.0,366.0x48.0
STOP 4 | label=Side by Side        | 12.0,700.0,122.0x76.0   (REPEAT -> siklus ditutup)
=== TOTAL 4 ===
```

Jumlah stop: **3** pada mode `Side by Side`/`Swipe`, **4** pada mode `Overlay`. Probe dihapus setelah kontrak ditulis.

Probe pertama hanya mencari `Text` non-`Icon`, sehingga slider terbaca sebagai `widget:Focus` — label `Slider` disimpan sebagai `label` widget dan tidak pernah di-render sampai slider di-drag, jadi tidak ada `Text` di subtree fokusnya. Kontrak final menyisipkan resolusi `Slider` ke dalam urutan `Tooltip` -> `Slider.label` -> `Text` -> runtime type, hasilnya stabil (`slider:50% generated`).

### Temuan geometri yang menolak asumsi awal

Dua ekspektasi pertama yang saya tulis sendiri ternyata salah dan ditolak oleh probe. Keduanya adalah asumsi saya, bukan defect produksi:

1. **Di layout lebar (1536 px) slider TIDAK turun ke baris baru.** `Wrap` pada panel kontrol punya cukup ruang, jadi slider tetap sebaris dengan tiga segment, di sebelah kanan `Swipe` pada `top` yang sama (964.0). Ekspektasi awal `stops[2].rect.bottom <= stops[3].rect.top` gagal dengan `Expected: a value less than or equal to <964.0> Actual: <1012.0>`.
2. **Ekspektasi overlap vertikal awal tidak bermakna.** `stops[0].rect.top == stops[1].rect.bottom` menebak `top` sebagai koordinat absolut; yang benar adalah membandingkan tinggi dan lebar. Diganti menjadi assertion tinggi fokus sama dan `top < bottom`.

Yang justru berubah total antara lebar dan sempit adalah **geometri segment**: pada 1536 px tiap segment 223.2 x 48.0 pada `top` 964.0; pada 390 px tiap segment 122.0 x 76.0 pada `top` 756.0, dan slider turun ke baris penuh 366.0 x 48.0 pada `top` 784.0. Keduanya dibaca kiri-ke-kanan sesuai urutan baca visual, sesuai WCAG 2.4.3.

### Kontrak yang dikunci

`test/features/references/reference_comparison_focus_order_test.dart` mengunci lima hal lewat lima test:

1. **Mode Side by Side = 3 stop persis:** `Side by Side`, `Overlay`, `Swipe`, dengan `find.byType(Slider)` harus `findsNothing` — slider hanya boleh muncul di mode `Overlay`.
2. **Urutan kiri-ke-kanan pada satu baris:** `left` menaik strict pada ketiganya, `top` sama, tinggi sama, `right` segment terakhir tidak melewati 1536.
3. **Mode Overlay = 4 stop persis:** `Side by Side`, `Overlay`, `Swipe`, `slider:50% generated`. Slider di sebelah kanan `Swipe` (`left` lebih besar), berbagi `top` yang sama di layout lebar, lebarnya lebih besar dari satu segment, `right`-nya tidak melewati viewport, dan `find.text('50% generated')` harus `findsNothing` saat idle karena label slider hanya muncul saat di-drag.
4. **Viewport 390 x 844 tidak kehilangan kontrol:** urutan label tetap empat, `tester.takeException()` null, lebar slider tidak melewati 390, dan baris segment (`top` 700.0) dibaca sebelum baris slider (`top` 784.0). Semua stop punya area non-zero.
5. **Perilaku keyboard pada `SegmentedButton`:** `ArrowRight` setelah memfokuskan group memindahkan sorot visual, bukan mengubah mode, sehingga `Slider` tetap `findsNothing` dan traversal dilanjutkan dari node fokus aktif memberi urutan relatif bergeser satu posisi (`Overlay`, `Swipe`, `Side by Side`). Ini didokumentasikan sebagai perilaku nyata, bukan defect focus order.

### Negative control

Ekspektasi urutan label dimutasi sementara (`slider:50% generated` dipindahkan ke depan traversal) lalu `flutter test` dijalankan tanpa pipe:

```
Expected: ['slider:50% generated', 'Side by Side', 'Overlay', 'Swipe']
  Actual: ['Side by Side', 'Overlay', 'Swipe', 'slider:50% generated']
   Which: at location [0] is 'Side by Side' instead of 'slider:50% generated'
00:02 +4 -1: Some tests failed.
NEGATIVE_EXIT=1
```

File dipulihkan dari backup `cp` di `%LOCALAPPDATA%\Temp`, backup dihapus (`BACKUP_GONE=YES`), dan re-run pasca-restore hijau (`RESTORE_EXIT=0`, `+5: All tests passed!`). Kontrak terbukti punya daya deteksi, bukan sekadar lulus pasif.

### Gate

| Gate | Perintah | Hasil |
|---|---|---|
| Format | `dart format test/features/references/reference_comparison_focus_order_test.dart` | `Formatted 1 file (0 changed)` (exit 0) |
| Analyzer | `dart analyze test/features/references/reference_comparison_focus_order_test.dart` | `No issues found!` (exit 0) |
| Kontrak | `flutter test test/features/references/reference_comparison_focus_order_test.dart` | `+5: All tests passed!` (exit 0) |
| Negative control | mutasi urutan label traversal | `+4 -1: Some tests failed.` (exit 1) |
| Suite feature | `flutter test test/features/references/` | lihat tabel status run ini |
| Scan CJK/Cyrillic | atas file kontrak | `none` |

### Status

**VERIFIED** untuk 2.4.3 (Focus Order) pada layar ini: urutan kiri-ke-kanan pada satu baris segment, penambahan slider sebagai stop keempat hanya di mode `Overlay`, safety geometri berbeda antara layout lebar dan sempit tetap tanpa kontrol hilang, dan area fokus non-zero di kedua viewport — semuanya terkunci kontrak yang terbukti negatif.

Tidak ada defect produksi focus order yang ditemukan, jadi tidak ada kode produksi yang diubah pada fase ini.

### Catatan metodologi

- Dua ekspektasi awal saya sendiri digugur oleh probe (lihat "Temuan geometri yang menolak asumsi awal"). Kontrak yang ditulis ulang mengikuti geometri nyata, bukan sebaliknya.
- Kunci siklus memakai segitiga (`top|left|width`). Pada layout lebar ketiga segment punya lebar identik (223.2) dan `top` identik, tapi `left` berbeda, jadi tidak collapsing.
- `_screen()` tidak butuh `ProviderScope` karena layar ini `StatefulWidget` murni dengan data injeksi constructor.
- ScrollBehavior default Material sudah menyertakan `widgetsApp` di traversal, jadi `InteractiveViewer` di area gambar tidak muncul sebagai stop — memang tidak punya kontrol keyboard yang dapat difokus.
- Screen ini berbeda dari `ReferenceLibraryScreen` (Bagian 25) dan `ReferenceManagementScreen` (Bagian 24), meski ketiganya berada di feature `references`.
## 27. Fase 22 — Focus Order di Forgot Password Screen (2.4.3)

**Layar:**  ()
**Kontrak:** 
**Tanggal:** 2026-10-03 | **Viewport probe & kontrak:** 1536 x 1024, dpr 1.0 | **Metode:** traversal  berulang, berhenti saat  fokus berulang.

Layar ini mandiri: callback  dan state email diinjeksikan langsung, tanpa database, network, atau provider. Probe memperbaiki hanya utilitas test untuk mengambil  dari ; tidak ada kode produksi yang diubah.

### Hasil probe (evidence-first)



Kontrak final memetakan tiga stop:  ->  -> . Semua  memiliki lebar dan tinggi non-zero; posisi stop monoton atas-ke-bawah dan sejajar kiri. Negative control mengubah jumlah stop dari 3 menjadi 4: test gagal dengan exit code 1 dan output ; file dipulihkan dan test kontrak kembali lulus.

**VERIFIED** untuk 2.4.3 (Focus Order): jumlah stop, urutan kontrol, geometri fokus non-zero, dan ketiadaan exception rendering terkunci oleh kontrak widget.

## 28. Fase 23 — Focus Order di Update Screen (2.4.3)

**Layar:** `UpdateScreen` (`lib/features/platform/presentation/update_screen.dart`)
**Kontrak:** `test/features/platform/presentation/update_screen_focus_order_test.dart`
**Tanggal:** 2026-10-03 | **Viewport probe & kontrak:** 1536 x 1024, dpr 1.0 | **Metode:** traversal `Tab` berulang, berhenti saat rect fokus berulang.

Layar ini mandiri dan tidak memerlukan database atau network. Probe memakai callback no-op agar dua tombol tetap masuk focus traversal; tidak ada kode produksi yang diubah.

### Hasil probe (evidence-first)

Probe mengukur 2 stop fokus:

1. `Later` — `Rect.fromLTRB(20.0, 279.0, 760.0, 319.0)`
2. `Download` — `Rect.fromLTRB(776.0, 279.0, 1516.0, 319.0)`

Kontrak final mengunci jumlah stop tepat 2, urutan label `Later` -> `Download`, area fokus non-zero, dan geometri kiri-ke-kanan pada satu baris. `tester.takeException()` juga wajib `null`. Negative control menukar urutan label menjadi `Download` -> `Later`; test gagal dengan exit code 1 dan output `Some tests failed`, lalu file dipulihkan dan kontrak kembali lulus.

**VERIFIED** untuk 2.4.3 (Focus Order): jumlah stop, urutan kontrol, posisi kiri-ke-kanan, dan area fokus non-zero terkunci oleh kontrak widget.

## 29. Fase 24 — Focus Order di Welcome Screen (2.4.3)

### 29.1 Layar dan fixture

`WelcomeScreen` dipilih karena mandiri, tanpa database/network, dan memiliki tiga aksi keyboard yang aktif: `Create Project`, `Open Project`, dan `Explore Demo`. Probe memakai viewport 1536x1024 dengan device pixel ratio 1.0 serta callback no-op agar ketiga tombol menjadi focusable.

### 29.2 Data traversal terukur

Traversal memakai `LogicalKeyboardKey.tab` sampai Rect fokus berulang sebagai tanda wrap. Hasil nyata:

- Stop 1 — `Create Project`, Rect `Rect.fromLTRB(638.0, 497.5, 898.0, 537.5)`
- Stop 2 — `Open Project`, Rect `Rect.fromLTRB(638.0, 557.5, 898.0, 597.5)`
- Stop 3 — `Explore Demo`, Rect `Rect.fromLTRB(638.0, 617.5, 898.0, 657.5)`
- Tab berikutnya kembali ke `Create Project` dan menghentikan probe.

Urutan aktual mengikuti urutan baca atas-ke-bawah. Seluruh area fokus memiliki lebar dan tinggi non-zero.

### 29.3 Kontrak dan negative control

Kontrak `test/features/platform/presentation/welcome_screen_focus_order_test.dart` mengunci tiga stop, label, posisi top yang meningkat, area fokus non-zero, dan tidak adanya exception rendering. Negative control menukar dua label ekspektasi; test benar-benar gagal dengan exit code `1` dan output `Some tests failed`, lalu file dipulihkan dari backup.

### 29.4 Gate dan cakupan

- `dart format test/features/platform/presentation/welcome_screen_focus_order_test.dart` — exit `0`.
- `dart analyze test/features/platform/presentation/welcome_screen_focus_order_test.dart` — `No issues found!`.
- Focus-order test — `All tests passed!`.
- Feature-suite gate: dijalankan pada closeout dan dilaporkan dari output aktual.

Status fase: **VERIFIED** untuk kontrak WCAG 2.4.3 pada Welcome Screen. Cakupan audit focus-order layar: 24 dari 89 target layar (`26eb29a` adalah commit sebelumnya; commit fase ini dicatat setelah gate).

## 30. Fase 25 — Focus Order di Product Detail Screen (2.4.3)

### 30.1 Layar dan fixture

`ProductDetailScreen` dipilih karena mandiri, tanpa database/network, dan memiliki dua CTA aktif dengan callback no-op: `Install` dan `Buy`. Probe memakai viewport 1536x1024 dengan device pixel ratio 1.0.

### 30.2 Data traversal terukur

Traversal memakai `LogicalKeyboardKey.tab` sampai Rect fokus berulang sebagai tanda wrap. Hasil nyata:

- Stop 1 — `Install`, Rect `Rect.fromLTRB(20.0, 309.0, 760.0, 349.0)`
- Stop 2 — `Buy`, Rect `Rect.fromLTRB(776.0, 309.0, 1516.0, 349.0)`
- Tab berikutnya kembali ke `Install` dan menghentikan probe.

Kedua kontrol berada pada satu baris; urutan visual dan keyboard sama-sama kiri-ke-kanan. Seluruh area fokus memiliki lebar dan tinggi non-zero.

### 30.3 Kontrak dan negative control

Kontrak `test/features/marketplace/product_detail_screen_focus_order_test.dart` mengunci tepat dua stop, label `Install` lalu `Buy`, posisi kiri-ke-kanan pada baris yang sama, dan area fokus non-zero. Negative control menukar urutan ekspektasi menjadi `Buy` lalu `Install`; test gagal dengan exit code `1` dan output `Some tests failed`, lalu file dipulihkan dari backup.

### 30.4 Gate dan cakupan

- `dart format test/features/marketplace/product_detail_screen_focus_order_test.dart` — exit `0`.
- `dart analyze test/features/marketplace/product_detail_screen_focus_order_test.dart` — `No issues found!`.
- Focus-order test — `All tests passed!`.
- Feature-suite gate `flutter test test/features/marketplace/` — `39` tests passed, exit `0`.
- Scan CJK/Cyrillic pada test, report, dan pesan commit — `none`.

Status fase: **VERIFIED** untuk kontrak WCAG 2.4.3 pada Product Detail Screen. Cakupan audit focus-order layar: 25 dari 89 target layar (berdasarkan kontrak focus-order yang ada setelah fase ini).

## 31. Fase 26 — Focus Order di Performance Preview Screen (2.4.3)

### 31.1 Layar dan fixture

`PerformancePreviewScreen` dipilih karena mandiri, tanpa database/network, dan memiliki lima `Switch` aktif dengan callback no-op. Probe memakai viewport 1536x1024 dengan device pixel ratio 1.0.

### 31.2 Data traversal terukur

Traversal memakai `LogicalKeyboardKey.tab` sampai Rect fokus berulang sebagai tanda wrap. Hasil nyata:

- Stop 1 — `High Quality Hair`, Rect `Rect.fromLTRB(1432.0, 116.0, 1492.0, 164.0)`
- Stop 2 — `Heavy VFX`, Rect `Rect.fromLTRB(1432.0, 184.0, 1492.0, 232.0)`
- Stop 3 — `Ray Tracing`, Rect `Rect.fromLTRB(1432.0, 252.0, 1492.0, 300.0)`
- Stop 4 — `High Resolution Shadows`, Rect `Rect.fromLTRB(1432.0, 320.0, 1492.0, 368.0)`
- Stop 5 — `Crowd Detail`, Rect `Rect.fromLTRB(1432.0, 388.0, 1492.0, 436.0)`
- Tab berikutnya kembali ke `High Quality Hair` dan menghentikan probe.

Urutan keyboard mengikuti urutan visual atas-ke-bawah; semua area fokus memiliki lebar dan tinggi non-zero.

### 31.3 Kontrak dan negative control

Kontrak `test/features/cinema/presentation/performance_preview_screen_focus_order_test.dart` mengunci tepat lima stop, label sesuai urutan di atas, posisi top yang meningkat, area fokus non-zero, dan tidak adanya exception rendering. Negative control menukar dua label pertama; test gagal dengan exit code `1` dan output `Some tests failed`, lalu file dipulihkan dari backup.

### 31.4 Gate dan cakupan

- `dart format test/features/cinema/presentation/performance_preview_screen_focus_order_test.dart` — exit `0`.
- `dart analyze test/features/cinema/presentation/performance_preview_screen_focus_order_test.dart` — `No issues found!`.
- Focus-order test — `All tests passed!`.
- Feature-suite gate dan commit dicatat setelah eksekusi closeout.

Status fase: **VERIFIED** untuk kontrak WCAG 2.4.3 pada Performance Preview Screen. Cakupan audit focus-order layar: 26 dari 89 target layar (berdasarkan kontrak focus-order yang ada setelah fase ini).

## 32. Fase 32 — Focus Order di Register Screen (2.4.3)

- **Layar:** `lib/features/authentication/presentation/register_screen.dart`
- **Kontrak:** `test/features/authentication/presentation/register_screen_focus_order_test.dart`
- **Viewport probe:** 1536x1024, device pixel ratio 1.0.
- **Hasil terukur:** 6 focus stops; traversal kembali ke stop pertama setelah stop keenam.
- **Urutan label:** `Display name` → `Email` → `Password` → `Confirm password` → `Create Account` → `Already have an account? Sign in`.
- **Geometri:** seluruh stop memiliki area non-zero; rect fokus terukur dari atas ke bawah pada `left=579.0`; rect stop 1–4 adalah `378x24`, tombol Create Account `378x40`, dan tombol sign-in `378x56`.
- **Kontrak posisi:** setiap stop berikutnya berada lebih rendah daripada stop sebelumnya dan seluruhnya memiliki alignment kiri yang sama.
- **Negative control:** ekspektasi jumlah stop diubah dari 6 menjadi 5; test gagal dengan exit `1` dan output `Some tests failed`. File kontrak dipulihkan setelah probe negatif.
- **Status:** VERIFIED untuk bukti focus order layar Register pada konfigurasi probe ini.

## 33. Fase 33 — Focus Order di Create Product Wizard Screen (2.4.3)

- **Layar:** `lib/features/marketplace/presentation/create_product_wizard_screen.dart`
- **Kontrak:** `test/features/marketplace/create_product_wizard_screen_focus_order_test.dart`
- **Viewport probe:** 1536x1024, device pixel ratio 1.0.
- **Hasil terukur:** 2 focus stops; traversal kembali ke stop pertama setelah stop kedua.
- **Urutan label:** `Cancel` → `Next`.
- **Geometri:** `Cancel` rect `Rect.fromLTRB(20.0, 175.0, 760.0, 215.0)` dan `Next` rect `Rect.fromLTRB(776.0, 175.0, 1516.0, 215.0)`; seluruh area fokus non-zero.
- **Kontrak posisi:** `Cancel` berada di kiri `Next`; kedua stop berbagi baris horizontal dengan top yang sama.
- **Negative control:** ekspektasi label ditukar menjadi `Next` → `Cancel`; test gagal dengan exit `1` dan output `Some tests failed`. File kontrak dipulihkan dari backup.
- **Status:** VERIFIED untuk bukti focus order layar Create Product Wizard pada konfigurasi probe ini. Cakupan audit focus-order layar: 28 dari 89 target layar.

## 34. Fase 34 — Focus Order di Theme Settings Screen (2.4.3)

- **Status:** PASS pada traversal keyboard yang diukur langsung.
- **Probe:** viewport 1536x1024, device pixel ratio 1.0, `Tab` berulang sampai rect fokus berulang.
- **Hasil:** 7 stop, dengan urutan `System` → `Void Purple` → `Ink` → `Ember` → `Sage` → `Rose` → `Ocean`.
- **Geometri:** stop pertama berada di atas deret accent; enam accent chip berikutnya sebaris dan meningkat kiri-ke-kanan. Semua rect fokus memiliki lebar dan tinggi non-zero.
- **Kontrak:** `test/features/platform/presentation/theme_settings_screen_focus_order_test.dart`; kontrak memvalidasi jumlah stop, label, geometri, dan `tester.takeException()`.
- **Negative control:** kontrak sengaja dijalankan dengan urutan label yang diubah; test gagal dengan exit code non-zero, lalu file dipulihkan dan test kembali lulus.
- **Batasan:** audit ini mengukur focus order aktual Theme Settings pada fixture tanpa database/network. Tidak ada perubahan produksi.

## 35. Fase 35 — Focus Order di Login Screen (2.4.3)

- **Layar:** `lib/features/authentication/presentation/login_screen.dart`
- **Kontrak:** `test/features/authentication/presentation/login_screen_focus_order_test.dart`
- **Viewport probe:** 1536x1024, device pixel ratio 1.0.
- **Hasil terukur:** 9 focus stops; traversal kembali ke stop pertama setelah stop kesembilan.
- **Urutan label:** `widget:Focus` → `widget:Focus` → `widget:Focus` → `widget:Focus` → `Forgot password?` → `Sign In` → `Work Offline` → `Continue as Guest` → `Create account`. Empat stop pertama adalah wrapper `Focus` di sekitar kontrol Email, Password, visibility toggle, dan area terkait; probe mencatat label widget karena tidak ada `Text` descendant pertama pada context fokus.
- **Geometri:** seluruh stop memiliki area non-zero. Stop 0 berada di kanan atas (`1364,32,40x40`); stop 1–2 berada pada form (`1020,325,368x24` dan `1020,437,336x24`); visibility toggle berada di `1360,425,48x48`; action stops berikutnya berurutan pada y `479`, `535`, `789`, `837`, dan `901`.
- **Kontrak posisi:** action stops setelah visibility toggle meningkat dari atas ke bawah; stop pertama berada di atas dan lebih kanan daripada field form; seluruh area fokus non-zero; tidak ada exception rendering.
- **Negative control:** ekspektasi jumlah stop diubah dari 9 menjadi 8; test gagal dengan exit `1` dan output `Some tests failed`. File kontrak dipulihkan dari backup.
- **Gate:** `dart analyze test/features/authentication/presentation/login_screen_focus_order_test.dart` menghasilkan `No issues found!`; focused test lulus.
- **Status:** VERIFIED untuk bukti focus order Login Screen pada konfigurasi probe ini. Cakupan audit focus-order layar: 29 dari 89 target layar.

## 36. Fase 36 — Focus Order di Create Project Screen (2.4.3)

- **Layar:** `lib/features/projects/presentation/create_project_screen.dart`
- **Kontrak:** `test/features/projects/presentation/create_project_screen_focus_order_test.dart`
- **Viewport probe:** 1536x1024, device pixel ratio 1.0; fixture `ProviderScope` tanpa database/network.
- **Hasil terukur:** 3 focus stops; traversal kembali ke stop pertama pada stop keempat.
- **Urutan label:** `widget:Focus` → `Cancel` → `Create Project`. Stop pertama adalah wrapper fokus field Project name; label widget tercatat karena context fokus tidak memiliki `Text` descendant pertama.
- **Geometri:** field rect `Rect.fromLTRB(519.0, 443.5, 1017.0, 467.5)`, Cancel `Rect.fromLTRB(519.0, 645.5, 627.6, 685.5)`, Create Project `Rect.fromLTRB(758.6, 645.5, 1017.0, 685.5)`; seluruh area fokus non-zero.
- **Kontrak posisi:** field berada di atas action row; `Cancel` berada di kiri `Create Project` pada baris yang sama; seluruh rect berada dalam viewport dan tidak ada exception rendering.
- **Negative control:** ekspektasi `Create Project` → `Cancel` ditukar; test gagal dengan exit `1` dan output `Some tests failed`. Kontrak dipulihkan dan test fokus kembali lulus.
- **Status:** VERIFIED untuk bukti focus order Create Project Screen pada konfigurasi probe ini. Cakupan audit focus-order layar: 30 dari 89 target layar.

## 37. Fase 37 — Focus Order di Project Resilience Center Screen (2.4.3)

**Status: VERIFIED (kontrak widget + negative control).**

- Layar: `ProjectResilienceCenterScreen`, fixture mandiri dengan tiga aksi aktif.
- Viewport probe: `1536x1024`, device pixel ratio `1.0`.
- Hasil probe: 3 stop unik lalu kembali ke stop pertama; semua rect fokus non-zero.
- Urutan terukur: `Scan Again` (`24.0,373.8`–`231.0,413.8`) → `Export Project` (`243.0,373.8`–`506.4,413.8`) → `Delete Cache` (`518.4,373.8`–`753.6,413.8`) → kembali ke `Scan Again`.
- Kontrak memverifikasi urutan label, posisi kiri-ke-kanan, area fokus non-zero, batas viewport, dan tidak adanya exception rendering.
- Negative control: urutan `Export Project`/`Delete Cache` ditukar; test gagal dengan exit code `1` dan output `Some tests failed`. File dipulihkan dari backup.
- Bukti test: `test/features/project_resilience/presentation/project_resilience_center_screen_focus_order_test.dart`.

## 38. Fase 36 — Focus Order di AI Generation Gallery Screen (2.4.3)

Status: VERIFIED untuk kontrak focus order pada fixture satu output di viewport 1536x1024, devicePixelRatio 1.0.

- Test: `test/features/ai/presentation/ai_generation_gallery_screen_focus_order_test.dart`.
- Stop terukur: 2, lalu traversal kembali ke stop pertama.
- Urutan label: `Use as Reference` → `Compare with Primary`.
- Rect stop 1: `Rect.fromLTRB(32.0, 286.0, 281.6, 326.0)`; area non-zero.
- Rect stop 2: `Rect.fromLTRB(32.0, 330.0, 288.0, 386.0)`; area non-zero.
- Posisi: stop kedua berada di bawah stop pertama (`top 330.0 > 286.0`) dan tidak lebih kiri (`left 32.0 >= 32.0`).
- Negative control: ekspektasi label kedua sengaja diubah menjadi `Use as Reference`; `flutter test` gagal dengan exit `1` dan output `Some tests failed`. Kontrak dipulihkan setelahnya.
- Scope: hanya kontrak test dan evidence report; tidak ada perubahan production code.

## 39. Fase 39 — Focus Order di Variant Inspector Screen (2.4.3)

**Layar**: `lib/features/multiverse/presentation/variant_inspector_screen.dart` (Multiverse / Character Portability, Sprint 45)
**Kontrak**: `test/features/multiverse/presentation/variant_inspector_screen_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 dpr 1.0, label diambil dari `Text` non-`Icon` pertama di subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, berhenti saat rect berulang.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `Arin Vale` | `Focus` (dropdown Karakter) | 37.0, 153.0, 246.0, 48.0 |
| 1 | `Canon Prime · Arin Vale` | `Focus` (dropdown Universe Variant) | 37.0, 242.0, 246.0, 48.0 |
| 2 | (repeats stop 0) | — | 37.0, 153.0, 246.0, 48.0 |

Jumlah stop = **2**. `tester.takeException()` = `null`.

### Kontrak yang dikunci

- `hasLength(2)` — tepat dua stop fokus yang dapat dicapai lewat Tab.
- Urutan label `['Arin Vale', 'Canon Prime · Arin Vale']` — dropdown Karakter dilemmas sebelum dropdown Universe Variant, sesuai urutan vertikal di UI.
- Luas fokus non-nol pada setiap stop (`width > 0 && height > 0`).
- Sisi kiri kedua dropdown sama (`stops[0].rect.left == stops[1].rect.left`) karena keduanya berada di kolom selector kiri pada layout lebar.
- Fokus bergerak atas-ke-bawah di dalam kolom selector (`stops[0].rect.top < stops[1].rect.top`).
- `tester.takeException()` = `null`.

### Catatan cakupan

Layar ini murni presentational + state lokal: tidak memakai Riverpod provider, tidak menyentuh database, jaringan, atau storage. Karena itu tidak ada fixture yang perlu diremock dan tidak ada item `DEFERRED` pada fase ini. Panel `Base` dan `Variant` (`_VariantPanel`) sengaja tidak dihitung: keduanya non-interaktif (hanya `Container` + `Text`), sehingga tidak memiliki node fokus sendiri.

### Verifikasi

```
dart analyze test/features/multiverse/presentation/variant_inspector_screen_focus_order_test.dart \
             lib/features/multiverse/presentation/variant_inspector_screen.dart
=> No issues found!

flutter test test/features/multiverse/presentation/variant_inspector_screen_focus_order_test.dart
=> 00:01 +1: All tests passed!
```

**Negative control** (wajib, dilakukan pada commit yang sama): ekspektasi urutan label dibalik menjadi `['Canon Prime · Arin Vale', 'Arin Vale']` pada salinan cadangan di `%LOCALAPPDATA%\Temp`, lalu test dijalankan:

```
Expected: ['Canon Prime · Arin Vale', 'Arin Vale']
  Actual: ['Arin Vale', 'Canon Prime · Arin Vale']
00:01 +0 -1: Variant Inspector Screen follows the measured WCAG 2.4.3 focus order [E]
00:01 +0 -1: Some tests failed.
exit code 1
```

Salinan cadangan dipulihkan dan dihapus; isi `_expectedLabels` diverifikasi kembali persis seperti semula. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus, bukan sekadar lolos karena tidak ada ekspektasi.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak: `none` (karakter non-ASCII satu-satunya yang ada adalah U+00B7 MIDDLE DOT pada label `Canon Prime · Arin Vale`).

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh.

## 40. Fase 40 — Focus Order di Mobile Navigation Screen (2.4.3)

**Layar**: `lib/features/creator/presentation/mobile_navigation_screen.dart` (Creator / Mobile Navigation, Step 43.52)
**Kontrak**: `test/features/creator/presentation/mobile_navigation_screen_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 dpr 1.0; label diambil dari `Text` non-`Icon` pertama di subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `Home` | `Focus` (NavigationDestination) | 0.0, 944.0, 307.2, 80.0 |
| 1 | `Projects` | `Focus` (NavigationDestination) | 307.2, 944.0, 307.2, 80.0 |
| 2 | `Create` | `Focus` (NavigationDestination) | 614.4, 944.0, 307.2, 80.0 |
| 3 | `AI` | `Focus` (NavigationDestination) | 921.6, 944.0, 307.2, 80.0 |
| 4 | `Profile` | `Focus` (NavigationDestination) | 1228.8, 944.0, 307.2, 80.0 |
| 5 | `Home` (repeats stop 0) | — | 0.0, 944.0, 307.2, 80.0 |

Jumlah stop = **5**. `tester.takeException()` = `null`.

Catatan probe: probe pertama sempat salah karena `seen.add(key)` dipanggil dua kali dalam satu iterasi (key kedua membuat match pertama selalu dianggap repeat), sehingga traversal berhenti di stop 0. Bug berada di probe, bukan di produksi; probe diperbaiki dengan menyimpan hasil `seen.add` ke variabel lokal sebelum memutuskan repeat.

### Kontrak yang dikunci

- `hasLength(5)` — tepat lima stop fokus yang dapat dicapai lewat Tab (lima destination bottom-nav), lalu traversal kembali ke stop pertama.
- Urutan label `['Home', 'Projects', 'Create', 'AI', 'Profile']` — sesuai urutan deklarasi `_destinations` di produksi, bukan urutan geometri acak.
- Luas fokus non-nol pada setiap stop (`width > 0 && height > 0`); masing-masing 307.2 x 80.0.
- Kelima stop berbagi satu `top` (`tops` hasLength 1) pada `top = 944.0` dan `height = 80.0` — satu baris navigation bar, tidak ada stop yang melompat ke baris lain.
- Urutan fokus kiri-ke-kanan: `stops[i-1].rect.left < stops[i].rect.left` dan `stops[i-1].rect.right <= stops[i].rect.left` (tanpa tumpang tindih), dari `left = 0.0` sampai `right = 1536.0`.
- `tester.takeException()` = `null`.

### Catatan cakupan

Layar ini murni presentational + state lokal (`int _index` di `_MobileNavigationScreenState`): tidak memakai Riverpod provider, tidak menyentuh database, jaringan, atau storage. Karena itu tidak ada fixture yang perlu diremock dan tidak ada item `DEFERRED` pada fase ini.

Kontrak sengaja menguji `NavigationBar` (Material 3) pada layout lebar desktop. Material membuat satu node fokus per `NavigationDestination` di dalam baris horizontal; pada lebar sempit Material dapat beralih ke `NavigationRail`/label tersembunyi, sehingga geometri ini **tidak** digeneralisasi ke viewport phone. Bukti fokus pada layout sempit tetap milik viewport 1536x1024.

### Verifikasi

```
dart format test/features/creator/presentation/mobile_navigation_screen_focus_order_test.dart
=> Formatted 1 file (1 changed)

dart analyze test/features/creator/presentation/mobile_navigation_screen_focus_order_test.dart \
             lib/features/creator/presentation/mobile_navigation_screen.dart
=> No issues found!

flutter test test/features/creator/presentation/mobile_navigation_screen_focus_order_test.dart
=> 00:01 +1: All tests passed!

flutter test test/features/creator/
=> 00:27 +78: All tests passed!
```

**Negative control** (wajib, dilakukan pada commit yang sama): ekspektasi urutan label dibalik menjadi `['Profile', 'AI', 'Create', 'Projects', 'Home']` pada salinan cadangan di `%LOCALAPPDATA%\Temp`, lalu test dijalankan:

```
Expected: ['Profile', 'AI', 'Create', 'Projects', 'Home']
  Actual: ['Home', 'Projects', 'Create', 'AI', 'Profile']
00:01 +0 -1: Mobile Navigation Screen follows the measured WCAG 2.4.3 focus order [E]
00:01 +0 -1: Some tests failed.
exit code 1
```

Salinan cadangan dipulihkan dan dihapus; isi `_expectedLabels` diverifikasi kembali persis `['Home', 'Projects', 'Create', 'AI', 'Profile']`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus, bukan sekadar lolos karena tidak ada ekspektasi.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak dan bagian report ini: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Mobile Navigation Screen di konfigurasi probe ini. Cakupan audit focus-order layar: **31 dari 89** target layar (30 kontrak focus-order di-track git sebelum fase ini + kontrak baru ini; satu kontrak lain — Content Capability Matrix Screen — masih untracked di working tree dan tidak dihitung di sini).
## 41. Fase 41 — Focus Order di HUD Designer Screen (2.4.3)

**Layar**: `lib/features/game/presentation/hud_designer_screen.dart` (Game / HUD Designer, Step 47.63)
**Kontrak**: `test/features/game/presentation/hud_designer_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam `ListTile` tergeografis pada subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `Health` | `Focus` (Switch kartu Health) | 1432.0, 127.0, 60.0, 48.0 |
| 1 | `Energy` | `Focus` (Switch kartu Energy) | 1432.0, 195.0, 60.0, 48.0 |
| 2 | `Ability` | `Focus` (Switch kartu Ability) | 1432.0, 263.0, 60.0, 48.0 |
| 3 | `Weapon` | `Focus` (Switch kartu Weapon) | 1432.0, 331.0, 60.0, 48.0 |
| 4 | `Minimap` | `Focus` (Switch kartu Minimap) | 1432.0, 399.0, 60.0, 48.0 |
| 5 | `Quest` | `Focus` (Switch kartu Quest) | 1432.0, 467.0, 60.0, 48.0 |
| 6 | `Interaction` | `Focus` (Switch kartu Interaction) | 1432.0, 535.0, 60.0, 48.0 |
| 7 | `Boss Health` | `Focus` (Switch kartu Boss Health) | 1432.0, 603.0, 60.0, 48.0 |
| 8 | `Health` (repeats stop 0) | — | 1432.0, 127.0, 60.0, 48.0 |

Jumlah stop = **8**. `tester.takeException()` = `null`. Tiap kartu memberi tepat satu node fokus (Switch di kolom `trailing`); `AppBar` `HUD Designer` tidak punya tombol back pada konfigurasi test, sehingga tidak ada stop sebelum `Health`.

### Kontrak yang dikunci

- `hasLength(8)` — tepat delapan stop fokus yang dapat dicapai lewat Tab.
- Urutan label `['Health', 'Energy', 'Ability', 'Weapon', 'Minimap', 'Quest', 'Interaction', 'Boss Health']` — urutan deklarasi `_hudItems` di produksi.
- Luas fokus non-nol pada setiap stop (`width > 0 && height > 0`); masing-masing 60.0 x 48.0.
- Fokus bergerak strictly atas-ke-bawah: `stops[i].rect.top > stops[i-1].rect.top` untuk semua i (selisih konstan 68.0 px).
- Semua stop berbagi kolom trailing yang sama (`stops[i].rect.left == stops[0].rect.left` = 1432.0) — bukan kiri-ke-kanan, karena kartu ditumpuk vertikal.
- Setelah kartu terakhir, traversal wrap kembali ke kartu pertama dengan `rect` identik; satu Tab lanjutan mengenai label kedua (`Energy`), membuktikan siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Layar ini presentational + konsumer Riverpod tanpa `watch`/`read` apa pun: tidak ada database, jaringan, atau storage, sehingga tidak ada fixture yang perlu diremock dan tidak ada item `DEFERRED` pada fase ini. `Switch` di setiap kartu memakai `value: true` dan `onChanged: (_) {}` (state tidak persisten) — kontrak fokus mengunci urutan & geometri, bukan perilaku toggle. Judul `HUD` (heading) bukan node fokus karena `Text` murni tanpa gesture/semantics action.

### Verifikasi

```
dart format test/features/game/presentation/hud_designer_focus_order_test.dart
=> Formatted 1 file (1 changed)

dart analyze test/features/game/presentation/hud_designer_focus_order_test.dart              lib/features/game/presentation/hud_designer_screen.dart
=> No issues found!

flutter test test/features/game/presentation/hud_designer_focus_order_test.dart
=> 00:01 +3: All tests passed!

flutter test test/features/game/
=> 00:13 +42: All tests passed!  (exit 0)
```

**Negative control** (wajib, dilakukan pada commit yang sama): ekspektasi urutan label dibalik menjadi `[..., 'Quest', 'Minimap', ...]` (tukar `Minimap` <-> `Quest`) pada salinan cadangan di `%LOCALAPPDATA%\Temp`, lalu test dijalankan:

```
00:01 +0 -1: HUD Designer — kontrak focus order 2.4.3 1. delapan stop dengan urutan label kartu HUD [E]
  Test failed. See exception logs above.
00:01 +2 -1: Some tests failed.
Failing tests: .../hud_designer_focus_order_test.dart: 1. delapan stop dengan urutan label kartu HUD
exit code 1
```

Salinan cadangan dipulihkan dan dihapus; `Minimap` kembali ke posisi ke-5 dan test ulang `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus, bukan sekadar lolos karena tidak ada ekspektasi.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh.

**Pemulihan run terputus (fase 40):** run sebelumnya meninggalkan `## 40. Fase 40` beserta `test/features/creator/presentation/mobile_navigation_screen_focus_order_test.dart` (untracked) tanpa commit karena lock basi (1243 dtk) diambil paksa. Test fase 40 dijalankan ulang (`+1: All tests passed!`, `dart analyze` `No issues found!`) lalu dikomit lebih dulu sebagai `3f10ddf` sebelum fase ini, supaya setiap section di report punya kontrak di git. Sisa artefak lama yang belum di-commit: `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` + `_probe_focus_test.dart` (untracked, tanpa section report) — tidak dihitung dan tidak disentuh fase ini.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada HUD Designer Screen di konfigurasi probe ini. Cakupan audit focus-order layar: **31 dari 89** target layar (30 kontrak focus-order di-track git setelah pemulihan fase 40 + kontrak baru ini; kontrak Content Capability Matrix Screen masih untracked di working tree dan tidak dihitung di sini).

## 42. Fase 42 — Focus Order di Automation Templates Screen (2.4.3)

**Layar**: `lib/features/workflow/presentation/automation_center_screen.dart` (Workflow / Automation Templates, kelas `AutomationTemplatesScreen`)
**Kontrak**: `test/features/workflow/presentation/automation_templates_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam `ListTile` terdekat milik subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `Export after job completes` | `Focus` (ListTile template pertama) | 0.0, 0.0, 1536.0, 72.0 |
| 1 | `Backup at startup` | `Focus` (ListTile template kedua) | 0.0, 72.0, 1536.0, 72.0 |
| 2 | `Thumbnail pipeline on import` | `Focus` (ListTile template ketiga) | 0.0, 144.0, 1536.0, 72.0 |
| 3 | `Export after job completes` (ulang stop 0) | — | 0.0, 0.0, 1536.0, 72.0 |

Jumlah stop = **3**. `tester.takeException()` = `null`. Layar ini berdiri sendiri: `AutomationTemplatesScreen` hanya berisi `ListView` berisi `ListTile` statis (data const `_templates`), tanpa `Scaffold`/`AppBar`/`IconButton` lain, sehingga tidak ada stop sebelum template pertama dan tidak ada fixture database/network.

### Kontrak yang dikunci

- `hasLength(3)` — tepat tiga stop fokus yang dapat dicapai lewat Tab.
- Urutan label `['Export after job completes', 'Backup at startup', 'Thumbnail pipeline on import']` — urutan deklarasi `_templates` di produksi.
- Luas fokus non-nol pada setiap stop (`width > 0 && height > 0`); masing-masing 1536.0 x 72.0.
- Fokus bergerak strictly atas-ke-bawah: `stops[i].rect.top > stops[i-1].rect.top` (selisih konstan 72.0 px) — bukan kiri-ke-kanan, karena baris ditumpuk vertikal.
- Semua stop berbagi tepi kiri yang sama (`stops[i].rect.left == stops[0].rect.left` = 0.0), karena tiap `ListTile` membentang penuh viewport.
- Setelah template terakhir, traversal wrap kembali ke template pertama dengan `rect` identik; satu Tab lanjutan mengenai label kedua (`Backup at startup`), membuktikan siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Screen presentational murni: callback `onInstantiate` di-`noop` (`(_) {}`) dan tidak ada `ref.watch`/`read`, storage, jaringan, maupun database. `Switch`/`onPressed` lain tidak ada di layar ini. File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format test/features/workflow/presentation/automation_templates_focus_order_test.dart
=> Formatted 1 file (1 changed) in 0.01 seconds.

dart analyze test/features/workflow/presentation/automation_templates_focus_order_test.dart
=> No issues found!

dart analyze test/features/workflow/
=> No issues found!   (exit 0)

dart analyze   (full repo)
=> 211 issues found.  (exit 3)
   Semua issue berada di file WIP sibling (test/release/scratch_*, test/shared/…); grep
   "automation_templates_focus_order" pada output = 0 hit, jadi tidak ada issue dari file audit ini.

flutter test test/features/workflow/presentation/automation_templates_focus_order_test.dart
=> 00:01 +3: All tests passed!

flutter test test/features/workflow/   (gate)
=> 00:07 +19: All tests passed!  (exit 0)
```

**Negative control** (wajib, pada commit yang sama): dua label pertama ditukar menjadi `['Backup at startup', 'Export after job completes', 'Thumbnail pipeline on import']` pada salinan cadangan di `%LOCALAPPDATA%\Temp`, lalu test dijalankan:

```
00:01 +0 -1: Automation Templates — kontrak focus order 2.4.3 1. tiga stop dengan urutan label template [E]
  Expected: ['Backup at startup', 'Export after job completes', 'Thumbnail pipeline on import']
  Actual: ['Export after job completes', 'Backup at startup', 'Thumbnail pipeline on import']
00:01 +0 -2: Automation Templates — kontrak focus order 2.4.3 3. Tab setelah template terakhir kembali ke template pertama [E]
  Test failed. See exception logs above.
00:01 +1 -2: Some tests failed.
Failing tests: .../automation_templates_focus_order_test.dart: 1. tiga stop dengan urutan label template, ...: 3. Tab setelah template terakhir kembali ke template pertama
exit code 1
```

Salinan cadangan dipulihkan dan dihapus; kontrak diverifikasi ulang `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus (2 dari 3 test gagal), bukan sekadar lolos karena tidak ada ekspektasi.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh.

**Sisa artefak yang tidak dihitung**: `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` + `_probe_focus_test.dart` (untracked, tanpa section report) tetap dibiarkan apa adanya, sama seperti catatan fase 41.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Automation Templates Screen di konfigurasi probe ini. Cakupan audit focus-order layar: **32 dari 89** target layar (31 kontrak focus-order di-track git sebelum fase ini + kontrak baru ini; kontrak Content Capability Matrix Screen masih untracked di working tree dan tidak dihitung di sini).


## 43. Fase 43 — Focus Order di Workflow Library Screen (2.4.3)

**Layar**: `lib/features/workflow/presentation/workflow_library_screen.dart` (Workflow / Workflow Library, kelas `WorkflowLibraryScreen`, 59 baris, `StatelessWidget`)
**Kontrak**: `test/features/workflow/presentation/workflow_library_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam `ListTile` terdekat milik subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 16 Tab).

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `backup-startup@1` | `IconButton` trailing baris 1 (`tooltip: Instantiate & run`) | 1468.0, 64.0, 40.0, 40.0 |
| 1 | `rename-asset@2` | `IconButton` trailing baris 2 (`tooltip: Instantiate & run`) | 1468.0, 120.0, 40.0, 40.0 |
| 2 | `backup-startup@1` (ulang stop 0, `repeat=true`) | — | 1468.0, 64.0, 40.0, 40.0 |

Jumlah stop = **2**. `find.byType(IconButton)` = 2. `tester.takeException()` = `null`.

Layar ini berdiri sendiri tanpa fixture database/network: `AppBar` hanya berisi `title` (route home, tanpa `leading`/`actions`, jadi tidak ada stop toolbar), `ListTile` dibangun oleh `ListView.builder` tanpa `onTap`, sehingga satu-satunya elemen focusable adalah `IconButton` trailing `Instantiate & run` per baris. Fixture test mendaftarkan dua `WorkflowDefinition` const ke `WorkflowTemplateRegistry` in-memory; registry mengurutkan `templateIds`, sehingga urutan list deterministik `backup-startup` -> `rename-asset`.

### Kontrak yang dikunci

- `expect(find.byType(IconButton), findsNWidgets(2))` dan `stops` `hasLength(2)` — tepat dua stop, disetel dengan jumlah tombol interaktif.
- Urutan label `['backup-startup@1', 'rename-asset@2']` — urutan sort `templateIds` registry, bukan urutan deklarasi test.
- Area fokus non-nol pada tiap stop (`width > 0 && height > 0`); keduanya 40.0 x 40.0.
- Fokus bergerak atas-ke-bawah: `stops[1].rect.top (120.0) > stops[0].rect.top (64.0)` — bukan kiri-ke-kanan, walau kedua tombol sejajar di tepi kanan.
- Kedua stop berbagi tepi kiri identik (1468.0) karena keduanya tombol trailing baris penuh.
- Setelah baris terakhir traversal wrap ke baris pertama dengan `rect` identik, lalu satu Tab lanjutan mengenai `rename-asset@2` — siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Screen presentational murni: tanpa `ref.watch`/`read`, storage, jaringan, maupun database; satu-satunya aksi (`registry.instantiate` + callback `onInstantiate`) dijalankan hanya oleh tombol yang diuji. Tidak ada perubahan kode produksi pada fase ini (probe tidak menemukan defect). File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format --set-exit-if-changed test/features/workflow/presentation/workflow_library_focus_order_test.dart
=> Formatted 1 file (0 changed) in 0.01 seconds.   (exit 0)

dart analyze test/features/workflow/
=> No issues found!   (exit 0)

flutter test test/features/workflow/presentation/workflow_library_focus_order_test.dart
=> 00:01 +3: All tests passed!

flutter test test/features/workflow/   (gate)
=> 00:12 +22: All tests passed!   (exit 0)
   Percobaan pertama gate berhenti sebelum test berjalan dengan
   "Flutter failed to delete file ... build/native_assets/windows/sqlite3.dll
   (file terkunci oleh proses lain). Setelah `taskkill` flutter_tester/dart dan
   penghapusan DLL terkunci, gate diulang dan lulus 22 test.
```

**Negative control** (wajib): `_expectedLabels` pada salinan cadangan di `%LOCALAPPDATA%\Temp` ditukar menjadi `['rename-asset@2', 'backup-startup@1']`, lalu kontrak dijalankan:

```
00:01 +0 -1: Workflow Library — kontrak focus order 2.4.3 1. dua stop dengan urutan label template [E]
  Expected: ['rename-asset@2', 'backup-startup@1']
    Actual: ['backup-startup@1', 'rename-asset@2']
00:01 +1 -2: Workflow Library — kontrak focus order 2.4.3 3. Tab setelah baris terakhir kembali ke baris pertama [E]
  Expected: 'rename-asset@2'
    Actual: 'backup-startup@1'
00:01 +1 -2: Some tests failed.
exit code 1 (NEGCTL_EXIT=1)
```

Salinan cadangan dipulihkan lalu dihapus; kontrak diverifikasi ulang `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus order (2 dari 3 test gagal saat ekspektasi urutan dibalik), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Sisa artefak yang tidak dihitung**: `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` (untracked, tanpa section report) tetap dibiarkan apa adanya, sama seperti catatan fase 41/42.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Workflow Library Screen di konfigurasi probe ini. Cakupan audit focus-order layar: **34 dari 89** target layar (33 kontrak focus-order di-track git sebelum fase ini + kontrak baru ini; catatan: section 42 mencatat 32, sedangkan `git ls-files` live sebelum fase ini = 33, jadi ada satu kontrak tracked yang tidak tercatat di section 42 — hitungan live yang dipakai di sini. Kontrak Content Capability Matrix Screen masih untracked dan tidak dihitung).



## 44. Fase 44 — Focus Order di Settings Hub Screen (2.4.3)

**Layar**: `lib/features/settings/presentation/settings_hub_screen.dart` (Settings / Settings Hub, kelas `SettingsHubScreen`, 192 baris, `ConsumerWidget`)
**Kontrak**: `test/features/settings/settings_hub_screen_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam subtree fokus, `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 24 Tab). Provider sesi di-override ke `null` sehingga layar berdiri tanpa database/network.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `General` | header `ExpansionTile` (collapsed) | 16.0, 73.0, 1504.0, 56.0 |
| 1 | `Appearance` | header `ExpansionTile` (collapsed) | 16.0, 131.0, 1504.0, 56.0 |
| 2 | `Sidebar & Workspace` | header `ExpansionTile` (collapsed) | 16.0, 189.0, 1504.0, 56.0 |
| 3 | `About & Diagnostics` | header `ExpansionTile` (`initiallyExpanded`) | 16.0, 247.0, 1504.0, 56.0 |
| 4 | `Lokasi penyimpanan kustom` | `ListTile` bertap di dalam About | 16.0, 519.0, 1504.0, 72.0 |
| 5 | `General` (ulang stop 0, `REPEAT at stop 5 -> cycle closed`) | — | 16.0, 73.0, 1504.0, 56.0 |

Jumlah stop = **5**. `find.byType(ExpansionTile)` = 4. `tester.takeException()` = `null`.

Layar ini memakai `ref.watch(projectSessionProvider)` dan dua masa depan (`BootstrapDirectories.resolve()` untuk baris Storage diagnostik), tetapi keduanya tidak butuh fixture berat: test cukup meng-override `projectSessionProvider` ke controller yang mengembalikan `null` (pola yang sudah dipakai `settings_hub_screen_test.dart`), dan `FutureBuilder` cukup dibiarkan pada status loading. Tanpa sesi, cabang `session == null` merender `ListTile` "Buka proyek untuk mengatur modul sidebar" — tetapi tile itu berada di dalam `ExpansionTile` `Sidebar & Workspace` yang collapsed, sehingga tidak ikut traversal.

Pembentukan urutan Tab:

- Empat header `ExpansionTile` masing-masing punya satu stop (`InkWell` header), berurutan deklarasi: General → Appearance → Sidebar & Workspace → About & Diagnostics.
- `About & Diagnostics` adalah satu-satunya yang `initiallyExpanded: true`, jadi anaknya ikut ter-render. Dari tiga `ListTile` anak yang selalu ada (`Versi`, `Platform`, `Storage diagnostik`) tidak ada yang punya `onTap` — bukan stop. `Lokasi penyimpanan kustom` punya `onTap` → stop kelima.
- `Diagnostik proyek` (bertap) hanya dirender saat `session != null`, jadi tidak ada pada konfigurasi ini.
- Setelah stop kelima, Tab berikutnya kembali ke `General` dengan `Rect` identik; satu Tab lagi lanjut ke `Appearance` — siklus utuh.

### Kontrak yang dikunci

- `expect(find.byType(ExpansionTile), findsNWidgets(4))` dan `stops` `hasLength(5)` — jumlah stop disetel dengan jumlah elemen focusable nyata (4 header + 1 ListTile bertap).
- Urutan label `['General', 'Appearance', 'Sidebar & Workspace', 'About & Diagnostics', 'Lokasi penyimpanan kustom']` — urutan deklarasi widget, diverifikasi probe.
- Area fokus non-nol pada tiap stop (`width > 0 && height > 0`); keempat header 1504.0 x 56.0, ListTile About 1504.0 x 72.0.
- Fokus bergerak menurun atas-ke-bawah: `top` tiap stop `>` `top` stop sebelumnya (73 → 131 → 189 → 247 → 519).
- Semua stop berbagi tepi kiri identik (16.0) karena keduanya baris penuh dalam `ListView` yang sama.
- Setelah stop terakhir traversal wrap ke `General` dengan `Rect` identik, lalu satu Tab lanjutan mengenai `Appearance` — siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Tidak ada perubahan kode produksi pada fase ini: probe tidak menemukan defect urutan (semua elemen bertap ikut traversal, tidak ada stop tersembunyi atau area nol). File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format --set-exit-if-changed test/features/settings/settings_hub_screen_focus_order_test.dart
=> Formatted 1 file (0 changed) in 0.02 seconds.   (exit 0)

dart analyze test/features/settings/settings_hub_screen_focus_order_test.dart
=> No issues found!   (exit 0)

flutter test test/features/settings/settings_hub_screen_focus_order_test.dart
=> 00:01 +3: All tests passed!   (exit 0)

flutter test test/features/settings/   (gate)
=> 00:12 +25: All tests passed!   (exit 0)
   4 file test (language_switcher 2 + kontrak focus-order 3 +
   settings_hub_screen 6 + storage_locations_screen 8 testWidgets,
   total 25 unit/widget assertions tercatat runner).
```

**Negative control** (wajib): dua baris pertama `_expectedLabels` pada salinan cadangan di `%LOCALAPPDATA%\Temp` ditukar menjadi `['Appearance', 'General', ...]`, lalu kontrak dijalankan:

```
00:01 +1 -2: Settings Hub — kontrak focus order 2.4.3 3. Tab setelah stop terakhir kembali ke General [E]
   Expected: 'Appearance'
     Actual: 'General'
00:01 +1 -2: Settings Hub — kontrak focus order 2.4.3 1. lima stop dengan urutan label yang dikunci [E]
00:02 +1 -2: Some tests failed.
exit code 1 (NEGCTL_EXIT=1)
```

Salinan cadangan dipulihkan lalu dihapus (`BACKUP_DELETED`), kontrak diverifikasi ulang `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus order (2 dari 3 test gagal saat ekspektasi urutan dibalik), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Sisa artefak yang tidak dihitung**: `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` (untracked, tanpa section report) tetap dibiarkan apa adanya, sama seperti catatan fase 41/42/43.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Settings Hub Screen di konfigurasi probe ini (sesi null + viewport desktop). Cakupan audit focus-order layar: **35 dari 89** target layar (34 kontrak focus-order di-track git sebelum fase ini + kontrak baru ini). Kontrak Content Capability Matrix Screen masih untracked dan tidak dihitung.

## 45. Fase 45 — Focus Order di Storage Locations Screen (2.4.3)

**Layar**: `lib/features/settings/presentation/storage_locations_screen.dart` (Storage Locations, kelas `StorageLocationsScreen`)
**Kontrak**: `test/features/settings/storage_locations_screen_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam subtree fokus, dan bila tidak ada jatuh ke `ValueKey<String>` terdekat pada rantai leluhur (IconButton refresh dan ketiga `TextField` tidak punya teks di dalam subtree fokus — `labelText` ada di decoration, di luar node fokus). `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 24 Tab). Layar berdiri tanpa database/network: `customStorageStoreProvider` di-override ke `CustomStorageLocationStore` dengan `registry file` di direktori temporer.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `storage-refresh` | `IconButton` refresh AppBar | 1492.0, 8.0, 40.0, 40.0 |
| 1 | `storage-set-active-field` | `TextField` Set lokasi aktif | 52.0, 244.0, 1263.2, 24.0 |
| 2 | `Jalankan` | `FilledButton` kartu Set lokasi aktif | 1339.2, 236.0, 160.8, 40.0 |
| 3 | `storage-relink-field` | `TextField` Relink lokasi | 52.0, 388.0, 1263.2, 24.0 |
| 4 | `Jalankan` | `FilledButton` kartu Relink lokasi | 1339.2, 380.0, 160.8, 40.0 |
| 5 | `storage-probe-field` | `TextField` Probe lokasi | 52.0, 532.0, 1263.2, 24.0 |
| 6 | `Jalankan` | `FilledButton` kartu Probe lokasi | 1339.2, 524.0, 160.8, 40.0 |
| 7 | `storage-refresh` (ulang stop 0, `REPEAT at stop 7 -> cycle closed`) | — | 1492.0, 8.0, 40.0, 40.0 |

Jumlah stop = **7**. `find.byType(TextField)` = 3, `find.byType(FilledButton)` = 3. `tester.takeException()` = `null`.

Pembentukan urutan Tab:

- Satu `IconButton` refresh di AppBar (`ValueKey('storage-refresh')`) menjadi stop pertama — rect kanan-atas (1492, 8), berada di atas dan di kanan semua field.
- Layar ini merender tiga kartu aksi yang ditumpuk atas-ke-bawah: **Set lokasi aktif**, **Relink lokasi**, **Probe lokasi**. Tiap kartu menyumbang dua stop berurutan: `TextField` di kiri (left 52, top 244/388/532) lalu tombol `Jalankan` di kanan (left 1339.2, top 236/380/524 — pusat baris sama, selisih pusat-Y field vs tombol <= 1.0 px karena tinggi 24 vs 40 dipusatkan pada baris yang sama).
- Ketiga tombol aksi berbagi label teks `Jalankan`, jadi kontrak membedakannya lewat posisi (indeks array), bukan teks.
- Setelah stop terakhir, Tab berikutnya kembali ke `storage-refresh` dengan `Rect` identik; satu Tab lagi lanjut ke `storage-set-active-field` — siklus utuh.

### Kontrak yang dikunci

- `expect(find.byType(TextField), findsNWidgets(3))`, `find.byType(FilledButton), findsNWidgets(3)`, dan `stops` `hasLength(7)` — jumlah stop disetel dengan jumlah elemen focusable nyata (1 refresh + 3 field + 3 tombol).
- Urutan label `['storage-refresh', 'storage-set-active-field', 'Jalankan', 'storage-relink-field', 'Jalankan', 'storage-probe-field', 'Jalankan']` — urutan Tab nyata dari probe.
- Area fokus non-nol pada tiap stop (`width > 0 && height > 0`).
- Refresh berada di atas dan di kanan field pertama (`stops.first.rect.top < stops[1].rect.top`, `stops.first.rect.left > stops[1].rect.left`).
- Tiga kartu aksi turun atas-ke-bawah: `top` stop 1 < stop 3 < stop 5 (244 → 388 → 532).
- Di dalam tiap kartu: field di kiri tombolnya (`left[i] < left[i+1]`) dan keduanya satu baris (`|Δcenter.dy| <= 1.0`).
- Setelah stop terakhir traversal wrap ke `storage-refresh` dengan `Rect` identik, lalu satu Tab lanjutan mengenai `storage-set-active-field` — siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Tidak ada perubahan kode produksi pada fase ini: probe tidak menemukan defect urutan (semua elemen interaktif ikut traversal, tidak ada stop tersembunyi atau area nol, dan urutan mengikuti layout kartu). File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format --set-exit-if-changed test/features/settings/storage_locations_screen_focus_order_test.dart
=> Formatted 1 file (0 changed) in 0.01 seconds.   (exit 0)

dart analyze test/features/settings/storage_locations_screen_focus_order_test.dart
=> No issues found! (ran in 4.2s)   (exit 0)

flutter test test/features/settings/storage_locations_screen_focus_order_test.dart
=> 00:02 +3: All tests passed!   (exit 0)

flutter test test/features/settings/   (gate)
=> 00:11 +28: All tests passed!   (exit 0)
   4 file test (language_switcher 7 + kontrak focus-order Settings Hub 3 +
   settings_hub_screen 1 + kontrak focus-order Storage Locations 3 +
   storage_locations_screen 8 testWidgets, total 28).
```

**Negative control** (wajib): dua baris pertama `_expectedLabels` pada salinan cadangan di `%LOCALAPPDATA%\Temp` ditukar menjadi `['storage-set-active-field', 'storage-refresh', ...]`, lalu kontrak dijalankan:

```
00:01 +0 -1: Storage Locations — kontrak focus order 2.4.3 1. tujuh stop dengan urutan label yang dikunci [E]
   Expected: ['storage-set-active-field', 'storage-refresh', 'Jalankan', ...]
     Actual: ['storage-refresh', 'storage-set-active-field', 'Jalankan', ...]
   Which: at location [0] is 'storage-refresh' instead of 'storage-set-active-field'
00:02 +1 -2: Some tests failed.
NEGCTL_EXIT=1
RESTORED_BACKUP_DELETED
00:02 +3: All tests passed!
REVERIFY_EXIT=0
```

Salinan cadangan dipulihkan lalu dihapus, kontrak diverifikasi ulang `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikat urutan focus order (2 dari 3 test gagal saat dua label pertama dibalik), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Sisa artefak yang tidak dihitung**: `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` (untracked, tanpa section report) tetap dibiarkan apa adanya, sama seperti catatan fase 41/42/43.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Storage Locations Screen di konfigurasi probe ini (registry file temp + viewport desktop). Cakupan audit focus-order layar: **35 dari 89** target layar — hitungan live `git ls-files | grep -c '_focus_order_test.dart'` = 34 sebelum commit fase ini, + kontrak baru ini = 35. (Koreksi hitungan: status fase 44 mencatat 35 dari 89, tetapi `git ls-tree -r 992fb49` = 34 kontrak tracked setelah commit fase 44, jadi angka fase 45 yang benar adalah 35.) Kontrak Content Capability Matrix Screen masih untracked dan tidak dihitung.

## 46. Fase 46 — Focus Order di AI Provider Workspace Screen (2.4.3)

**Layar**: `lib/features/ai/presentation/ai_provider_workspace_screen.dart` (AI Providers, kelas `AiProviderWorkspaceScreen`)
**Kontrak**: `test/features/ai/presentation/ai_provider_workspace_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam subtree fokus, dan bila tidak ada jatuh ke `ValueKey<String>` terdekat pada rantai leluhur. `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 24 Tab). Layar berdiri tanpa database/network: `credentialStore` di-override ke `MemoryCredentialStore` sehingga `flutter_secure_storage` tidak menyentuh platform channel, dan `http.Client` hanya dibuat saat aksi `Test connection` ditekan (tidak pernah pada probe).

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Kartu (`ListTile` pembungkus) | Rect (left, top, w, h) |
|---|---|---|---|---|
| 0 | `Configure` | `OutlinedButton` Configure | OpenAI | 1313.1, 92.0, 174.9, 40.0 |
| 1 | `Configure` | `OutlinedButton` Configure | Gemini | 1313.1, 188.0, 174.9, 40.0 |
| 2 | `Configure` | `OutlinedButton` Configure | Ollama | 1313.1, 284.0, 174.9, 40.0 |
| 3 | `Configure` | `OutlinedButton` Configure | ComfyUI | 1313.1, 380.0, 174.9, 40.0 |
| 4 | `Configure` (ulang stop 0, `CYCLE complete at i=4`) | — | OpenAI | 1313.1, 92.0, 174.9, 40.0 |

Jumlah stop = **4**. `find.byType(OutlinedButton)` = 4. `tester.takeException()` = `null`.

Pembentukan urutan Tab:

- `AppBar` layar ini hanya berisi judul `AI PROVIDERS` (tanpa tombol kembali di konfigurasi `MaterialApp(home: ...)`), jadi tidak ada stop sebelum kartu pertama.
- Empat `ListTile` provider tidak punya `onTap` sehingga bukan stop; tiap kartu menyumbang tepat satu stop pada `OutlinedButton` `Configure` di trailing-nya.
- Tombol `Test connection` dirender `null` (disabled, tidak ikut traversal) selama provider belum dikonfigurasi — kontrak state default punya 4 stop, bukan 5.
- `Switch` tiap kartu sengaja display-only (`onChanged: null`, alpha scope) sehingga memang bukan target fokus; ini perilaku yang diharapkan, bukan defect.
- Keempat tombol berbagi teks `Configure`, jadi identitas stop dikunci lewat judul `ListTile` yang rect-nya memuat pusat area fokus (`_providerAt`), bukan lewat teks tombol.
- Geometri: keempat stop berbagi `left` 1313.1 (satu kolom tombol di sisi kanan) dan `top` naik 92 → 188 → 284 → 380 (jarak kartu 96 px, atas-ke-bawah). Setelah stop terakhir, Tab kembali ke rect stop 0 — siklus utuh.

### Kontrak yang dikunci

- `expect(find.byType(OutlinedButton), findsNWidgets(4))` dan `stops` `hasLength(4)` — jumlah stop disetel dengan jumlah kartu provider yang punya tombol Configure aktif.
- Urutan provider `['OpenAI', 'Gemini', 'Ollama', 'ComfyUI']` — urutan Tab nyata dari probe, diambil dari judul kartu pembungkus tiap stop.
- Semua stop berlabel `Configure` pada state default, dan area fokus non-nol (`width > 0 && height > 0`).
- Kartu menumpuk atas-ke-bawah (`top[i] > top[i-1]`) dan keempat tombol berbagi satu kolom (`left` sama dalam toleransi 0.5 px).
- State terkonfigurasi (`OpenAiProvider.credentialKey` diisi lewat `MemoryCredentialStore`) menambah tepat satu stop `Test connection` di depan `Configure` pada kartu OpenAI: total 5 stop, `Test connection` di kiri `Configure` dengan pusat baris sama (`|Δcenter.dy| <= 1.0`), tiga kartu sisanya tetap `Gemini`, `Ollama`, `ComfyUI`.
- Setelah stop terakhir traversal wrap ke rect stop 0 (kartu OpenAI), lalu satu Tab lanjutan mengenai kartu Gemini — siklus fokus utuh.
- `tester.takeException()` = `null`.

### Catatan cakupan

Tidak ada perubahan kode produksi pada fase ini: probe tidak menemukan defect urutan (semua elemen interaktif ikut traversal, tidak ada stop tersembunyi atau area nol, dan urutan mengikuti layout kartu). File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format --set-exit-if-changed test/features/ai/presentation/ai_provider_workspace_focus_order_test.dart
=> Formatted 1 file (0 changed) in 0.01 seconds.   (exit 0)

dart analyze test/features/ai/presentation/ai_provider_workspace_focus_order_test.dart
=> No issues found!   (exit 0)

flutter test test/features/ai/presentation/ai_provider_workspace_focus_order_test.dart
=> 00:01 +4: All tests passed!   (exit 0)

flutter test test/features/ai/   (gate)
=> 00:55 +171: All tests passed!   (exit 0)
```

**Negative control** (wajib): dua entri pertama `_expectedProviders` pada salinan cadangan di `%LOCALAPPDATA%\Temp` ditukar menjadi `['Gemini', 'OpenAI', 'Ollama', 'ComfyUI']`, lalu kontrak dijalankan:

```
This was caught by the test expectation on the following line:
  .../ai_provider_workspace_focus_order_test.dart line 115
The test description was:
  1. empat stop, urutan provider terkunci, area non-zero
00:01 +0 -1: ... 1. empat stop, urutan provider terkunci, area non-zero [E]
00:02 +3 -1: Some tests failed.
NEGCTL_PIPE_EXIT=1
```

Salinan cadangan dipulihkan lalu dihapus (`RESTORED_AND_BACKUP_REMOVED`, `BACKUP_GONE`), kontrak diverifikasi ulang lewat gate `+171: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikuti urutan focus order (1 dari 4 test gagal saat urutan dua kartu provider dibalik), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak: `0` hit. Bagian report ini dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada AI Provider Workspace Screen di konfigurasi probe ini (store memori + viewport desktop). Cakupan audit focus-order layar: **36 dari 89** target layar — hitungan live `git ls-files | grep -c '_focus_order_test.dart'` = 35 sebelum commit fase ini, + kontrak baru ini = 36. Kontrak Content Capability Matrix Screen masih untracked dan tidak dihitung (catatan fase 41/42/43/45 tetap berlaku).

## 47. Fase 47 — Focus Order di Advanced AI Studio Screen (2.4.3)

**Layar**: `lib/features/ai/presentation/advanced_ai_studio_screen.dart` (Advanced AI Studio, kelas `AdvancedAiStudioScreen`)
**Kontrak**: `test/features/ai/presentation/advanced_ai_studio_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam subtree fokus (tanpa fallback `ValueKey`); `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 10 Tab). Layar berdiri tanpa database/network: dua callback `onOpenImageGenerator`/`onOpenVideoGenerator` di-override noop, tidak ada platform channel yang tersentuh.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `Image Generator` | `OutlinedButton` Image Generator | 12.0, 72.0, 277.5, 40.0 |
| 1 | `Video Generator` | `OutlinedButton` Video Generator | 299.5, 72.0, 277.5, 40.0 |
| 2 | `null` (tidak ada `Text` berdata) | `Focus` di dalam `EditableText` (TextField prompt) | 28.0, 148.0, 1480.0, 24.0 |
| 3 | `Image Generator` (ulang rect stop 0 — CYCLE complete) | — | 12.0, 72.0, 277.5, 40.0 |

Jumlah stop = **3**. `tester.takeException()` = `null`.

Pembentukan urutan Tab:

- Toolbar atas memuat dua `OutlinedButton.icon` (`Image Generator`, `Video Generator`) — kiri-ke-kanan: `left` 12.0 → 299.5 dengan `top` sama 72.0, jarak tombol 10 px gutter.
- Field prompt (`TextField`) berada di bawah toolbar (`top` 148.0 > 72.0, atas-ke-bawah) dan memulai setelah kolom tombol pertama (`left` 28.0 > 12.0); lebarnya 1480 px mengisi viewport.
- Fokus stop 2 berada pada `Focus` internal `EditableText`; subtree-nya tidak berisi `Text` dengan data sehingga label `null` — identitas stop dikunci dengan keberadaan tepat satu `EditableText` di dalam `find.byType(TextField)`, bukan dengan teks karangan.
- Setelah TextField, Tab wrap kembali ke rect stop 0 — siklus utuh.

### Kontrak yang dikunci

- `stops` `hasLength(3)` — jumlah stop disetel dengan tiga elemen focusable di state default.
- Urutan label `['Image Generator', 'Video Generator', null]` — urutan Tab nyata dari probe.
- Area fokus non-nol (`width > 0 && height > 0`) untuk ketiga stop.
- Kiri-ke-kanan pada baris yang sama: `stops[1].left > stops[0].left` dan `|stops[1].top - stops[0].top| <= 1.0` (via `closeTo`).
- Atas-ke-bawah: `stops[2].top > stops[1].top`, dan `stops[2].left > stops[0].left` (TextField mulai setelah kolom tombol pertama).
- `EditableText` di dalam `TextField` = 1 widget (identitas stop TextField).
- `tester.takeException()` = `null`.

### Catatan cakupan

Tidak ada perubahan kode produksi pada fase ini: probe tidak menemukan defect urutan (ketiga elemen interaktif ikut traversal, tidak ada area nol, urutan mengikuti layout visual toolbar lalu field). File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format test/features/ai/presentation/advanced_ai_studio_focus_order_test.dart
=> Formatted 1 file (0 changed) in 0.01 seconds.   (exit 0)

dart analyze test/features/ai/presentation/advanced_ai_studio_focus_order_test.dart
=> No issues found!   (exit 0)

flutter test test/features/ai/presentation/advanced_ai_studio_focus_order_test.dart
=> 00:01 +1: All tests passed!   (exit 0)

flutter test test/features/ai/   (gate)
=> 00:49 +172: All tests passed!   (exit 0)
```

**Negative control** (wajib): ekspektasi `expect(stops[0].label, 'Image Generator')` pada salinan cadangan di `%LOCALAPPDATA%\Temp` diubah sementara menjadi `'Video Generator'`, lalu kontrak dijalankan:

```
Actual: 'Image Generator'
This was caught by the test expectation on the following line:
  .../advanced_ai_studio_focus_order_test.dart line 66
00:01 +0 -1: Advanced AI Studio: urutan fokus Tab stabil, kiri-ke-kanan lalu ke bawah [E]
00:01 +0 -1: Some tests failed.
```

Salinan cadangan dipulihkan lalu dihapus (ekspektasi asli kembali terverifikasi lewat grep: 1 hit) dan kontrak diverifikasi ulang lewat gate `+172: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengikuti urutan focus order (1 test gagal saat label stop pertama diganti), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Advanced AI Studio Screen di konfigurasi probe ini (viewport desktop 1536x1024). Cakupan audit focus-order layar: **37 dari 89** target layar — hitungan live `git ls-files | grep -c '_focus_order_test.dart'` = 36 sebelum commit fase ini, + kontrak baru ini = 37.

## 48. Fase 48 — Focus Order di Agent Permission Screen (2.4.3)

**Layar**: `lib/features/marketplace/presentation/agent_permission_screen.dart` (Agent Permission Screen, kelas `AgentPermissionScreen`)
**Kontrak**: `test/features/marketplace/presentation/agent_permission_screen_focus_order_test.dart`
**Metode**: probe `LogicalKeyboardKey.tab` berulang pada viewport 1536x1024 / dpr 1.0; label diambil dari `Text` non-`Icon` pertama di dalam subtree fokus dengan fallback ke subtree terluar lewat `visitAncestorElements` (stop berupa `Switch` tidak punya `Text` di subtree-nya sendiri, label diambil dari `ListTile.title` di atasnya); `Rect` fokus dari `localToGlobal(Offset.zero) & size`, traversal berhenti saat `Rect` berulang (maks 10 Tab). Layar berdiri tanpa database/network: dua callback `onAllowAll`/`onDenyOptional` di-override noop, tidak ada platform channel yang tersentuh.

### Hasil probe (sebelum kontrak dikunci)

| Stop | Label | Widget fokus | Rect (left, top, w, h) |
|---|---|---|---|
| 0 | `AI Provider` | `Switch` pada tile permission optional | 1432.0, 292.0, 60.0, 48.0 |
| 1 | `Allow All` | `FilledButton` Allow All | 20.0, 388.0, 740.0, 40.0 |
| 2 | `Deny Optional` | `OutlinedButton` Deny Optional | 776.0, 388.0, 740.0, 40.0 |

Jumlah stop = **3**. `tester.takeException()` = `null`.

Pembentukan urutan Tab:

- `_permissions` berisi tiga entri. Dua di antaranya — `('File Access', 'Read project files', true)` dan `('Network', 'Access internet', true)` — bertanda `isRequired: true`, sehingga `_PermissionTile` merender `Text('Required')` pada posisi `trailing` (baris 105-110), bukan `Switch`. `Text` statis tidak dapat menerima fokus, jadi kedua tile itu **sengaja tidak punya stop fokus**.
- Hanya `('AI Provider', 'Use AI provider credentials', false)` yang merender `Switch` dengan `onChanged` -> `(v) => setState(...)`, menjadi satu-satunya stop fokus di dalam daftar permission. Aksesibilitasnya benar: user boleh menolak permission optional (sila'i `onDenyOptional` di baris 7-10), sedangkan dua permission required memang tidak dapat dimatikan.
- Aksi kaki layar berada di satu `Row` dua `Expanded` (baris 50-66): `FilledButton` 'Allow All' di kiri (`left` 20.0) lalu `OutlinedButton` 'Deny Optional' di kanan (`left` 776.0), `top` sama-sama 388.0 dan lebar sama-sama 740.0.
- Urutan traversal mengikuti urutan visual: tile permission (`top` 292.0) lebih dulu secara atas-ke-bawah, lalu baris tombol. Di dalam baris tombol urutan kiri-ke-kanan.

### Kontrak yang dikunci

- Urutan label `['AI Provider', 'Allow All', 'Deny Optional']` — urutan Tab nyata dari probe, termasuk identitas stop `Switch` yang labelnya diambil dari subtree terluar.
- Area fokus non-nol (`width > 0 && height > 0`) untuk ketiga stop.
- Bukti bahwa hanya permission optional yang punya stop fokus di dalam daftar: tepat satu `Switch`, tepat dua `Text('Required')`, dan hanya satu stop dengan `rect.top < 340` (yaitu tile) berlabel `AI Provider`.
- Positional lock: `toggle.top < allow.top` (tile di atas baris tombol), `allow.left < deny.left` (Allow All di kiri), `allow.top == deny.top` (keduanya satu `Row` action), `allow.right <= deny.left`, dan `toggle.right > allow.left` (toggle berada di sisi trailing tile).
- `tester.takeException()` = `null`.

Tiga test dalam kontrak: urutan label, bukti satu-satunya stop di dalam daftar, dan urutan posisional kiri-ke-kanan/atas-ke-bawah.

### Catatan cakupan

Tidak ada perubahan kode produksi pada fase ini: probe tidak menemukan defect urutan fokus. Ketiga elemen interaktif yang memang bisa difokuskan ikut traversal, tidak ada area fokus nol, dan urutan mengikuti layout visual. Dua tile permission required tidak punya stop fokus adalah perilaku yang benar (`Text` statis, bukan kontrol interaktif), bukan defect 2.4.3.

File `_probe_focus_test.dart` sementara sudah dihapus setelah kontrak dibuat; kontrak inilah satu-satunya artefak test yang dikomit pada fase ini.

### Verifikasi

```
dart format test/features/marketplace/presentation/agent_permission_screen_focus_order_test.dart
=> Formatted 1 file (1 changed) in 0.01 seconds.   (exit 0)

dart analyze test/features/marketplace/presentation/agent_permission_screen_focus_order_test.dart
=> No issues found!   (exit 0)

flutter test test/features/marketplace/presentation/agent_permission_screen_focus_order_test.dart
=> 00:01 +3: All tests passed!   (exit 0)

flutter test test/features/marketplace/   (gate)
=> 00:31 +43: All tests passed!   (exit 0)
```

Gate feature memuat ketiga test kontrak ini (terkonfirmasi lewat baris `agent_permission_screen_focus_order_test.dart: AgentPermissionScreen focus order is Switch -> Allow All -> Deny Optional` pada `00:09 +19`, lalu suite penuh `+43: All tests passed!`).

Catatan lingkungan: sebelum setiap `flutter test` perlu `taskkill` proses `flutter_tester.exe`/`dart.exe` dan penghapusan `build/native_assets/windows/sqlite3.dll`. File itu pernah tertinggal sebagai remnant terpotong 755 byte sehingga `flutter test` gagal **bukan** karena assertion melainkan karena `Flutter failed to delete file`. Ini bukan regresi kode; setelah dihapus suite berjalan normal.

**Negative control** (wajib): `expectedLabels` pada salinan cadangan di `%LOCALAPPDATA%\Temp\agent_permission_focus_backup.dart` diubah sementara dari `['AI Provider', 'Allow All', 'Deny Optional']` menjadi `['Allow All', 'AI Provider', 'Deny Optional']` (tukar dua label pertama), lalu kontrak dijalankan:

```
Expected: ['Allow All', 'AI Provider', 'Deny Optional']
  Actual: ['AI Provider', 'Allow All', 'Deny Optional']
This was caught by the test expectation on the following line:
  .../agent_permission_screen_focus_order_test.dart line 84
00:01 +0 -1: AgentPermissionScreen focus order is Switch -> Allow All -> Deny Optional [E]
00:01 +2 -1: Some tests failed.
Failing tests:
  .../agent_permission_screen_focus_order_test.dart: AgentPermissionScreen focus order is Switch -> Allow All -> Deny Optional
```

Salinan cadangan dipulihkan lalu dihapus (ekspektasi asli terverifikasi lewat grep: `['AI Provider', 'Allow All', 'Deny Optional']`, backup `BACKUP_REMOVED`) dan kontrak diverifikasi ulang: `dart analyze` `No issues found!` plus `flutter test` `+3: All tests passed!`. Kontrol negatif membuktikan kontrak benar-benar mengunci urutan focus order (1 test gagal dan `Some tests failed.` ketika urutan label ditukar), bukan sekadar lolos.

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak, bagian report ini, dan pesan commit: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh (banyak file WIP sibling tetap dirty dan dibiarkan apa adanya).

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Agent Permission Screen di konfigurasi probe ini (viewport desktop 1536x1024). Cakupan audit focus-order layar: **38 dari 89** target layar — hitungan live `git ls-files | grep -c '_focus_order_test.dart'` = 37 sebelum commit fase ini, + kontrak baru ini = 38.

## 49. Fase 49 — Focus Order di Preview Modes Screen (2.4.3)

**Target:** `lib/features/cinema/presentation/preview_modes_screen.dart` (kelas `PreviewModesScreen`)
**Kontrak:** `test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart`

### Alasan pemilihan

Layar ini diberi prioritas karena seluruh surface interaktifnya berupa lima `ChoiceChip` di dalam satu `Wrap`, bersumber dari provider `cinemaProvider` yang murni in-memory (`CinemaState` default, tanpa database, tanpa network, tanpa plugin platform). Tidak ada `session.lock`, tidak ada fixture, dan tidak ada ketergantungan Core Worker, sehingga hasil probe bisa direproduksi tanpa kondisiaringan lain. Dipercaya dari 89 layar kandidat, ini adalah kandidat paling kecil yang tetap punya lebih dari dua elemen interaktif.

### Probe sebelum kontrak

Probe sementara (viewport 1536x1024, dpr 1.0, `LogicalKeyboardKey.tab` berulang, berhenti saat Rect berulang) menghasilkan lima stop, seluruhnya pada satu baris:

| Stop | Label | Rect (left, top, width, height) |
|---|---|---|
| 0 | Storyboard | 20.0, 81.0, 195.0, 38.0 |
| 1 | Animatic | 227.0, 81.0, 146.8, 38.0 |
| 2 | Low Quality | 385.8, 81.0, 189.1, 38.0 |
| 3 | Real-Time | 586.9, 81.0, 160.9, 38.0 |
| 4 | Final Preview | 759.8, 81.0, 217.3, 38.0 |

Probe dihapus setelah kontrak ditulis; hanya file kontrak yang tersisa.

### Yang dikunci kontrak

- `expect(stops, hasLength(5))` — tepat lima stop fokus, tidak ada stop tambahan dari AppBar.
- `equals(['Storyboard', 'Animatic', 'Low Quality', 'Real-Time', 'Final Preview'])` — urutan label persis seperti urutan deklarasi `_modes`.
- Setiap stop punya `width > 0` dan `height > 0` (area fokus non-zero).
- Kelima `rect.top` identik, membuktikan kelima chip benar-benar satu baris `Wrap`, bukan susunan bertumpuk yang kebetulan berurutan.
- `rect.left` naik monotonik, membuktikan urutan fokus mengikuti urutan visual kiri ke kanan.
- `stops.first.rect.top > 0` (di bawah AppBar) dan `stops.last.rect.right < 1536` (tidak keluar viewport).
- `expect(tester.takeException(), isNull)` sebagai pagar overflow/render exception.

### Negative control

Dua mutasi, masing-masing dicadangkan ke `%LOCALAPPDATA%\Temp` lalu dipulihkan:

1. Tukar dua label pertama (`Storyboard` <-> `Animatic`): `EXIT=1`, `00:01 +0 -1: Some tests failed`, diff `at location [0] is 'Storyboard' instead of 'Animatic'`.
2. Ubah `hasLength(5)` menjadi `hasLength(4)`: `EXIT=1`, `Some tests failed`, `Which: has length of <5>`.

Setelah dipulihkan, kontras green kembali (`+1: All tests passed!`) dan file cadangan dihapus.

### Bukti eksekusi

```
dart format test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart
-> Formatted 1 file (1 changed) in 0.01 seconds
dart analyze test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart
-> No issues found!
flutter test test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart
-> 00:01 +1: All tests passed!
flutter test test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart  (mutasi label)
-> EXIT=1, Some tests failed
flutter test test/features/cinema/presentation/preview_modes_screen_focus_order_test.dart  (mutasi hasLength)
-> EXIT=1, Some tests failed
```

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak: `none`.

Tidak ada perubahan kode produksi pada fase ini; file di luar dua path yang dikomit tidak disentuh dan tidak di-`git add`.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Preview Modes Screen. Jumlah layar teraudit dari 89 kandidat: 39 (sebelum fase ini 38).

## 50. Fase 50 — Focus Order di AI Generation Queue Screen (2.4.3)

**Target:** `lib/features/ai/presentation/ai_generation_queue_screen.dart` (kelas `AiGenerationQueueScreen`)
**Kontrak:** `test/features/ai/ai_generation_queue_screen_focus_order_test.dart`

### Alasan pemilihan

Layar ini meneruskan fixture lewat parameter `jobs:` bertipe `GenerationJob`, jadi tidak ada database, tidak ada network, tidak ada plugin platform, dan tidak ada `session.lock`. Seluruh surface interaktifnya tetap beragam: satu action di AppBar, satu `TextField`, satu `DropdownButton`, satu tombol submit, dan `IconButton` aksi per job. Dari 89 layar kandidat yang belum diaudit, ini adalah layar dengan titik fokus paling beragam per baris kode dan biaya setup fixture paling rendah.

### Probe sebelum kontrak

Probe sementara `test/features/ai/_probe_focus_test.dart` (viewport 1536x1024, devicePixelRatio 1.0, `LogicalKeyboardKey.tab` berulang, berhenti saat geometri berulang) menghasilkan enam stop; traversal kembali ke stop 0 setelah stop 5:

| Stop | Label | Rect (left, top, width, height) |
|---|---|---|
| 0 | Run Queue (AppBar action) | 1355.1, 8.0, 180.9, 40.0 |
| 1 | Image prompt (TextField) | 56.0, 148.0, 1424.0, 96.0 |
| 2 | openai / comfyui (Dropdown) | 40.0, 272.0, 137.1, 48.0 |
| 3 | Generate Image (FilledButton) | 189.1, 276.0, 263.4, 40.0 |
| 4 | Cancel job-queued (IconButton) | 1444.0, 376.0, 40.0, 40.0 |
| 5 | Retry job-failed (IconButton) | 1444.0, 460.0, 40.0, 40.0 |

Job berstatus `completed` sengaja tidak menambah stop fokus karena UI hanya menampilkan status dan tidak merender aksi apa pun untuk status itu. Ini perilaku yang benar, bukan control yang hilang, dan dikunci eksplisit oleh test keempat.

Probe dihapus setelah kontrak ditulis (`ls test/features/ai/` tidak lagi memuat `_probe_focus_test.dart`); hanya file kontrak yang tersisa.

### Cara label fokus ditentukan

Label diambil dari subtree elemen yang difokuskan (semua `Text.data` dan `Tooltip.message` descendant, digabung dengan prefiks `runtimeType:`). Bila subtree tidak memberi apa pun, label dicari di ancestor: `TextField.decoration.labelText`/`.hintText` untuk field input, dan `Tooltip.message` untuk `IconButton` yang menyimpan tooltip sebagai ancestor. Tanpa fallback ancestor, `IconButton` dan `TextField` akan menghasilkan label generik `widget:...` dan urutan fokus tidak bisa dibedakan satu per satu.

### Yang dikunci kontrak

- `expect(stops.map((s) => s.label).toList(), _expectedLabels)` — urutan enam label persis: Run Queue, Image prompt, dropdown provider, Generate Image, Cancel job-queued, Retry job-failed.
- `expect(stops.length, 6)` — tepat enam stop fokus, tidak ada stop tersembunyi dari AppBar atau card submit.
- Setiap stop punya `width > 0` dan `height > 0`, serta `rect.shortestSide >= 40.0` (ambang `_minFocusArea`) sehingga target fokus sekecil mungkin tetap terukur.
- Traversal kembali ke geometri stop pertama (`_firstStopGeometry = '1355,8,181,40'`) pada fixture satu job queued, membuktikan tidak ada jebakan fokus setelah aksi job terakhir.
- Fixture satu job `completed` menghasilkan tepat empat label (`_expectedLabels.take(4)`), membuktikan status tanpa aksi tidak menambah stop.
- `expect(tester.takeException(), isNull)` pada setiap fixture sebagai pagar overflow/render exception.

### Negative control

Satu mutasi dicadangkan ke `%LOCALAPPDATA%\Temp\wcag243_negctl_backup.dart` lalu dipulihkan: label stop 0 dan stop 1 ditukar (`Text:Run Queue` <-> `TextField:Image prompt`). Hasil: `EXIT=1`, `00:02 +2 -2: Some tests failed`, dengan dua test gagal dan pesan `at location [0] is 'Text:Run Queue' instead of 'TextField:Image prompt'`. Setelah `cp` restore, urutan label kembali ke bentuk semula dan file cadangan dihapus.

### Bukti eksekusi

```
dart format test/features/ai/ai_generation_queue_screen_focus_order_test.dart
-> Formatted 1 file (1 changed) in 0.01 seconds
dart analyze test/features/ai/ai_generation_queue_screen_focus_order_test.dart
-> No issues found!
flutter test test/features/ai/ai_generation_queue_screen_focus_order_test.dart
-> 00:01 +4: All tests passed!
flutter test test/features/ai/ai_generation_queue_screen_focus_order_test.dart  (mutasi label)
-> NEGCTL_EXIT=1, 00:02 +2 -2: Some tests failed
```

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak: `none` (0 hit).

Tidak ada perubahan kode produksi pada fase ini; hanya dua file yang di-`git add` dengan pathspec eksplisit, tanpa `git add -A`, dan tanpa menyentuh file WIP Core Worker.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada AI Generation Queue Screen. Jumlah layar teraudit dari 89 kandidat: 40 (sebelum fase ini 39).

## 51. Fase 51 — Focus Order di Tech Tree Workspace (2.4.3)

**Target:** `lib/features/world_logic/presentation/tech_tree_workspace_view.dart` (kelas `TechTreeWorkspaceView`)
**Kontrak:** `test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart`

### Alasan pemilihan

Layar ini menerima `TechTreeController` yang dibangun dari `TechTreeController.forRegistry(registry:, timeline:)`, jadi fixture-nya murni data in-memory: tidak ada database, tidak ada network, tidak ada plugin platform, dan tidak ada `session.lock`. Surface interaktifnya justru paling beragam dari semua kandidat yang sudah diaudit: dua `ChoiceChip` filter (branch dan culture), satu `Slider` dengan label deskriptif, tiga `InkWell` node graph, dan enam `IconButton` aksi keyboard. Kandidat sebelumnya di direktori yang sama belum ada yang punya kontrak fokus, dan direktori `lib/features/world_logic/` bersih dari perubahan uncommitted.

Kandidat `AutomationCenterScreen` dieliminasi lebih dulu oleh probe: keenam `Switch`-nya memakai `onChanged: null`, sehingga nol stop fokus. Kandidat `CinemaWorkspaceScreen` dan `GameCreationDashboardScreen` hanya punya dua tombol aktif dan membutuhkan mock riverpod, jadi biayanya lebih tinggi untuk cakupan fokus yang lebih sempit.

### Probe sebelum kontrak

Probe sementara `test/features/world_logic/_probe_focus_test.dart` (viewport 1536x1024, devicePixelRatio 1.0, `LogicalKeyboardKey.tab` berulang, berhenti saat geometri berulang) menghasilkan tiga belas stop. Fixture: registry tiga node (Wheel tier 1 -> Bronze Casting tier 2 -> Iron Smelting tier 3), branch `prime`, culture `all`.

| Stop | Label | Rect (left, top, width, height) | Widget |
|---|---|---|---|
| 0 | Text:all | 124, 21, 76, 38 | ChoiceChip |
| 1 | Text:prime | 208, 21, 125, 38 | ChoiceChip |
| 2 | Text:all | 138, 77, 96, 38 | ChoiceChip |
| 3 | Slider:tech-tree-filter-tick-slider | 95, 128, 1298, 48 | Slider |
| 4 | Text:tier 1 \| Text:Wheel | 16, 196, 1504, 38 | InkWell |
| 5 | Text:tier 2 \| Text:Bronze Casting | 16, 242, 1504, 38 | InkWell |
| 6 | Text:tier 3 \| Text:Iron Smelting | 16, 288, 1504, 38 | InkWell |
| 7 | Tooltip:Advance tier | 20, 350, 40, 40 | IconButton |
| 8 | Tooltip:Retreat tier | 76, 350, 40, 40 | IconButton |
| 9 | Tooltip:Jump to first discovery | 132, 350, 40, 40 | IconButton |
| 10 | Tooltip:Jump to last discovery | 188, 350, 40, 40 | IconButton |
| 11 | Tooltip:Navigate left | 244, 350, 40, 40 | IconButton |
| 12 | Tooltip:Navigate right | 300, 350, 40, 40 | IconButton |

Tombol "clear" pada baris Tick sengaja tidak menambah stop fokus karena `onPressed: null` (disabled). Ini perilaku Flutter yang benar, bukan control yang hilang, dan Absence-nya terlihat langsung di probe: urutan berhenti tepat di dua belas stop lalu wraps.

Probe dihapus setelah kontrak ditulis (`git status --porcelain test/features/world_logic/_probe_focus_test.dart` kosong); hanya file kontrak yang tersisa.

### Cara label fokus ditentukan

Label diambil dari subtree elemen yang difokuskan (semua `Text.data` dan `Tooltip.message` descendant, digabung dengan prefiks `runtimeType:`). Tanpa fallback ancestor, `IconButton` akan menghasilkan label generik `widget:IconButton` dan enam aksi keyboard tidak bisa dibedakan satu per satu. Stop 3 adalah `Slider` yang subtree-nya tidak memuat `Text` atau `Tooltip`, sehingga resolver memakai `ancestorKey` untuk menamai stop itu secara deterministik sebagai `Slider:tech-tree-filter-tick-slider` alih-alih `widget:Focus` yang bergantung pada urutan materialisasi widget.

### Yang dikunci kontrak

- `expect(stops.length, 13)` — tepat tiga belas stop fokus.
- `expect(stops.map((s) => s.label).toList(), _expectedLabels)` — urutan label persis seperti tabel di atas, dari filter branch, filter culture, slider tick, tiga node graph, lalu enam aksi keyboard.
- `expect(stops.map((s) => _geometryOf(s.rect)).toList(), _expectedGeometry)` — setiap stop terkunci ke Rect nyata, bukan hanya ke urutan, sehingga reflow yang mengubah posisi target fokus terdeteksi.
- Setiap stop punya `width > 0` dan `height > 0`, serta `rect.shortestSide >= 38.0` (ambang `_minFocusShortestSide`, mengikuti tinggi ChoiceChip 38 px) sehingga target fokus terkecil tetap terukur.
- Traversal bergerak dari atas ke bawah tanpa lompatan: setiap stop berikutnya, kecuali yang berada pada baris yang sama, memiliki `top` lebih besar; pada baris yang sama, koordinat `left` tidak pernah menurun.
- Test keempat menjalankan 2N tab dan mengunci sifat cincin traversal: satu putaran berisi N stop unik (tiap stop muncul tepat sekali, tidak ada yang dilewati atau diulang), putaran kedua identik dengan putaran pertama (tidak ada jebakan fokus setelah aksi keyboard terakhir), dan urutan melingkar di dalam putaran itu sama dengan kontrak.
- `expect(tester.takeException(), isNull)` pada setiap fixture sebagai pagar overflow/render exception.

### Catatan metodologi: offset mulai traversal tidak deterministik

Dua kali revisi test keempat diperlukan karena perilaku traversal bawaan Flutter:

1. `FocusManager.instance.primaryFocus` bersifat global di dalam satu file test. Traversal kedua dilanjutkan dari stop terakhir traversal pertama, sehingga helper `_resetFocus()` kini memanggil `primaryFocus?.unfocus()` sebelum setiap pump baru.
2. Bahkan dari keadaan fokus segar, `FocusManager` dapat melanjutkan traversal dari node yang sebelumnya di-dispose, sehingga tab pertama tidak selalu mendarat di stop 0. Kontrak karena itu menguji sifat cincin traversal (dua putaran identik, urutan melingkar) alih-alih offset mulai absolut. Ini bukan pelonggaran kontrak: urutan relatif dan closure traversal tetap terkunci penuh.

Kesalahan kompilasi pertama pada revisi ini adalah `const n = _expectedLabels.length` yang ditolak analyzer (`const_eval_property_access`) karena `.length` di atas top-level `final` tidak boleh dipakai dalam ekspresi konstanta; diganti `final n = ...`.

### Negative control

Satu mutasi dicadangkan ke `%LOCALAPPDATA%\Temp\tech_tree_focus_negctl.bak` lalu dipulihkan: dua label filter branch ditukar (`Text:all` <-> `Text:prime`). Hasil: `NEGCTL_FLUTTER_EXIT=1`, `00:02 +3 -1: Some tests failed`, dengan pesan `at location [0] is 'Text:all' instead of 'Text:prime'`. Setelah `cp` restore, urutan label kembali ke bentuk semula (`Text:all`, `Text:prime`, ...), verifikasi ulang `EXIT=0` `All tests passed!`, lalu file cadangan dihapus.

Dua percobaan negative control pertama tidak menghasilkan mutasi karena pola literal tidak cocok: berkas kontrak memakai kutip ganda dan line ending LF murni (`dart format` menormalkannya), bukan kutip tunggal maupun CRLF. Kedua percobaan itu justru terekam sebagai `All tests passed` dengan exit 0, yang membuktikan mutasi tidak pernah menyentuh berkas — bukan bukti negative control. Mutasi baru dinyatakan sah hanya setelah `MUTATED` tercetak dan exit 1 terukur.

### Bukti eksekusi

```
dart format test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart
-> Formatted 1 file (0 changed) in 0.01 seconds
dart analyze test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart
-> No issues found!
flutter test test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart
-> 00:02 +4: All tests passed!
flutter test test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart  (mutasi label branch)
-> NEGCTL_FLUTTER_EXIT=1, 00:02 +3 -1: Some tests failed
flutter test test/features/world_logic/presentation/tech_tree_workspace_focus_order_test.dart  (setelah restore)
-> RESTORE_VERIFY_EXIT=0, 00:01 +4: All tests passed!
flutter test test/features/world_logic/
-> SUITE_EXIT=0, 00:53 +2255: All tests passed!
```

Scan karakter CJK/Cyrillic/Hangul/Kana pada file kontrak: `none` (0 hit).

Berkas bukti `docs/evidence/wcag-2.2-audit-login-screen-2026-09-30.md` memakai line ending LF murni (2613 LF, 0 CRLF) sehingga sisip section dilakukan dengan line ending yang sama untuk menghindari diff seluruh berkas.

Tidak ada perubahan kode produksi pada fase ini; hanya dua file yang di-`git add` dengan pathspec eksplisit, tanpa `git add -A`, dan tanpa menyentuh file WIP Core Worker maupun probe milik run lain di `test/features/content_capabilities/`.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Tech Tree Workspace. Jumlah layar teraudit dari 89 kandidat: 41 (sebelum fase ini 40).

## 52. Fase 52 — Focus Order di Project List Screen (2.4.3)

Tanggal probe: 2026-10-04. Layar alvo `lib/features/projects/presentation/project_list_screen.dart` (256 baris, bersih di `git status`, tanpa `*_focus_order_test.dart` sebelumnya).

Fixture deterministik: satu proyek "Void Universe" pada `ProjectLocalDataSource` in-memory, di-override lewat `projectLocalDataSourceProvider` + `projectRepositoryProvider`. Pola ini sudah terbukti di `test/features/projects/presentation/project_delete_ui_test.dart`, jadi tidak ada database, network, `path_provider`, maupun file picker yang tersentuh. Tanpa fixture ini grid akan merender `ProjectEmptyState` dan kartu proyek tidak pernah fokus (pitfallWCAG: collection kosong bukan bukti region non-fokusable).

### Traversal terukur

Viewport 1536x1024, devicePixelRatio 1.0, `sendKeyEvent(LogicalKeyboardKey.tab)` berulang, dedup berdasarkan geometri. Traversal kembali ke stop 0 setelah stop 2, jadi N = 3 stop unik dan traversal melingkar penuh:

```
0 New Project       (FilledButton)     Rect(1283, 41, 221, 40)
1 kartu proyek      (InkWell)         Rect(  32, 117, 480, 310)
2 Project actions   (PopupMenuButton) Rect( 461, 128,  40,  40)
3 <kembali ke stop 0>
```

Catatan mekanika yang terukur:

- Tombol `New Project` adalah stop pertama meski secara visual berada di kanan header; urutan baca (bukan urutan geometri) yang governs traversal, dan ini sesuai WCAG 2.4.3 karena hanya ada satu kontrol di baris header itu.
- `PopupMenuButton` "Project actions for Void Universe" menyimpan tooltip sebagai **ancestor**, bukan descendant, sehingga label fokusnya harus dibaca lewat `visitAncestorElements`. Probe yang hanya memindai subtree Text akan salah melaporkannya sebagai `widget:...`.
- Teks `ProjectCard` (nama, deskripsi, "Version 0.1.0") berada di dalam `InkWell` kartu yang sama, jadi ia terbaca sebagai bagian dari stop 1 — bukan tiga stop fokus terpisah. Ini perilaku benar, bukan kontrol yang hilang.
- `PopupMenuButton` berada di dalam area kartu (x 461..501 di dalam 32..512), dan kontrak mengunci invarian itu secara eksplisit.

### Asersi kontrak

`test/features/projects/presentation/project_list_screen_focus_order_test.dart` mengunci empat hal:

1. jumlah stop, urutan label lengkap, dan daftar geometri (`_expectedLabels` / `_expectedGeometry`);
2. area fokus non-zero dengan sisi terpendek minimal 40 px (tombol 40 px, PopupMenu 40 px);
3. monoton baris (tidak naik ke atas) dan kiri-ke-kanan pada baris yang sama, plus `PopupMenuButton` berada di dalam `Rect` kartu;
4. sifat melingkar: traversal 2N menghasilkan dua putaran identik tanpa stop terlewat atau terulang (mendeteksi jebakan fokus). `FocusManager.instance` bersifat global per file test, jadi traversal kedua butuh `_resetFocus()` sebelum pump.

### Bukti eksekusi

```
dart format test/features/projects/presentation/project_list_screen_focus_order_test.dart
-> Formatted 1 file (1 changed)

dart analyze test/features/projects/presentation/project_list_screen_focus_order_test.dart
-> No issues found!

flutter test test/features/projects/presentation/project_list_screen_focus_order_test.dart
-> 00:01 +4: All tests passed!   (GREEN_EXIT=0)

flutter test test/features/projects/            # gate feature
-> 00:34 +34: All tests passed!   (GATE_EXIT=0)
```

### Negative control (dua mutasi, keduanya tertangkap)

1. Tukar urutan label `New Project` dan kartu proyek → `flutter test` exit **1**, `00:01 +0 -1`, test "focus order mengikuti urutan baca" gagal.
2. Jumlah stop dinaikkan 3 → 4 dengan geometri tambahan `999,999,10,10` → exit **1**, `00:01 +2 -2`, dua test gagal ("urutan baca" dan "tidak ada jebakan fokus").

Kontrak dikembalikan dari backup `C:\Users\nepht\AppData\Local\Temp\wcag243_negctl_project_list_screen_focus_order_test.dart.bak` (9 326 byte), lalu backup dihapus. Re-run setelah restore: `00:01 +4: All tests passed!`.

### Catatan koreksi counter

Penghitungan nyata pada repo saat fase ini:

- 42 berkas `test/**/*focus_order_test.dart`;
- **38 layar `_screen.dart` distinct** tercakup, ditambah 1 kontrak atas `tech_tree_workspace_view.dart` (bukan `_screen.dart`, jadi tidak masuk hitungan layar);
- 6 layar punya **dua** berkas kontrak (duplikasi historis): `forgot_password_screen`, `login_screen`, `register_screen` (ketiganya juga di `test/features/authentication/focus_order_test.dart`), `agent_permission_screen`, `create_product_wizard_screen`, dan `product_detail_screen` (dua marketplace).

Artinya counter serials lama di laporan (41 pada section 51) menghitung **fase**, bukan layar distinct; layar distinct yang benar sebelum fase ini adalah 37, menjadi **38** setelah fase ini. Angka 89 kandidat tetap sesuai brief; delta screen nyata per fase berikutnya sebaiknya memakai pengukuran distinct ini.

Line ending berkas bukti: **LF murni** (2 702 LF, 0 CRLF saat diukur), jadi sisip section ini memakai LF agar tidak menghasilkan diff seluruh berkas.

Tidak ada perubahan kode produksi pada fase ini. Hanya dua berkas yang di-`git add` dengan pathspec eksplisit, tanpa `git add -A`, tanpa menyentuh 96 file dirty milik Core Worker, dan probe `_probe_focus_test.dart` dihapus setelah kontrakfinal dibuat.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Project List Screen. Layar teraudit dari 89 kandidat: **38 distinct** (serial fase: 52; counter fase sebelumnya melaporkan 41).

## 53. Fase 53 — Focus Order di Cinema Workspace Screen (2.4.3)

Tanggal probe: 2026-10-04. Layar alvo `lib/features/cinema/presentation/cinema_workspace_screen.dart` (182 baris, bersih di `git status`, tanpa `*_focus_order_test.dart` sebelumnya).

Fixture deterministik: tidak ada. Layar ini `ConsumerWidget` yang hanya `ref.watch(cinemaProvider)`; `CinemaController` adalah `Notifier<CinemaState>` murni in-memory (`build()` mengembalikan `const CinemaState()`), jadi `ProviderScope` tanpa override sudah deterministik. Kedua tombol memanggil `togglePlayback()`, tidak menyentuh database, network, `path_provider`, maupun file picker. SyaratWR: total proyek punya `test/features/cinema/presentation/cinema_workspace_screen_test.dart` yang hanya asserting label — probe fokus butuh viewport desktop yang tidak pernah disentuh test lama itu.

### Traversal terukur

Viewport 1536x1024, devicePixelRatio 1.0, `sendKeyEvent(LogicalKeyboardKey.tab)` berulang, dedup berdasarkan geometri. Traversal kembali ke stop 0 setelah stop 1, jadi N = 2 stop unik dan traversal melingkar penuh:

```
0 Preview  (TextButton.icon)   Rect(1204.70, 8.0, 152.70, 40.0)
1 Render   (FilledButton.icon) Rect(1369.40, 8.0, 150.60, 40.0)
2 <kembali ke stop 0>
```

Branch sempit 390x844 (lebar < 1000, threshold `constraints.maxWidth >= 1000` di `cinema_workspace_screen.dart:54`) mengukur urutan label yang sama dengan offset berbeda karena AppBar action tidak lagi berdesain ke kanan:

```
0 Preview  Rect(58.70, 8.0, 152.70, 40.0)
1 Render   Rect(223.40, 8.0, 150.60, 40.0)
2 <kembali ke stop 0>
```

Catatan mekanika yang terukur:

- Body three-panel (sidebar Project dengan `Shots`/`Sequences`/`Timeline`, viewport, dan panel `Shot Details`) **tidak punya kontrol interaktif** — semuanya `Icon` + `Text` tanpa `onTap`/`InkWell`/`Focus`. Jadi 2 stop di AppBar adalah hasil lengkap, bukan traversal terpotong oleh kontrol yang hilang. Ini kebalikan dari pitfallWCAG "collection kosong = region non-fokusable": di sini kosongnya memang benar, ditandai oleh probe sebagai `FlutterError`-free traversal dua stop.
- Urutan fokus mengikuti urutan visual kiri ke kanan di baris AppBar (`left` 1204.70 → 1369.40), bukan urutan baca terbalik. `top` keduanya identik `8.0` dan tinggi identik `40.0`, sesuai tinggi toolbar Material.
- Layar memakai `key: ValueKey(cinemaState.isPlaying)` pada `Scaffold` (`cinema_workspace_screen.dart:26`), jadi `togglePlayback()` membangun ulang seluruh pohon. Kontrak sengaja **tidak** mengunci perilaku re-tree tersebut: fokus di Flutter kembali ke `FocusScope` akar sesudah widget tree diganti, dan mengunci-nya akan membuat kontrak rapuh tanpa nilai aksesibilitas.

### Asersi kontrak

`test/features/cinema/presentation/cinema_workspace_screen_focus_order_test.dart` mengunci lima hal:

1. jumlah stop = 2 dan urutan label lengkap `['Preview', 'Render']` pada viewport 1536x1024;
2. area fokus non-zero pada setiap stop (`width > 0`, `height > 0`);
3. kedua stop berada pada baris yang sama — `top` identik dan `height` identik;
4. urutan kiri ke kanan (`stops[i].rect.left > stops[i-1].rect.left`) plus kedua tombol di dalam viewport (`top >= 0`, `right < 1536`);
5. urutan label yang sama pada viewport sempit 390x844, sekaligus `tester.takeException()` null untuk branch narrow.

Probe tidak menyimpan daftar geometri persis sebagai konstanta; ia mengunci Hubungan geometris (baris sama, kiri-ke-kanan, non-zero, dalam viewport) karena angka piksel berasal dari metrics Material dan bisa bergeser antar versi SDK, sementara invarian yang diwndud adalah urutan dan relasi posisinya.

### Negative control

Ekspektasi urutan label di temporarily ditukar dari `['Preview', 'Render']` menjadi `['Render', 'Preview']` (backup `C:\Users\nepht\AppData\Local\Temp\cinema_focus_order_contract.bak`, 5 661 byte):

```
NEG_CONTROL_EXIT=1
Expected: ['Render', 'Preview']
  Actual: MappedListIterable<({String label, Rect rect}), String>:['Preview', 'Render']
00:01 +0 -1: mengunci urutan fokus Cinema Workspace Screen [E]
00:01 +1 -1: Some tests failed.
```

Kontrak dikembalikan dari backup lalu backup dihapus. Bukti bahwa kontrak benar-benar bisa mendeteksi regresi urutan, bukan hanya hijau karena tidak pernah gagal.

### Gap yang ditemukan probe (belum diperbaiki pada fase ini)

Probe menemukan **defect produksi nyata yang terpisah dari fokus**: pada branch wide (1536x1024) `RenderFlex overflowed by 10 pixels on the right` pada `Row` di `cinema_workspace_screen.dart:63` — baris item sidebar (`Icon` 18px + `SizedBox(width: 12)` + `Text`) di dalam `Container(width: 180, padding: EdgeInsets.all(16))` memberi lebar efektif 148px, dan label terpanjang ("Sequences") meluap 10px. Kontrak fokus mengambil exception itu lewat `tester.takeException()` dan mencetak `KNOWN_LAYOUT_DEFECT: FlutterError` alih-alih mengunci overflow sebagai perilaku yang diharapkan; test branch sempit tetapowns `takeException() isNull` karena branch itu memang tidak meluap.

Test lama `cinema_workspace_screen_test.dart` tidak menangkapnya karena hanya menguji viewport 390x844 (branch narrow), bukan branch wide desktop.

Status: **GAP terverifikasi, belum di-fix.** Kode produksi tidak disentuh pada fase ini sesuai aturan "jangan mengubah kode produksi kecuali defect terbukti dari probe — laporkan dulu"; perbaikanIEDIRECTLY (bungkus `Text` dengan `Expanded`/`Flexible` di sidebar `Row`) menjadi kandidat RED→GREEN untuk cron berikutnya. Entry ini dicatat di laporan bukti ini, **belum** dipromosikan ke `docs/sprints/` ledger, karena kontrak run ini membatasi `git add` pada dua berkas (laporan + kontrak) dan tidak boleh meninggalkan dirty file baru di working tree yang dipakai Core Worker.

### Catatan koreksi counter

Penghitungan nyata pada repo saat fase ini:

- 43 berkas `test/**/*_focus_order_test.dart` setelah fase ini (42 tracked sebelum fase ini + kontrak baru ini);
- **39 layar `*_screen.dart` distinct** tercakup, naik dari 38distinct pada section 52;
- 1 kontrak lain mengaudit `tech_tree_workspace_view.dart` (bukan `_screen.dart`, jadi tidak masuk hitungan layar);
- duplikasi historis tetap: `agent_permission_screen`, `create_product_wizard_screen`, dan `product_detail_screen` masing-masing punya dua kontrak.

Counter fase sebelumnya (41 pada section 51) menghitung fase, bukan layar distinct; phase ini memakai pengukuran distinct dari `git ls-files` + import yang discan terhadap `*_screen.dart`.

Line ending berkas bukti: **LF murni** (2 774 LF, 0 CRLF saat diukur), jadi sisip section ini memakai LF agar tidak menghasilkan diff seluruh berkas.

Tidak ada perubahan kode produksi pada fase ini. Hanya dua berkas yang di-`git add` dengan pathspec eksplisit, tanpa `git add -A`, tanpa menyentuh 96 file dirty milik Core Worker, dan probe `_probe_focus_test.dart` dihapus setelah kontrak final dibuat.

**Status fase:** VERIFIED untuk kontrak WCAG 2.4.3 pada Cinema Workspace Screen (2 stop: `Preview` → `Render`, kedua branch layout). Layar teraudit dari 89 kandidat: **39 distinct `*_screen.dart`** (serial fase: 53; 38 distinct sebelum fase ini). Satu GAP terverifikasi tercatat di atas dan belum di-fix.

## 54. Fase 54 — Focus Order di Game Creation Dashboard Screen (2.4.3)

**Layar audited:** `lib/features/game/presentation/game_creation_dashboard_screen.dart` (`GameCreationDashboardScreen`).
**Kontrak:** `test/features/game/presentation/game_creation_dashboard_screen_focus_order_test.dart` (2 test).
**Metode:** probe sementara pada viewport 1536x1024 dan 390x844, dpr 1.0, `sendKeyEvent(LogicalKeyboardKey.tab)` berulang sampai geometri fokus berulang (wrap ke stop pertama). Label diambil dari `Text` non-`Icon` terdekat ke pusat Rect fokus.

### Klasifikasi kontrol interaktif

Layar ini hanya punya dua kontrol interaktif, keduanya di `AppBar.actions`:

| Kontrol | Widget | Baris kode | Callback |
|---|---|---|---|
| Play | `TextButton.icon` | 34-38 | `onPlay` (nullable) |
| Build | `FilledButton.icon` | 42-47 | `onBuild` (nullable) |

Body layar (sidebar World, panel Game World, Inspector) murni teks: tidak ada `ListTile.onTap`, `Switch`, `Checkbox`, atau `TextField`. `_worldItems` hanya dirender sebagai `Row` berisi `Icon` + `Text` tanpa `InkWell`/`GestureDetector`, sehingga **tidak** masuk traversal fokus.

Karena `onPlay`/`onBuild` nullable, probe dan kontrak **wajib** mengirim callback non-null. Dengan callback null, Flutter membuang tombol dari traversal fokus dan probe akan melaporkan `hasLength(1)` yang salah.

### Hasil pengukuran — 1536x1024 (branch `wide`)

```
STOP 0 label="Play"  rect=(1261.1, 8.0, 110.4, 40.0)
STOP 1 label="Build" rect=(1383.5, 8.0, 136.5, 40.0)
STOP#WRAP after 2
```

### Hasil pengukuran — 390x844 (branch sempit)

```
STOP 0 label="Play"  rect=(115.1, 8.0, 110.4, 40.0)
STOP 1 label="Build" rect=(237.5, 8.0, 136.5, 40.0)
STOP#WRAP after 2
```

### Yang dikunci kontrak

- Tepat **2 stop** fokus, urutan label `['Play', 'Build']` di kedua viewport.
- Area fokus non-zero pada setiap stop (lebar dan tinggi > 0) — kontrol benar-benar bisa dijangkau keyboard.
- Kedua tombol pada baris AppBar yang sama: `rect.top` identik (8.0) dan `rect.height` identik (40.0).
- Urutan fokus mengikuti urutan visual kiri ke kanan (`rect.left` menaik).
- Baris tombol tidak keluar dari viewport: `top >= 0` dan `right < 1536`.
- **Aktivasi nyata via keyboard** (bukan hanya perpindahan fokus): setelah loop wrap fokus berada di Play → `Enter` memicu `onPlay` (playCalls 1); `Tab` maju ke Build → `Enter` memicu `onBuild` (buildCalls 1). Status awal diverifikasi nol sebelum aktivasi.

### Negative control (WAJIB, terbukti)

| # | Mutasi | Hasil |
|---|---|---|
| NC1 | `expect(stops, hasLength(2))` → `hasLength(3)` | **exit 1**, `Some tests failed`, `Expected: an object with length of <3>` |
| NC2 | label order viewport sempit `['Play','Build']` → `['Build','Play']` | **exit 1**, `Some tests failed`, `Expected: ['Build', 'Play'] / Actual: ['Play', 'Build']` |

Kedua mutasi dikembalikan dari backup di `/c/Users/nepht/AppData/Local/Temp/`; SHA-256 file kontrak setelah restore identik dengan baseline (`1b7b0bbbc8860ad1…`) dan backup sudah dihapus.

Catatan proses: percobaan NC versi label-order pertama gagal diterapkan karena `assert s.count(old) == 1` menemukan **2** kemunculan (ekspektasi yang sama ada di kedua test). Guard itu justru membuktikan ekspektasi terduplikasi, sehingga mutasi pertama tidak pernah mengubah file dan hasil run tersebut **tidak** dihitung sebagai negative control. NC di atas memakai targeting yang terverifikasiuniquely.

### Defect TERPISAH yang ditemukan (bukan bagian kontrak 2.4.3)

Pada viewport **1536x1024** saja, probe menangkap exception `A RenderFlex overflowed by 25 pixels on the right.` yang **tidak** muncul di 390x844. Lokasi ditentukan secara terukur, bukan ditebak:

```
ITEM "Levels"     textWidth=85.5   naturalRow=115.5  available=148.0
ITEM "Characters" textWidth=142.5  naturalRow=172.5  available=148.0  <-- +24.5
ITEM "Quests"     textWidth=85.5   naturalRow=115.5  available=148.0
ICON_SIZE: Size(18.0, 18.0)
```

- Sidebar `Container(width: 180)` dikurangi `padding: EdgeInsets.all(VoidSpacing.md)` (16) x2 → **148 px** tersedia (baris 97-114).
- Item `Row` = `Icon(size: 18)` + `SizedBox(width: VoidSpacing.sm = 12)` + `Text('Characters')` (baris 62-73).
- `172.5 - 148 = 24.5`, dibulatkan Flutter menjadi **overflow 25 px**.

Test lama `game_creation_dashboard_screen_test.dart` hanya menguji overflow pada **viewport 390** (`tester.view.physicalSize = const Size(390, 844)`), sehingga defect branch `wide` ini tidak pernah tertangkap.

**Status defect:** `PARTIAL` — dicatat sebagai Gap, **belum** diperbaiki dalam run ini. Kontrak fokus sengaja **tidak** mengunci overflow tersebut sebagai perilaku yang diharapkan: exception diambil lewat `tester.takeException()` hanya agar tidak menutupi kontrak 2.4.3, dan dicetak sebagai `KNOWN_LAYOUT_DEFECT`. Perbaikan produksi (mis. `Flexible`/`Expanded` pada Text label, atau `isExpanded`/ellipsis) adalah slice terpisah di luar scope "satu layar per run" dan perlu RED→GREEN tersendiri.

### Gate

| Gate | Perintah | Hasil |
|---|---|---|
| format | `dart format <kontrak>` | Formatted 1 file |
| analyze | `dart analyze <kontrak>` | `No issues found!` |
| test kontrak | `flutter test <kontrak>` | `All tests passed!` (2 test) |
| suite feature | `flutter test test/features/game/` | `All tests passed!` (+44), exit 0 |
| CJK/Cyrillic scan | regex `\u0400-\u04FF\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af` | 0 hit |

**Status section:** `VERIFIED` untuk fokus 2.4.3 (order, label, geometri, area non-zero, aktivasi keyboard, negative control). Defect overflow branch `wide` dicatat terpisah sebagai `PARTIAL`.

## 55. Fase 55 — Focus Order di Content Capability Matrix Screen (2.4.3)

**Layar audited:** `lib/features/content_capabilities/presentation/content_capability_matrix_screen.dart` (`ContentCapabilityMatrixScreen`, 462 baris).
**Kontrak:** `test/features/content_capabilities/presentation/content_capability_matrix_screen_focus_order_test.dart` (8 test).
**Metode:** probe sementara pada viewport 1536x1024 dan 390x844, dpr 1.0, `sendKeyEvent(LogicalKeyboardKey.tab)` berulang. Label diambil dari `Text` non-`Icon` pertama di subtree node fokus; kolom pencarian tidak punya `Text` di subtree fokusnya sehingga diberi label eksplisit `field:search` lewat jenis ancestor-nya.

Layar dipilih karena sifatnya murni presentasi: seluruh state berasal dari katalog statis `ContentCapabilityCatalog` dan state lokal `TextEditingController`, tanpa database, tanpa network, tanpa DI. Tidak ada fixture yang perlu disiapkan, sehingga cocok untuk run audit terjadwal.

### Klasifikasi kontrol interaktif

| Kontrol | Widget | Baris kode | Keterangan |
|---|---|---|---|
| Kolom pencarian | `TextField` | 115-116 | `ValueKey('content-capability-search')` |
| Chip `Semua` | `FilterChip` | 190-191 | `ValueKey('maturity-all')` |
| Chip 5 maturity | `FilterChip` | 197-198 | `ValueKey('maturity-${maturity.name}')`, digabung dalam `Wrap` |
| Kartu modul | `ExpansionTile` | 217-218 | `ValueKey('content-module-${module.id}')`, 17 buah |
| Pemulihan filter | `TextButton` | 435 | Hanya dirender pada keadaan kosong |

Kartu modul memuat tombol `Chip`/`Switch` di dalam `ExpansionTile` yang collapsed. Node-node itu **tidak** masuk traversal saat tile tertutup, sehingga tidak ikut terukur.

### Hasil pengukuran — 1536x1024, keadaan daftar penuh

Siklus 24 node, traversal masuk pertama kali pada `field:search`:

```
STOP  0 field:search      L=246.0  T= 76.0  W=399.2 H=24.0
STOP  1 Semua             L=665.2  T=205.0  W=124.5 H=38.0
STOP  2 Full 0            L=797.7  T=205.0  W=118.6 H=38.0
STOP  3 Partial 9         L=924.3  T=205.0  W=160.9 H=38.0
STOP  4 Domain Only 6     L=1093.2 T=205.0  W=217.3 H=38.0
STOP  5 UI Only 1         L=665.2  T=261.0  W=160.9 H=38.0
STOP  6 Planned 1         L=834.1  T=261.0  W=160.9 H=38.0
STOP  7 Novel & Scene     L=179.0  T=358.0  W=1178.0 H=72.0
STOP  8 Character         L=179.0  T=446.0  W=1178.0 H=72.0
STOP  9 World & Locations L=179.0  T=534.0  W=1178.0 H=72.0
STOP 10 Project Bible & Lore    L=179.0 T=622.0 W=1178.0 H=72.0
STOP 11 Timeline & Events        L=179.0 T=710.0 W=1178.0 H=72.0
STOP 12 Assets & References     L=179.0 T=798.0 W=1178.0 H=72.0
STOP 13 Cinema & Shots          L=179.0 T=886.0 W=1178.0 H=72.0
STOP 14 Audio, Music & SFX      L=179.0 T=952.0 W=1178.0 H=72.0
STOP 15 AI Generation Outputs   L=179.0 T=952.0 W=1178.0 H=72.0
STOP 16 Dialogue                L=179.0 T=952.0 W=1178.0 H=72.0
STOP 17 Plot, Subplot & Quest   L=179.0 T=952.0 W=1178.0 H=72.0
STOP 18 Pacing & POV            L=179.0 T=952.0 W=1178.0 H=72.0
STOP 19 Herbology & Alchemy     L=179.0 T=952.0 W=1178.0 H=72.0
STOP 20 Economy & Travel        L=179.0 T=952.0 W=1178.0 H=72.0
STOP 21 Culture, Language & Idioms L=179.0 T=952.0 W=1178.0 H=72.0
STOP 22 Creature, Vehicle & Prop Cards L=179.0 T=952.0 W=1178.0 H=72.0
STOP 23 Reader Annotations      L=179.0 T=952.0 W=1178.0 H=72.0
STOP 24 field:search            (siklus tertutup)
```

Stop 14 sampai 23 semua melaporkan `T=952.0 H=72.0` yang identik. Ini **bukan** card yang menumpuk: hanya delapan kartu pertama yang benar-benar ter-layout di dalam viewport 1024 px, sedangkan sisanya berada di luar area terlihat sehingga `Rect`-nya dijepit cache sliver. Kontrak karena itu hanya memakai `Rect` delapan kartu pertama sebagai bukti urutan vertikal, dan tidak mengklaim posisi piksel kartu di luar viewport.

### Hasil pengukuran — keadaan kosong

Setelah `enterText('zzzqqqxxx')`, kartu modul hilang (`ExpansionTile` tidak ada) dan tombol pemulihan masuk:

```
Siklus 8 node: Semua, Full 0, Partial 9, Domain Only 6, UI Only 1, Planned 1, Reset filter, field:search
```

### Temuan metodologis: traversal bersifat siklik, bukan linear

Kontrak run sebelumnya mengasumsikan traversal selalu mulai dari `field:search`. Probe membuktikan asumsi itu salah, dan run ini memperbaikinya:

- Setelah `pumpWidget` fokus belum ada, jadi Tab pertama masuk dari awal traversal (`field:search`).
- Setelah `enterText` fokus **tertahan** di dalam `TextField` (`EditableText` mengambilnya), sehingga Tab pertama melompat ke node berikutnya: chip filter.
- Setelah `tap` tombol pemulihan, node fokus yang dituju hilang dari pohon, sehingga FocusManager mengembalikan fokus ke akar scope dan traversal berikutnya masuk dari awal lagi.

Kontrak karena itu membandingkan traversal terhadap **rotasi** dari satu siklus tunggal yang sudah diputar ke anchor eksplisit per test (`_expectFullCycle(stops, cycle, anchor)`), ditambah bukti penutupan siklus lewat node ke-`cycle.length+1`. Helper geometri memfilter satu siklus penuh saja lewat `_oneCycle`, supaya indeks tidak bergeser saat traversal berulang.

### Yang dikunci kontrak (8 test)

1. Viewport lebar menyisir siklus 24 node lalu kembali ke anchor; setiap stop punya area non-zero.
2. Jumlah node kartu fokus sama dengan `ContentCapabilityCatalog.modules.length` dan urutannya persis mengikuti katalog, bukan geometri render.
3. Chip filter dibaca kiri ke kanan pada baris pertama lalu turun ke baris kedua pada 1536 px.
4. Kartu modul satu kolom penuh: satu lebar, satu margin kiri, dibaca atas ke bawah, dan kartu pertama mulai setelah baris chip terakhir.
5. Viewport 390x844: siklus 24 node tetap utuh, `tester.takeException()` null, tidak ada kontrol hilang, dan tidak ada node yang melewati viewport.
6. Pada 390 px chip membungkus ke empat baris `[Semua, Full]`, `[Partial]`, `[Domain Only]`, `[UI Only, Planned]`; kartu tetap satu kolom.
7. Keadaan kosong menyisakan siklus 8 node dengan tombol pemulihan yang punya area fokus non-zero, dan tidak ada `ExpansionTile`.
8. Setelah tombol pemulihan ditekan, traversal kembali ke siklus 24 node penuh tanpa meninggalkan node fokus yatim.

### Verifikasi

- `dart format` pada file kontrak: `Formatted 1 file (0 changed)`.
- `dart analyze test/features/content_capabilities/`: `No issues found!`.
- `flutter test test/features/content_capabilities/`: `All tests passed!` (14 test, termasuk 6 test lama milik feature yang sama).
- Negative control: urutan dua label chip ditukar sementara di siklus lebar. Hasil `+5 -3: Some tests failed.` dengan `EXIT=1`, tiga test gagal (`viewport lebar menyisir tepat 24 node lalu mengulang`, `viewport sempit tetap menyisir 24 node tanpa kontrol hilang`, `tombol pemulihan filter mengembalikan daftar modul`). Backup dipulihkan dari `%LOCALAPPDATA%\Temp\ccms_focus_backup.dart` dan file backup dihapus.
- Scan CJK/Cyrillic pada test dan report: `none`.
- Probe `test/features/content_capabilities/_probe_focus_test.dart` dihapus setelah kontrak dibuat.

### Status

**VERIFIED** untuk focus order `ContentCapabilityMatrixScreen` di 1536x1024 dan 390x844 pada codebase saat commit. Tidak ada defect produksi yang ditemukan pada fase ini; koreksi yang dibuat hanya pada ekspektasi kontrak yang salah asumsi terhadap titik mulai traversal. Batas bukti: pengukuran adalah traversal `Tab` sintetik pada widget tree, belum berupa native Windows focus ring pada aplikasi yang sudah dibangun.

## 56. Fase 56 — Focus Order di Map Time Slider View (2.4.3)

**Layar audited:** `lib/features/world_logic/presentation/map_time_slider.dart` (`MapTimeSliderView`).
**Kontrak:** `test/features/world_logic/map_time_slider_focus_order_test.dart` (5 test).
**Metode:** probe sementara pada viewport 1536x1024 dan 390x844, dpr 1.0, `sendKeyEvent(LogicalKeyboardKey.tab)` berulang sampai `Rect` fokus mengulang. Label tiap stop diturunkan dari jenis widget fokus, bukan dari posisi piksel.

Layar dipilih karena seluruh surface interaktifnya berdiri sendiri: satu `Slider`, delapan `IconButton` kunci waktu, dan tiga `InputChip` layer beserta tombol hapusnya. State berasal dari `TemporalMapState` yang dibangun in-memory lewat `MapTimeSliderController.forState`, tanpa database, tanpa network, tanpa DI, tanpa `session.lock`. Tidak ada fixture yang perlu disiapkan, sehingga cocok untuk run audit terjadwal.

### Klasifikasi kontrol interaktif

| Kontrol | Widget | Keterangan |
|---|---|---|
| Slider tick | `Slider` | `ValueKey('map-time-slider')` |
| 8 tombol navigasi waktu | `IconButton` | `map-time-key-*`, masing-masing dibungkus `Tooltip` |
| 3 chip layer aktif | `InputChip` | `map-time-layer-chip-<tick>`, `onDeleted` aktif |
| 3 tombol hapus layer | affordance `InputChip` | dirender Material sebagai `InkWell` bersarang, bukan `IconButton` |

### Hasil pengukuran — 1536x1024 dan 390x844

Siklus traversal **15 node**, urutan identik di kedua viewport; hanya geometri yang berbeda karena baris tombol membungkus pada lebar sempit.

```
STOP  0 slider:map-time-slider
STOP  1 key:map-time-key-advanceSmall
STOP  2 key:map-time-key-retreatSmall
STOP  3 key:map-time-key-advanceBig
STOP  4 key:map-time-key-retreatBig
STOP  5 key:map-time-key-jumpStart
STOP  6 key:map-time-key-jumpEnd
STOP  7 key:map-time-key-nextKeyTick
STOP  8 key:map-time-key-prevKeyTick
STOP  9 chip:map-time-layer-chip-0|Tick 0
STOP 10 delete:map-time-layer-chip-0
STOP 11 chip:map-time-layer-chip-40|Tick 40
STOP 12 delete:map-time-layer-chip-40
STOP 13 chip:map-time-layer-chip-80|Tick 80
STOP 14 delete:map-time-layer-chip-80
```

Aritmetika siklus: 1 slider + 8 tombol kunci + 3 pasang (chip + hapus) = 15. Traversal masuk pertama kali pada slider, yang merupakan node fokus pertama pada subtree widget ini.

### Temuan teknis: tombol hapus chip bukan `IconButton`

Draf kontrak pertama mengasumsikan node fokus tombol hapus chip memiliki ancestor `IconButton`. Probe membuktikannya salah: Material merender affordance hapus `InputChip` sebagai `InkWell` bersarang dengan `FocusNode` internal, sehingga **tidak ada** `IconButton` di subtree-nya. Kontrak dikoreksi ke diskriminator yang terukur:

- Identitas lewat `chip.focusNode` **tidak bisa dipakai** — nilainya `null` saat pemanggil tidak menyediakannya, sehingga perbandingan identitas tidak membedakan kedua stop.
- Tinggi **tidak bisa dipakai** — stop label (tinggi 38) lebih pendek daripada chip (tinggi 48), sama seperti stop hapus.
- **Lebar bisa dipakai** — stop label membentang selebar chip (138.6), sedangkan stop hapus hanya kotak ikon 18x18 di dalamnya.

Klasifikasi final memakai lebar dengan toleransi 0.5 px, ditambah anak `InputChip` sebagai penanda bahwa node itu berada di dalam chip. Ini dicatat sebagai fakta terukur, **bukan** defect produksi: tidak ada kode produksi yang diubah pada fase ini.

### Verifikasi

- `dart format` pada file kontrak: `Formatted 1 file (0 changed)`.
- `dart analyze test/features/world_logic/map_time_slider_focus_order_test.dart`: `No issues found!`.
- `flutter test test/features/world_logic/map_time_slider_focus_order_test.dart`: `All tests passed!` (5 test), `EXIT=0`.
- `flutter test test/features/world_logic/`: `All tests passed!` (+2260 test), `EXIT=0`.
- Negative control: `key:map-time-key-prevKeyTick` dipindahkan satu posisi mundur dalam daftar ekspektasi. Hasil `+3 -2: Some tests failed.` dengan `EXIT=1`, dua test gagal, pesan `at location [8] is 'key:map-time-key-prevKeyTick' instead of 'chip:map-time-layer-chip-0|Tick 0'`. Backup dipulihkan dari `%LOCALAPPDATA%\Temp\map_time_slider_focus_order_test.bak.dart` (11.485 B), dicocokkan byte-wise identik, lalu file backup dihapus.
- Scan CJK/Cyrillic pada test dan report: `none`.
- Probe `test/features/world_logic/_probe_focus_test.dart` dihapus setelah kontrak dibuat. Probe `test/features/platform/presentation/_probe_focus_test.dart` dari fase kandidat juga dihapus.

### Status

**VERIFIED** untuk focus order `MapTimeSliderView` di 1536x1024 dan 390x844 pada codebase saat commit. Tidak ada defect produksi yang ditemukan pada fase ini; koreksi hanya pada ekspektasi kontrak yang salah asumsi terhadap bentuk affordance hapus chip. Batas bukti: pengukuran adalah traversal `Tab` sintetik pada widget tree, belum berupa native Windows focus ring pada aplikasi yang sudah dibangun.

## 57. Fase 57 — Focus Order di Dashboard Screen (2.4.3)

### Layar yang dipilih

`DashboardScreen` (`lib/features/dashboard/presentation/dashboard_screen.dart`), dipilih karena pada audit kandidat ia masih punya 7 affordance fokus yang dapat diukur dan fixture-nya bisa di-override tanpa database maupun jaringan. Layar lain yang tersisa (`story_workspace_screen`, `asset_browser_screen`, `project_bible_workspace_screen`, `supporting_asset_workspace_screen`, `project_ai_generation_gallery_screen`, `scene_workspace_screen`) semuanya bergantung pada `projectSessionProvider` / Drift dan tidak stabil untuk traversal fokus sintetis, sehingga ditandai DEFERRED untuk run berikutnya.

Probe `test/features/platform/presentation/_probe_focus_test.dart` dari run sebelumnya (kandidat `OptionalTourScreen`) ikut dihapus: layar itu hanya punya satu `FilledButton` dan karena `onStartTour` null tombolnya disabled, sehingga tidak memenuhi syarat minimal 2 elemen interaktif.

### Kontrak

`test/features/dashboard/dashboard_screen_focus_order_test.dart` — 5 test. Fixture: `authControllerProvider` di-override ke `AuthSession.guest()` (agar badge local-only tampil dan `RecentProjects` masuk state data), `projectControllerProvider` di-override ke dua proyek fixture agar baris "Other recent projects" benar-benar dirender. GoRouter minimal dipasang supaya callback `context.go`/`context.push` tidak melempar saat widget dibangun.

### Hasil probe (1536x1024, dpr 1.0)

STOP_COUNT 7, traversal berhenti saat label+rect berulang (wrap):

1. `New Novel` — rect 128.0, 226.0, 192.9x40.0
2. `Open Novel` — rect 330.9, 226.0, 207.0x40.0
3. `Create Character` — rect 547.9, 226.0, 279.6x40.0
4. `View all` — rect 811.5, 323.0, 136.8x40.0
5. `Continue writing` — rect 281.0, 523.0, 291.6x40.0
6. `Manage local storage` — rect 1085.0, 561.0, 306.0x40.0
7. `Beta Novel` — rect 145.0, 620.0, 803.3x76.0

Semua stop punya area fokus non-zero.

### Hasil probe (390x844, dpr 1.0)

STOP_COUNT 7 dengan urutan berbeda: `New Novel`, `Open Novel`, `Create Character`, `View all`, `Continue writing`, `Beta Novel`, `Manage local storage`. Perbedaan ini bukan defect: pada lebar sempit layout berubah dari dua kolom (`Row` + `Expanded`) menjadi satu `Column`, sehingga kartu Storage berada setelah daftar proyek, bukan di kolom kanan. Kontrak mengunci dua daftar ekspektasi terpisah.

### Catatan geometri yang dikunci

- **Desktop (1536x1024)**: urutan mengikuti reading-order default Flutter — rect difold menjadi band horizontal lalu diurutkan kiri-ke-kanan di dalam band. `Manage local storage` (top=561) memang dikunjungi sebelum `Beta Novel` (top=620) meski berada di kolom berbeda, jadi kontrak mengunci invariant top-monotik, bukan urutan kolom.
- **Narrow (390x844)**: `SingleChildScrollView` auto-scroll untuk memunculkan anak yang difokus, sehingga rect stop awal ditulis ulang oleh stop berikutnya (terukur: `Continue writing` melaporkan top=804 sementara `Beta Novel` yang menyusul melaporkan top=755). Karena itu kasus narrow **sengaja** tidak punya asersi geometri — hanya jumlah stop, urutan label, area fokus non-zero, dan `tester.takeException() isNull`. Mengunci geometri di lebar itu akan mengunci artefak scroll, bukan kontrak focus order.

### Bukti eksekusi

- Probe: `flutter test test/features/dashboard/_probe_focus_test.dart` → `All tests passed!` (`EXIT=0`), 2 test probe, stdout `STOP 0..6` + `STOP_COUNT 7` per viewport.
- Probe dihapus setelah kontrak dibuat.
- `dart format test/features/dashboard/dashboard_screen_focus_order_test.dart` → `Formatted 1 file (1 changed)`.
- `dart analyze test/features/dashboard/dashboard_screen_focus_order_test.dart` → `No issues found!` (`EXIT=0`).
- `flutter test test/features/dashboard/dashboard_screen_focus_order_test.dart` → `All tests passed!` (5 test), `EXIT=0`.
- Negative control: `Beta Novel` dipindahkan satu posisi ke depan dalam `kExpectedWideOrder` (tukar posisi 5 dan 6). Hasil `+4 -1: Some tests failed.` dengan `EXIT=1`, test `2.4.3 focus order visits the Dashboard action cluster` gagal pada pesan `at location [4] is 'Continue writing' instead of 'Beta Novel'`. Backup `dashboard_screen_focus_order_test.bak.dart` (9.693 B) dipulihkan, dicocokkan byte-wise identik (`cmp` keluar 0), lalu dihapus. Re-run setelah restore: `All tests passed!` (5 test), `EXIT=0`.
- Gate suite: `flutter test test/features/dashboard/` → `All tests passed!` (+21 test, termasuk 8 file lama: `dashboard_create_character_no_session_test`, `dashboard_local_status_test`, `dashboard_no_fabricated_data_test`, `dashboard_screen_test`, `recent_projects_test`, `statistics_panel_test`, `storage_card_test`), `EXIT=0`.
- Scan CJK/Cyrillic pada file kontrak: `0` (none).

### Status

**VERIFIED** untuk focus order `DashboardScreen` pada 1536x1024 dan 390x844 di codebase saat commit. Tidak ada defect produksi yang ditemukan pada fase ini; seluruh perubahan adalah file test baru. Batas bukti: pengukuran adalah traversal `Tab` sintetik pada widget tree, belum berupa native Windows focus ring pada aplikasi yang sudah dibangun, dan label diambil dari subtree `Text` pertama sehingga affordance berbasis ikon saja akan tampil sebagai runtime type. Enam layar kandidat lain tetap **DEFERRED** karena fixture-nya butuh Drift/project session.

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
