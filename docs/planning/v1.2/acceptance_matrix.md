# 109.2 Output 3/4 — Acceptance Matrix (Sprint 109)

> Sumber: array `acceptance`/`outputs` verbatim dari `sprint_109.json` (kanonik, folder outputs
> 2026-08-22). Total **170 kriteria pada 35 langkah fitur** (13 capability) — diverifikasi
> programatik: 30 langkah × 5 + 109.10/109.11 × 4 + tiga langkah kontrak-skema
> (109.12/109.25/109.41) × 4 output = 170.
> Status seluruhnya PENDING sampai langkah masing-masing tereksekusi dengan bukti.
> Metode verifikasi default per kriteria: unit/widget/integration test TDD; kriteria
> bertanda § diverifikasi juga lewat dokumen/demonstrasi tercatat (bukan cuma kode).

Legenda metode: `U` unit · `W` widget · `I` integration/restart · `D` dokumen/demo.

## F1 Inline Lore Linking (109.9–11)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.9 | parse_valid_links · preserve_plain_text · handle_rename · escape_syntax · round_trip | U |
| 109.10 | keyboard_navigation · duplicate_warning · create_entity · hover_or_focus_preview | U+W |
| 109.11 | backlink_query · broken_link_report · ambiguous_link_report · repair_action | U+W |

## F2 Story Contradiction Detector (109.12–14)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.12 | rule_schema · severity_model · confidence_model · explanation_contract | U+D |
| 109.13 | incremental_scan · source_citations · deterministic_rules · dismissal_state · rescan | U+I |
| 109.14 | severity_filter · entity_filter · jump_to_source · resolve_or_dismiss · history | U+W |

## F4 Character Voice Interview (109.15–16)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.15 | question_sets · first_person_answers · session_history · manual_edit · source_provenance | U+I |
| 109.16 | editable_voice_rules · dialogue_comparison · explain_warning · disable_rule · no_auto_rewrite | U |

## F7 Constructed Language Dictionary (109.17–19)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.17 | multiple_languages · dictionary_search · variant_forms · usage_examples · import_export | U+I |
| 109.18 | grammar_rules · phoneme_inventory · orthography_map · script_notes · version_history | U+I |
| 109.19 | dictionary_lookup · unknown_term_warning · variant_awareness · jump_to_occurrence · user_override | U+W |

## F8 Focus Writing, Word Targets & Draft Snapshots (109.20–22)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.20 | distraction_free · keyboard_exit · autosave_visible · theme_support · screen_reader_access | W (+a11y review 109.48) |
| 109.21 | target_levels · live_progress · session_reset · history · timezone_safe | U |
| 109.22 | automatic_snapshot · manual_snapshot · diff_view · restore_creates_backup · retention_controls | U+I |

## F9 Global Lore Graph (109.23–24)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.23 | filter_nodes · filter_edges · focus_entity · source_navigation · large_graph_fallback | U+W |
| 109.24 | orphan_report · conflict_path · missing_relation_hint · explain_result · dismiss_hint | U |

## F10 Kanban Plot Board (109.25–27)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.25 | board_schema · card_schema · ordering_contract · story_sync_contract | U+D |
| 109.26 | drag_reorder · keyboard_reorder · multi_select · undo · screen_reader_announcement | U+W (+a11y) |
| 109.27 | explicit_sync · conflict_preview · dependency_warning · undo_sync · history | U+I |

## F12 Character Visual Moodboard (109.28–29)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.28 | local_media · categories · annotations · source_credit · missing_file_state | U+I |
| 109.29 | attribute_registry · scene_comparison · explain_warning · timeline_awareness · user_override | U |

## F16 Spoiler-Aware Sharing (109.30–32)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.30 | spoiler_levels · reveal_point · audience_policy · inheritance_rules · safe_default | U |
| 109.31 | preview_as_reader · redaction · hidden_links · no_metadata_leak · revocable_access | U (+security test anti-leak wajib) |
| 109.32 | preflight_report · audience_manifest · sanitized_export · share_expiry · revoke | U+I |

## F17 POV Consistency Tracker (109.33–35)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.33 | scene_pov · section_override · tense · narration_mode · visible_status | U |
| 109.34 | knowledge_events · timeline_query · source_reference · uncertain_knowledge · secret_handling | U+I |
| 109.35 | narration_analysis · knowledge_violation · jump_to_text · false_positive_control · chapter_report | U+W |

## F18 Pacing & Tension Heatmap (109.36–37)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.36 | manual_scale · custom_labels · duration_signal · word_count_signal · arc_aggregation | U |
| 109.37 | heatmap · chapter_view · arc_view · long_plateau_hint · custom_thresholds | U+W |

## F19 Clean Manuscript Export (109.38–40)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.38 | profile_settings · chapter_rules · scene_break_rules · front_matter · saved_presets | U |
| 109.39 | strip_internal_links · strip_private_notes · preserve_formatting · deterministic_output · no_source_mutation | U (deterministic_output = golden-file test) |
| 109.40 | preflight_report · blocking_errors · warnings · sample_preview · export_manifest | U |

## F25 Subplot, Mission & Quest Tracker (109.41–43)

| Langkah | Kriteria | Metode |
|---|---|---|
| 109.41 | quest_schema · dependency_schema · stakeholder_links · outcome_schema | U+D |
| 109.42 | board_views · story_links · status_flow · dependency_view · filters | U+W |
| 109.43 | unresolved_report · deadline_or_story_point · failure_consequence · dismissal_reason · closure_history | U |

## Gerbang lintas-fitur (mengikat semua di atas)

| Langkah | Bukti wajib |
|---|---|
| 109.44 | stable_ids · explicit_novel_character_links · no_cross_workspace_co_ownership · no_circular_ownership · unlink_does_not_delete_character · graceful_partial_failure · distinct_navigation |
| 109.45 | suite: unit, integration, contract, migration, ui, end_to_end, regression |
| 109.46 | datasets, baselines, budgets, results, bottlenecks, mitigations |
| 109.47 | threat_review, permission_tests, redaction_tests, leakage_tests, findings, fix_status |
| 109.48 | keyboard/screen_reader/scaling/contrast/locale results + fix_status |
| 109.49 | feature_guides, tooltips, privacy_notes, recovery_guide, known_limits |
