# Windows OS Error Check & Repair via Command Line

This guide explains how to check and fix system errors on Windows using the command line tools. We'll cover the necessary commands and steps to identify and resolve common issues.

## Project docs

| Doc | Purpose |
|-----|---------|
| [docs/](docs/) | Usage, troubleshooting, Git Flow |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute (`main` / `develop` / `feature/*` / `release/*` / `hotfix/*`) |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SUPPORT.md](SUPPORT.md) | How to get help |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [LICENSE](LICENSE) | MIT License |

## 1. System File Checker (SFC)

### Steps

1. Open Command Prompt as Administrator: Press Windows + X → select Command Prompt (Admin) or Windows Terminal (Admin).
2. Run the following.

```
sfc /scannow
```

3. Wait until the scan completes. Do not close the window during the process.

## 2. Deployment Imaging Service and Management Tool (DISM)

The DISM tool repairs the Windows system image and component store.

### Commands to Run in Sequence

```
DISM /Online /Cleanup-Image /CheckHealth
```

```
DISM /Online /Cleanup-Image /ScanHealth
```

```
DISM /Online /Cleanup-Image /RestoreHealth
```

### Description

- `/CheckHealth` – Quickly checks for known corruption.
- `/ScanHealth` – Performs a deeper scan for problems.
- `/RestoreHealth` – Repairs the image using Windows Update or a specified source.

### Recommended Full Repair Sequence

1. Open terminal as Administrator.
2. Run the following

```
DISM /Online /Cleanup-Image /RestoreHealth
```

3. Then run

```
sfc /scannow
```

## Windows System Repair Tool

Instead of running each command manually, use the included repair tool. `RepairWindows.bat` elevates and launches `RepairWindows.ps1`, a menu-driven PowerShell suite covering the common Windows repair steps.

### Features

- **Auto-elevates to Administrator** — double-clicking the bat file triggers a UAC prompt.
- **Interactive menu** — run a single repair step or the full recommended sequence.
- **Session summary** — each step records `[PASS]`, `[WARN]`, `[DONE]`, or `[FAIL]`.
- **Logging** — writes a timestamped log under `%TEMP%\WindowsRepairTool\`.
- **Safe defaults** — never forces a reboot; CHKDSK `/f` and network reset only warn that a reboot may be needed.

### Menu options

| Option | Action |
|--------|--------|
| 1 | Create system restore point |
| 2 | DISM CheckHealth |
| 3 | DISM ScanHealth |
| 4 | DISM RestoreHealth |
| 5 | DISM StartComponentCleanup |
| 6 | SFC /scannow |
| 7 | CHKDSK online scan (`/scan`) |
| 8 | Schedule CHKDSK `/f` (reboot required later) |
| 9 | Reset Windows Update components |
| 10 | Network reset (flush DNS, Winsock, IP) |
| 11 | Re-register Microsoft Store apps |
| 12 | Clear user and Windows temp folders |
| 13 | Full recommended sequence (restore point → DISM RestoreHealth → SFC → component cleanup) |
| 14 | Show session summary |
| 0 | Exit (shows summary first) |

### How to Run

1. Double-click `RepairWindows.bat` (or run `RepairWindows.ps1` in an elevated PowerShell).
2. Click **Yes** on the UAC prompt.
3. Choose a menu option. Option **13** runs the recommended core sequence.
4. Review on-screen output and option **14** / exit summary when finished.
5. Optionally open the log path printed in the menu footer.

### Report Status Codes

| Status | Meaning |
|--------|---------|
| `[PASS]` | Step completed successfully with no issues |
| `[WARN]` | Issues were detected or the step partially completed |
| `[DONE]` | Step finished with an expected follow-up (e.g. SFC repaired files, CHKDSK scheduled) |
| `[FAIL]` | Step failed — check the error code and log |

### Notes on individual repairs

- **Windows Update reset** stops WU-related services, renames `SoftwareDistribution` and `catroot2`, then restarts the services.
- **Network reset** may require a reboot before networking fully recovers.
- **Store re-register** skips packages whose `AppxManifest.xml` is missing and continues on per-package errors.
- **Temp cleanup** ignores files that are locked or in use.

## Notes

- These tools are built into Windows and safe to use when run as documented.
- DISM RestoreHealth typically needs an internet connection if using Windows Update as the repair source.
- You can use these commands to help with issues like:
  - Missing or corrupt system files
  - Random crashes or BSODs
  - Windows Update problems
  - Broken Microsoft Store apps
  - DNS / Winsock networking glitches
