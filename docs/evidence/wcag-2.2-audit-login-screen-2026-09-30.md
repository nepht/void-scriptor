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
