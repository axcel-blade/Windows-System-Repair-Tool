# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
where version tags are used.

## [Unreleased]

### Added

- Menu-driven PowerShell repair suite (`RepairWindows.ps1`) with:
  - System restore point creation
  - DISM CheckHealth / ScanHealth / RestoreHealth / StartComponentCleanup
  - SFC `/scannow`
  - CHKDSK online scan and scheduled `/f`
  - Windows Update component reset
  - Network reset (DNS / Winsock / IP)
  - Microsoft Store app re-registration
  - Temp folder cleanup
  - Full recommended sequence and session summary
  - Session logs under `%TEMP%\WindowsRepairTool\`
- Community and project docs: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `CHANGELOG.md`, `docs/`, and GitHub issue/PR/discussion templates
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) — required-file check, uppercase Markdown filenames, PowerShell parse, batch launcher validation

### Changed

- `RepairWindows.bat` is now a thin elevated launcher for `RepairWindows.ps1`
- README documents the interactive menu and status codes

## [0.1.0] - 2025-11-11

### Added

- Initial DISM + SFC automated sequence in `RepairWindows.bat`
- README with manual SFC/DISM instructions and report status codes
- MIT License
