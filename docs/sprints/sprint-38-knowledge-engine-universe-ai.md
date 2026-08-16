# Sprint 38 — Knowledge Engine + Universe AI

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S38 Knowledge Engine+Universe AI") — hanya judul.
> Fondasi audit: `BibleEntries` (type/title/content/canonStatus/tagsJson),
> `RelationDao`/`AssetRelations` (graph relations), `StoryDao`, `CharacterDao`,
> `RelationDao` outgoing/incoming relations.

## Tujuan

Membangun **knowledge engine + universe AI** deterministic: ontology entity graph,
semantic query, cross-entity inference, universe consistency validation, dan
AI-assisted retrieval. Bukan embedding/vector DB real.

## Batas lingkup (jujur)

- **IN**: `KnowledgeEntity` (id, type, title, facts), `EntityRelation`
  (source/target/kind), `KnowledgeGraph` (add/query/traverse), `UniverseValidator`
  (consistency rules + violations), `KnowledgeQuery` (semantic-ish keyword retrieval),
  `UniverseAi` (assisted retrieval + suggestion), UI `KnowledgeEnginePanel` + route `/knowledge`.
- **OUT**: real LLM embedding/vector index, neural retrieval, external AI API calls.
  Ini **symbolic graph + rule-based** engine CPU.

## Step

### Blok A — Entity + relation (38.1–38.3)
- **38.1** `KnowledgeEntity` (id, type, title, facts).
- **38.2** `EntityRelation` (sourceId, targetId, kind).
- **38.3** `EntityType` enum (character, location, item, faction, event, concept).

### Blok B — Knowledge graph (38.4–38.6)
- **38.4** `KnowledgeGraph` (add entity/relation).
- **38.5** `neighbors(id)` + `relationsOf(id)`.
- **38.6** `traverse(id, maxDepth)` BFS.

### Blok C — Universe validator (38.7–38.9)
- **38.7** `UniverseValidator` rule registry.
- **38.8** Consistency rule: no duplicate entity title within type.
- **38.9** `validate(graph)` → violations list.

### Blok D — Query + universe AI (38.10–38.12)
- **38.10** `KnowledgeQuery` keyword search over entities + facts.
- **38.11** `UniverseAi` assisted retrieval (ranked results).
- **38.12** `UniverseAi.suggest()` related entities.

### Blok E — Persistence (38.13–38.15)
- **38.13** Table `knowledge_entities` (schema v48→**v49**).
- **38.14** Table `knowledge_relations`.
- **38.15** `KnowledgeRepository` + restart persistence test.

### Blok F — UI (38.16–38.18)
- **38.16** `KnowledgeEnginePanel` (entity count + query).
- **38.17** `KnowledgeEntityList`.
- **38.18** `UniverseValidationView`.

### Blok G — Demo + wire (38.19–38.21)
- **38.19** Wire route `/knowledge`.
- **38.20** `DemoKnowledge` built-in.
- **38.21** DoD: full regression gates + commit + tandai DONE.

## Schema v49
- `knowledge_entities` (id PK, type, title, factsJson).
- `knowledge_relations` (id PK, sourceId, targetId, kind).

## Risiko jujur
- Symbolic graph + rule validation CPU; bukan embedding/vector/neural retrieval.
