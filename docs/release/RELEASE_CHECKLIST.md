# Void Scriptor Release Checklist

This checklist is a gate, not evidence that a release already exists.

## Source and governance

- [ ] Release commit is clean, reviewed, and synchronized with the protected default branch.
- [ ] Hosted CI completed successfully on the exact release commit.
- [ ] Security workflow completed successfully on the exact release commit.
- [ ] Version is aligned across `pubspec.yaml`, Android, Windows, Web metadata, and Apple bundles.
- [ ] Signed Git tag and release notes identify the release commit.

## Quality gates

- [ ] Formatting, analyzer, full tests, and `git diff --check` pass.
- [ ] Linux, Web, Android, Windows, macOS, and iOS gates have current evidence or an explicitly approved scope exclusion.
- [ ] Android runtime is checked on supported API levels and at least one physical ARM device.
- [ ] Desktop and Web critical user workflows complete without credentials embedded in test artifacts.
- [ ] Accessibility, localization, startup, memory, and performance budgets are recorded.

## Supply chain and compliance

- [ ] Dependency lockfile is unchanged after resolution.
- [ ] Dependency advisory review is complete; EOL dependencies are removed or formally accepted.
- [ ] `build/release-metadata/sbom.cdx.json` is generated and retained.
- [ ] `build/release-metadata/THIRD_PARTY_NOTICES.txt` is generated and shipped where required.
- [ ] Project license and distribution rights are approved.
- [ ] Secret, dependency, and code-scanning controls are enabled and green.

## Packaging and signing

- [ ] Android AAB uses the production upload key, not `Android Debug`.
- [ ] Windows executables/installers have a valid Authenticode signature.
- [ ] macOS app is signed and notarized; iOS archive uses the intended distribution profile.
- [ ] Linux package format and dependencies are tested on supported distributions.
- [ ] Web metadata, HTTPS hosting, security headers, SPA routing, and cache policy are production-ready.
- [ ] Install, upgrade, downgrade refusal, uninstall, and rollback are tested.

## Operations

- [ ] Release artifacts and checksums are retained outside the build machine.
- [ ] Crash/error reporting and privacy-safe diagnostics are verified in production configuration.
- [ ] Backup restore and release rollback drills are complete with recorded RPO/RTO.
- [ ] Incident owner and private security-reporting channel are active.
- [ ] Deployment approval and rollback authority are explicit.

## Final decision

- [ ] Product authority approved the release scope and version.
- [ ] Security and engineering blockers are closed or explicitly accepted in writing.
- [ ] Release verdict records `GO` or `NO-GO`, exact commit SHA, artifacts, signatures, and hosted run IDs.