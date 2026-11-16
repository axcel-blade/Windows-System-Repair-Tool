# Security Policy

## Supported versions

| Version / branch | Supported |
|------------------|-----------|
| Latest `main` release | Yes |
| `develop` (pre-release) | Best-effort |
| Older tagged releases | No |

## What this project does

This repository ships administrator-level Windows repair scripts (`RepairWindows.bat` / `RepairWindows.ps1`). Treat them like any elevated system utility: review changes before running, and only run them on systems you own or are authorized to administer.

## Reporting a vulnerability

**Do not** open a public issue or discussion for security problems.

Please report privately using one of these methods:

1. **GitHub Security Advisories** — Repository → Security → Advisories → New draft advisory (preferred when available).
2. **Email the maintainer** listed on the [GitHub profile for axcel-blade](https://github.com/axcel-blade) if advisories are unavailable.

Include:

- Description of the issue and impact
- Steps to reproduce
- Affected file(s) and commit/tag if known
- Whether you have a suggested fix

## Response expectations

- Acknowledgement within **7 days** when possible
- Status update within **14 days** for confirmed issues
- Coordinated disclosure after a fix is available on `main`

## Safe use reminders

- Scripts request elevation via UAC; decline if you did not intend to run them.
- The tool does not force reboots; some steps (CHKDSK `/f`, network reset) may require a reboot you choose to perform later.
- Do not embed third-party downloaders or obfuscated payloads in contributions.
