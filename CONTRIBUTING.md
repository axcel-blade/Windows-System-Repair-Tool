# Contributing

Thanks for helping improve **Windows System Repair Tool**.

## Code of conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## How we work (Git Flow)

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready releases |
| `develop` | Integration branch for the next release |
| `feature/*` | New features (branch from `develop`) |
| `release/*` | Release preparation (branch from `develop`) |
| `hotfix/*` | Urgent production fixes (branch from `main`) |

### Feature workflow

1. Open an issue (or discussion) describing the change when it is non-trivial.
2. Branch from the latest `develop`:

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/short-description
   ```

3. Make focused commits. Keep scripts safe: no forced reboots, clear admin elevation, and preserve summary status codes (`PASS` / `WARN` / `DONE` / `FAIL`).
4. Open a pull request **into `develop`** using the PR template.
5. Address review feedback. Do not force-push to shared branches.

### Release and hotfix

- **Release:** `release/x.y.z` from `develop` → PR to `main` and back-merge to `develop`. Update [CHANGELOG.md](CHANGELOG.md).
- **Hotfix:** `hotfix/x.y.z` from `main` → PR to `main` and merge back into `develop`.

## What to contribute

- Repair steps that use built-in Windows tools
- Safer defaults, clearer logging, and better docs
- Bug fixes for elevation, exit codes, or menu behavior

Avoid destructive actions that delete user data without a clear warning, or anything that requires offline WinRE unless documented as advanced/optional.

## Local checks

CI runs the **Build** job on pushes and pull requests to `main` and `develop` (see `.github/workflows/ci.yml`).

- Parse/syntax-check PowerShell before submitting:

  ```powershell
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path .\RepairWindows.ps1).Path, [ref]$null, [ref]$errors)
  if ($errors) { $errors; throw 'Parse failed' } else { 'PARSE_OK' }
  ```

- Keep Markdown filenames uppercase (enforced in CI).
- Run the tool only on machines you own or administer. Prefer dry review of new steps before live runs.

## Docs

- User-facing docs live under [`docs/`](docs/).
- Keep [README.md](README.md) accurate for how to run the tool.
- Record user-visible changes in [CHANGELOG.md](CHANGELOG.md).

## Security

Do not open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

## Getting help

See [SUPPORT.md](SUPPORT.md).
