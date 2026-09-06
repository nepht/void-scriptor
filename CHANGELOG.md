# Changelog

All notable release changes will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Void Scriptor has not published a production release, so current work remains under **Unreleased**.

## [Unreleased]

### Added

- Repository-local security workflow with scheduled and pull-request Gitleaks history scanning.
- Deterministic CycloneDX SBOM and third-party notices generation.
- Dependabot configuration for Pub and GitHub Actions dependencies.
- Security policy, contribution contract, pull-request evidence template, code ownership, and release checklist.

### Security

- Third-party GitHub Actions are pinned to immutable commit SHAs.
- Workflow permissions are read-only and checkout credentials are not persisted.
