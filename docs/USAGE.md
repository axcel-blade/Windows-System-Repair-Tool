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

Use menu option **15** (full recommended sequence):

1. Create a system restore point  
2. DISM RestoreHealth  
3. SFC `/scannow`  
4. DISM StartComponentCleanup  

If DISM returns `0x800F0915`, use option **5** with a matching Windows ISO or `install.wim`.

Then review option **16** (summary) or exit (summary is shown automatically).

Blank desktop/taskbar icons: try option **14** (rebuild icon cache).

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
- CHKDSK `/f` (option 9) and network reset (option 11) may require a reboot you perform yourself.
- Only run on systems you are authorized to administer.
