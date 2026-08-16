# Sprint 37 — Enterprise Studio Management

> **STATUS: DONE** — 37.1–37.21 GREEN, 702 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S37 Enterprise Studio Management") — hanya judul.
> Fondasi audit: `Collaborator` (owner/editor/viewer), `CollaboratorRepository`,
> `ProjectComment`, table `project_collaborators`.

## Tujuan

Membangun **enterprise studio management** deterministic: organisasi (studio), hierarki role
dengan permission matrix, team member, seat/license, dan audit log. Bukan SSO/LDAP real.

## Batas lingkup (jujur)

- **IN**: `Studio` (organisation identity), `StudioRole` (admin/member/viewer) + permission
  matrix, `TeamMember` (user + role + status), `SeatLicense` (seat allocation + enforcement),
  `AuditLog` (event + actor + timestamp), `StudioRegistry` (org + members + audit),
  UI `StudioManagementPanel` + route `/studio`.
- **OUT**: SSO/SAML/OIDC, LDAP/Active Directory, real billing/subscription, quota
  enforcement server-side. Ini **model + registry** CPU.

## Step

### Blok A — Studio + role (37.1–37.3)
- **37.1** `Studio` (id, name, plan).
- **37.2** `StudioRole` enum (admin, member, viewer) + permission matrix.
- **37.3** `Permission` enum + `StudioRole.can(permission)`.

### Blok B — Team member (37.4–37.6)
- **37.4** `TeamMember` (userId, role, status).
- **37.5** `MemberStatus` enum (invited, active, suspended).
- **37.6** `TeamMember.can(permission)` delegates to role.

### Blok C — Seat license (37.7–37.9)
- **37.7** `SeatLicense` (maxSeats, usedSeats).
- **37.8** `SeatLicense.allocate()` / `release()` with over-capacity guard.
- **37.9** `SeatLicense.isAtCapacity`.

### Blok D — Audit log (37.10–37.12)
- **37.10** `AuditEvent` (actor, action, target, timestamp).
- **37.11** `AuditLog` (append + query by actor/action).
- **37.12** Audit log size cap (ring buffer).

### Blok E — Studio registry (37.13–37.15)
- **37.13** `StudioRegistry` (org + members + audit + seats).
- **37.14** Registry add member with seat enforcement.
- **37.15** Registry persist (schema v47→**v48**).

### Blok F — UI (37.16–37.18)
- **37.16** `StudioManagementPanel` (org + seats).
- **37.17** `TeamMemberList`.
- **37.18** `AuditLogView`.

### Blok G — Demo + wire (37.19–37.21)
- **37.19** Wire route `/studio`.
- **37.20** `DemoStudio` built-in.
- **37.21** DoD: full regression gates + commit + tandai DONE.

## Schema v48
- `studio_members` (userId PK, role, status, studioId).
- `audit_events` (id PK, actor, action, target, timestamp).

## Risiko jujur
- Registry + permission matrix + audit log CPU; bukan SSO/billing/quota server real.
