# Account & Cloud Center — protected visual baseline

Status: **LOCKED BY OPERATOR**  
Effective: 2026-10-07  
Owner: Choirudin / Choi

The supplied 1536x1024 Account & Cloud Center artwork is the approved desktop
baseline. Agents, cron workers, bug hunters, and automated refactors MUST NOT
change the geometry, spacing, card order, rail placement, or `referenceVisual`
route wiring without a new explicit user instruction.

Protected paths:

- `lib/features/account/presentation/account_cloud_center_screen.dart`
- `lib/features/account/domain/account_center_wide_desktop_frame.dart`
- `lib/features/account/domain/account_center_design_tokens.dart`
- `lib/app/routing/app_router.dart` (Account & Cloud Center route wiring only)
- `lib/app/shell/desktop/void_desktop_shell.dart` and `void_top_bar.dart`
  (the route-level 52px Account Center chrome override only)
- `test/features/account/presentation/account_cloud_center_reference_visual_test.dart`

Approved geometry at a 1536px desktop viewport:

- page padding: 17px horizontal, 12px vertical
- Account Center route top bar: 52px
- left Account Center rail: 0px (global app navigation remains the owner)
- main grid: 1141px
- main-to-summary seam: 19px
- right summary rail: 342px
- status bar: 40px
- overview card rhythm: 3 / 5 / 5 columns

If a change is needed, the worker must stop and report `BLOCKED — protected
visual baseline requires explicit operator approval`. Do not update the
baseline test to make an unapproved visual change pass. A new design requires
an explicit user message and a new visual-baseline document/test review.
