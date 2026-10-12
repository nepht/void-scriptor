# Signed Windows bundle handoff

The `Release Train` workflow in `.github/workflows/release-train.yml` is the
single signing authority for Windows candidates. It uses the existing
`WINDOWS_CODESIGN_PFX_BASE64`, `WINDOWS_CODESIGN_PFX_PASSWORD`, and
`WINDOWS_CODESIGN_SUBJECT` repository secrets, then produces:

- a signed Windows bundle ZIP;
- `windows-signed-rc-manifest.json` for the signed executable;
- `windows-signed-r2-handoff.json` with the source revision, release label,
  R2 object key, ZIP SHA-256, size, and signing status.

R2 publication is deliberately fail-closed. Add these two repository secrets
to `nepht/void-scriptor` before publishing a release candidate:

- `CLOUDFLARE_ACCOUNT_ID` — the Cloudflare account identifier;
- `CLOUDFLARE_R2_UPLOAD_TOKEN` — a Cloudflare API token limited to object write
  access for the `voidscriptor-downloads` bucket.

The token is used only by the Windows release job. It is not copied to the
website repository and it never has access to the signing certificate.

For a tag push matching `v1.2.0-rc.*`, the workflow publishes the bundle under
`releases/windows/<tag>/VoidScriptor-<tag>-windows-x64-signed.zip`. Manual runs
must set `publish_r2=true` and use a release-candidate ref such as
`v1.2.0-rc.3`; a branch such as `master` is rejected for R2 publication.

The website worker accepts only this exact versioned ZIP shape. The current
`.exe` download remains unchanged until a successful signed handoff has been
verified and deliberately promoted to the public release surface.
