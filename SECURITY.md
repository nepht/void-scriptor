# Security Policy

## Supported versions

Void Scriptor has not published a production release. Security fixes currently target the latest maintained `master` revision only.

## Report a vulnerability

Do not open a public issue for a suspected vulnerability or exposed credential.

Use the repository's private **Security → Advisories → Report a vulnerability** flow. Include:

- affected revision or artifact version;
- reproduction steps and expected impact;
- affected platform;
- logs or screenshots with credentials and personal data removed;
- whether the issue is already being exploited.

If private vulnerability reporting is unavailable, contact the repository owner through an existing private channel and ask for a private reporting path. Do not paste exploit details or secrets into public discussions.

## Handling credentials

- Never commit API keys, passwords, tokens, certificates, signing keys, or connection strings.
- Replace values in reports with `[REDACTED]`.
- Revoke and rotate any credential believed to have entered Git history; deleting the current file is not sufficient.
- Release signing material must remain outside the repository and CI logs.

## Security gates

Pull requests are expected to pass the repository's CI and Security workflows. Current automated coverage includes static analysis, tests, build gates, release-metadata generation, and Gitleaks history scanning. These controls do not replace manual review or platform store validation.