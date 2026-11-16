# Git Flow

This repository uses classic Git Flow.

```text
main          production releases
  ^
  |  merge release/* or hotfix/*
  |
develop       integration / next release
  ^
  |  merge feature/*
  |
feature/*     new work
release/*     version cut from develop
hotfix/*      urgent fix from main
```

## Branch naming

| Pattern | Example | Base | Merge target |
|---------|---------|------|--------------|
| `feature/*` | `feature/windows-repair-suite` | `develop` | `develop` |
| `release/*` | `release/1.0.0` | `develop` | `main` + back to `develop` |
| `hotfix/*` | `hotfix/1.0.1` | `main` | `main` + back to `develop` |

## Rules of thumb

- Do not commit directly to `main` or `develop` when branch protection requires PRs.
- Keep `feature/*` branches short-lived and focused.
- Update [CHANGELOG.md](../CHANGELOG.md) on release and for user-visible unreleased work.
- Tag releases on `main` (for example `v1.0.0`) when cutting a release.

See also [CONTRIBUTING.md](../CONTRIBUTING.md).
