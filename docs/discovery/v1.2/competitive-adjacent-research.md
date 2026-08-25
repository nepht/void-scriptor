# 108.15 — Competitive & Adjacent Research

> Sprint 108 · disusun 2026-08-25 · kanonik required_outputs:
> patterns, tradeoffs, differentiation_opportunities, sources, research_date
> Metode: riset web terbatas (sumber publik nyata, tercantum di bawah);
> pola dipelajari TANPA menyalin fitur otomatis.

## Patterns (pola produk relevan)

1. **Modularitas sebagai strategi** (Campfire Writing, ±17 modul beli-per-modul):
   pengguna memilih subsistem yang penting baginya — persis mengakui bahwa
   tidak semua orang menyentuh semuanya. Void Scriptor punya 157 tabel tapi
   pemakaian nyata hanya 5 → masalah yang sama, tanpa lapisan onboarding.
2. **Interlinking wiki-style** (World Anvil): nilai utama dunia besar adalah
   tautan antar-entitas (`[@Karakter]` jadi link). VS punya entity graph +
   relasi terstruktur — kapabilitas setara belum diekspose sebagai nilai.
3. **AI dengan kunci milik pengguna (BYO)** (Novelcrafter: OpenRouter/OpenAI/
   Anthropic/Gemini/**bahkan lokal via LM Studio/Ollama**) vs langganan AI
   tertutup (Sudowrite). Pasar bergerak ke arah yang SAMA dengan arsitektur
   provider-registry VS: remote opt-in + antarmuka lokal dipelihara.
4. **Desktop + data lokal sebagai pembeda yang diiklankan** (Campfire:
   "work lives on your computer"): mayoritas pesaing web/cloud-first;
   offline-first VS bukan kelemahan melainkan posisi produk.

## Tradeoffs yang terlihat

- Modularitas ↔ biaya & kompleksitas pilihan (modul Campfire mahal kalau
  diambil semua; 157 subsistem VS membingungkan bila semua ditonjolkan).
- Komprehensif ↔ kurva belajar (World Anvil kuat tapi terjal).
- Kolaborasi awan ↔ privasi/kontrol lokal (komunitas World Anvil ≠ offline).
- AI bawaan ↔ fleksibilitas BYO (Sudowrite mudah tapi terkunci).

## Differentiation_opportunities untuk VS

a. Satu-satunya studio penulisan **offline-first berbasis proyek-folder**
   (`.voidproject` portabel + backup lokal) di segmen ini.
b. **Automation dengan gerbang approval** — tak ada pesaing yang punya padanan;
   nilainya belum tersalurkan (108.11) tapi kapabilitasnya unik.
c. Kedalaman data terstruktur (Bible/canon/timeline) + naratif dalam satu DB.
d. Belum ada pesaing yang serius untuk penulis berbahasa Indonesia.

## Sources

- loreteller.com/learn/world-anvil-vs-campfire/ (perbandingan mendalam)
- campfirewriting.com/learn/world-anvil-vs-campfire (posisi resmi Campfire)
- forum.literatureandlatte.com/t/scrivener-vs-world-anvil/94727
- novelcrafter.com; sudowrite.com/blog (Sudowrite vs Novelcrafter)
- ilampadmanabhan.medium.com (Sudowrite vs Novelcrafter, rincian BYO-key)

research_date: 2026-08-25
