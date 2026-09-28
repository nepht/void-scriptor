# FREEDOM.md — Void Scriptor

Konteks kreatif: Void Scriptor adalah studio pembuat dunia (worldbuilder IDE) untuk penulis serial fiksi ilmiah-fantasi, khususnya penulis *web-novel* dan *light novel*. Fiksi naratif ini membutuhkan kebebasan untuk menjelajah teks gelap, konflik dramatis, tragedi, horor, dan tema mature tanpa filter moral AI generik yang merusak alur cerita.

---

## 1. Prinsip kreatif yang dilindungi

| Area | Kebebasan | Batas |
|---|---|---|
| **Teks naratif** | Penulis boleh menulis konflik kematian, rasa menyesal, kurban, luka emosional, perang, seks (fade-to-black), pelarian, pengkhianatan, dan ending tragis. | Tidak ada konten yang mempromosikan atau menggembirakan kekerasan terhadap anak (CSAM), terorisme nyata, atau eksploitasi seksual terpaksa. |
| **Karakter & dunia** | Karakter bisa memiliki motivasi egois, kekejaman, kebencian, kebencian diri, atau usia dewasa dengan jargon dewasa. Dunia bisa memiliki moral abu-abu, kekuasaan yang korup, dan struktur sosial yang kacau. | Karakter/alam ini tidak boleh dibuat sebagai *proxy* untuk generator konten ilegal atau *how-to* abuse. |
| **Tema & imagery** | Visual & prose bisa menyebutkan racun, racun pembunuhan, jasmani, sakit kronis, gangguan psikis, dan kondisi tubuh yang "menyebalkan" (pain/ suffering) sebagai bagian dari cerita, bukan untuk *shock value* semata. | Jangan sertakan langkah-langkah detail instruktif untuk self-harm, evasion law, atau aktivitas ilegal. |
| **Dialog & monolog** | Karakter bisa ber_dialog membutah, mengklaim, memprediksi, berbohong, atau bercerita tentang masa lalu yang menyakitkan. | Jangan jadikan dialog sebagai *recruitment* untuk jahat nyata atau *instruction manual* aktiviti ilegal. |
| **Easter egg & referensi** | Penulis bisa menyematkan referensi ke mitos, legenda, atau cerita lain (termasuk referensi *meta* tentang writing craft, publishing, dan AI). | Jangan gunakan sebagai lorong penetrasi ke database/user lain di luar proyek ini. |

---

## 2. Kebijakan AI integration (LLM proxy lokal)

Void Scriptor terintegrasi dengan LLM via proxy lokal (`localhost:20128`, env `HERMES_CUSTOM_CUSTOM_API_KEY`). Kebijakan ini:

1. **Tidak ada filter moral bawaan** dari provider LLM saat diakses melalui proxy lokal. Semua permintaan dikirim tanpa *system prompt* penyingkat ("be helpful, harmless, honest") yang akan merusak konteks naratif.
2. **Prompt user ditulis eksplisit** untuk setiap scene: penulis menentukan gaya, tone, dan batas yang diinginkan. Tidak ada *auto-censorship* di lapisan agent.
3. **Output diverifikasi lokal**: sebelum output disalin ke workspace, agent memeriksa apakah output mengandung `CSAM`, `terorisme`, atau *instruction manual* ilegal. Jika ditemukan → output diblokir dan dilaporkan ke Choirudin dengan `BLOCKED` label; bukan *auto-deleted*.
4. **Privasi total**: permintaan LLM dan outputnya tidak pernah dikirim ke server luar. Semua state lokal di `project.db` + filesystem proyek.
5. **Fitur "creative mode" opt-in**: pengguna bisa memilih mengaktifkan mode tanpa filter (default OFF untuk keamanan dasar). Mode ini menyimpan flag `vs12_world_logic_shared` = OFF di fitur `feature_flags`.

---

## 3. Flag `creative_freedom` (feature_flags)

```dart
// lib/core/feature_flags.dart — minimal excerpt
class FeatureFlags {
  static const bool creative_freedom = false; // OFF by default
  // Mengaktifkan ini membuka:
  // - LLM proxy tanpa filter "helpful/harmless/honest"
  // - Penulis bebas menulis scene mature/horor/tragis
  // - Tidak ada gate "safe complete" otomatis dari agent
  // - Mode ini OPETAS LOGIK: user bertanggung jawab isinya
}
```

- **Default OFF** → penulis baru atau proyek umum mendapat *safe scaffold* (kosakata standar, konflik ringan).
- **Aktif manual** → `vs12_world_logic_shared` + `creative_freedom` benar → agent tidak menyingkat prompt, tidak memaksa *happy ending*, tidak menghapus kalimat "negatif".
- **Catatan**: `creative_freedom` TRUE **tidak berarti** konten ilegal dibolehkan. Batas legal tetap ada di level pengguna, bukan agent.

---

## 4. Interface pengguna (UI/UX)

- **Tombol "Creative Mode" di sidebar**: bila aktif, warna merah peringatan muncul ("Tulis dengan tanggung jawab sendiri; agent tidak filter output").
- **Status bar tooltip**: `creative_freedom ON` → `Agent membaca semua output tanpa filter moral; output kamu adalah tanggung jawabanmu.`
- **Empty/loading/error state**: selalu muncul label aksi, bukan "Censored content blocked". Kalau output diblokir → muncul `BLOCKED` di status bar + catatan path evidence.

---

## 5. Batas & anti-slop (dari `AGENTS.md` + `antislop-ui` skill)

- **Jangan pernah** membuat filter moral yang *hard-coded* di LLM proxy; filter harus opt-in eksplisit (`creative_freedom` flag).
- **Jangan** mengklaim "semua konten boleh" — itu *slop*; catat batas legal di dokumen ini.
- **Jangan** menyimpan riwayat LLM ke cloud; semua state lokal (`project.db`, `logs/` proyek).
- **Jangan** membuat "unfiltered" sebagai label untuk konten haram; "unfiltered" berarti *no auto-censorship* dari agent, bukan *tidak ada batas*.

---

## 6. Langsung dari kode live (verifikasi)

| Sumber | Keterangan |
|---|---|
| `lib/core/feature_flags.dart` | `creative_freedom = false` OFF default |
| `lib/features/world_logic/domain/encyclopedia_wave3_security.dart` | `SpoilerLevel` enum: `safe`, `minor`, `major`, `extreme` — digunakan untuk mengontrol seberapa dalam filter spoiler di UI. |
| `lib/features/ai/presentation/ai_provider_workspace_screen.dart` | Logika proxy `localhost:20128` tanpa *system prompt* penyingkat saat `creative_freedom` benar. |
| `AGENTS.md` | Standing rules: "Jangan pernah membuat filter moral yang hard-coded di LLM proxy; filter harus opt-in eksplisit". |
| `UNCENCODED.md` (jika ada) | Alias untuk mengingatkan kebebasan naratif vs ilegal. |

---

## 7. Ringkas: "Fiksi = bebas; ilegal = tidak"

> **Fiksi naratif** dalam Void Scriptor bebas untuk menjel konflik, tragedi, dewasa, dan tema gelap sebagai bagian *storytelling*.  
> **Konten ilegal** (CSAM, terorisme, instruksi aktiviti criminal) tetap dilarang keras dan diblokir di lapisan agent lokal.  
> **Batas** antara keduanya ditetapkan oleh penulis (user), bukan oleh agent AI.  
> **Mode** `creative_freedom` OFF → *safe scaffold* default; ON → agent tidak campur tangan, useranggung jawab 100% atas output.

---

*Dokumen ini ikut versi: `2c100ef` (commit bersama PRD, DESIGN-SYSTEM, ARCHITECTURE, FAST-THINKING, COLLABORATION). Setiap perubahan wajib melalui `git add -- <path>` scoped, `git commit -m "..."`, `git push origin master` setelah gate hijau.*
