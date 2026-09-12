# Referee report — vs-hunt-20260913-importer (run265)
- target: importer/thumbnail/reference/binder vertical (9 lib + 3 test files)
- repo: D:\VoidScriptor\void_scriptor_multiplatform, branch master
- HEAD hunt start: 50c6221; HEAD referee done: 50c6221 (no commits mid-hunt by siblings during stages)
- agents: Hunter 6 findings (40 pts) -> Skeptic accepted 6/6 (parent recorded its failure to check reachability) -> Referee independent verdict below
- stage note: Referee attempt #1 died on upstream 429 after 11 calls; attempt #2 completed with compact brief. Delegation model gemini/gemini-3.5-flash-lite.

## Confirmed (Referee verdicts, authority)

| # | Severity | File | Lines | Description | Fix direction |
|---|----------|------|-------|-------------|---------------|
| BUG-3 | Medium | lib/features/bible/application/timeline_era_image_importer.dart | 72-74 | Orphan era image on disk if repo.saveEra throws after copy | try/catch delete target + rethrow, mirror faction_image_importer (2a55bd7) |
| BUG-4 | Medium | lib/features/assets/application/asset_thumbnail_importer.dart | 73-76 | Orphan thumbnail on disk if assetDao.setThumbnail throws after copy | try/catch delete target + rethrow, same pattern |
| BUG-5 | Low | lib/features/references/application/reference_bulk_importer.dart | 186-201 | Mid-batch failure leaves orphan files + partial rows; no rollback. Referee: partial import idempotent on re-run via content-hash dedup (byContentHash) — reduced to Low | defer: transaction or per-item cleanup; not in this run's slice |

## Dismissed (transparency)
- BUG-1 (claimed Critical data loss in character_reference_binder): Referee NOT A BUG — new file copied BEFORE delete loop, addReference uses fresh Uuid so constraint failure ~impossible; residual = catastrophic-disk-failure-only; fix direction if ever touched: wrap in database.transaction. True severity Low/theoretical.
- BUG-2 / BUG-6 (claimed Critical/Medium path traversal via assetId/eraId): Referee NOT A BUG — ids originate from local app-generated UUIDs / local DB; exploitation requires tampered local DB or malicious backup crossing the local-first trust boundary. Theoretical only => Low max, no fix mandated.

## Evidence contract
- findings carry file:line + quoted evidence from Hunter, re-read by Skeptic and Referee independently
- commands run by agents: read_file/search_files only (read-only per skill)
- status: VERIFIED (scope fully read by all three stages; 12/12 files)

## Queue disposition
- BUG-3 + BUG-4 = one slice (same defect class, established repo pattern), executed by parent this run via TDD.
- BUG-5 remains queued (Low). BUG-1/2/6 recorded as dismissed with rationale; not to be re-fixed without new reachability evidence.
