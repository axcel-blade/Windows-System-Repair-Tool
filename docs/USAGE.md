# Usage

## Requirements

- Windows 10 or Windows 11 (built-in DISM / SFC / CHKDSK)
- Administrator approval at the UAC prompt
- Internet access recommended for DISM RestoreHealth (Windows Update source)

## Quick start

1. Clone or download this repository.
2. Double-click `RepairWindows.bat`.
3. Accept the UAC prompt.
4. Choose a menu option in `RepairWindows.ps1`.

You can also run the script directly in an elevated PowerShell:

```powershell
Set-Location path\to\Windows-System-Repair-Tool
powershell -NoProfile -ExecutionPolicy Bypass -File .\RepairWindows.ps1
```

## Recommended first run

Use menu option **13** (full recommended sequence):

1. Create a system restore point  
2. DISM RestoreHealth  
3. SFC `/scannow`  
4. DISM StartComponentCleanup  

Then review option **14** (summary) or exit (summary is shown automatically).

## Logs

Each session writes:

`%TEMP%\WindowsRepairTool\repair-YYYYMMDD-HHmmss.log`

The menu footer prints the active log path.

## Status codes

| Code | Meaning |
|------|---------|
| `PASS` | Succeeded with no issues reported |
| `WARN` | Partial success or issues detected |
| `DONE` | Finished with an expected follow-up (repairs made / reboot later) |
| `FAIL` | Failed — check console output and the log |

## Safety notes

- The tool never forces a reboot.
- CHKDSK `/f` (option 8) and network reset (option 10) may require a reboot you perform yourself.
- Only run on systems you are authorized to administer.
