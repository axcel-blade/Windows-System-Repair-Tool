# Support

## How to get help

1. Read [README.md](README.md) and the guides under [`docs/`](docs/).
2. Search [existing issues](https://github.com/axcel-blade/Windows-System-Repair-Tool/issues) and discussions.
3. Open a **Discussion** for questions, or an **Issue** for bugs and feature requests (use the templates).

## What to include

When asking for help, include:

- Windows edition and version (`winver`)
- Whether you ran `RepairWindows.bat` or `RepairWindows.ps1`
- Menu option(s) you selected
- Summary status lines (`[PASS]` / `[WARN]` / `[DONE]` / `[FAIL]`)
- Relevant excerpts from `%TEMP%\WindowsRepairTool\repair-*.log` (redact machine-specific paths if needed)

## Scope

Maintainers can help with:

- Using the repair menu and interpreting status codes
- Bugs in elevation, logging, or documented repair steps
- Documentation gaps

Maintainers generally cannot:

- Remotely troubleshoot arbitrary hardware failures
- Guarantee that DISM/SFC/CHKDSK will fix every system
- Provide paid support or data-recovery services

## Security issues

See [SECURITY.md](SECURITY.md) — do not post vulnerability details publicly.
