# 109.41 — Subplot & Quest Data Model

**Output kanonik:** `quest_schema`, `dependency_schema`,
`stakeholder_links`, `outcome_schema`.

## Implementasi

`lib/features/subplot/domain/story_quest.dart` menyediakan model domain murni
untuk misi naratif. Modul dan tipe memakai prefiks `StoryQuest*` untuk
menghindari tabrakan dengan `Quest`/`QuestStatus` yang sudah ada di
`lib/features/game/domain/quests.dart`.

- `StoryQuest`: ID immutable, judul, tujuan, pemberi tugas, status,
  dependencies, stakeholder, dan outcome.
- `StoryQuestDependency`: quest prasyarat beserta status yang diwajibkan;
  default `completed`.
- `StoryQuestGraph`: validasi self-dependency, referensi yang tidak dikenal,
  dan siklus dependency.
- `StoryQuestStakeholder`: relasi typed ke character/location/faction/item
  dengan peran giver/ally/opponent/destination/subject/beneficiary.
- `StoryQuestOutcome`: konsekuensi sukses atau gagal serta entitas terdampak.
- Status terminal `completed`/`failed` wajib memiliki outcome sejenis.
- Koleksi dibungkus unmodifiable dan `copyWith` menghasilkan instance baru.

## Batas skema

Langkah ini tidak mengubah Drift. D-SCHEMA-01 masih OPEN sampai gate 109.51;
model ini adalah contract domain yang dapat dipetakan ke persistence setelah
ratifikasi evolusi skema.

## Bukti TDD

| Output | Bukti fokus |
|---|---|
| `quest_schema` | Identitas, objective, giver, status, copy immutable, validasi field wajib. |
| `dependency_schema` | Evaluasi status prasyarat; graph mendeteksi self/unknown/cycle. |
| `stakeholder_links` | Empat tipe entitas dan role typed; query menurut tipe. |
| `outcome_schema` | Konsekuensi sukses/gagal dan entitas terdampak; terminal status wajib outcome pasangan. |

## Iterasi jujur

Fixture awal memakai `const StoryQuest`, tetapi konstruktor melakukan validasi
runtime dan defensive-copy sehingga memang non-const. `const` dilepas hanya
dari root object; 12 child value object kemudian dibuat const untuk memenuhi
analyzer. Implementasi perilaku tidak dilemahkan.
