# 🧰 Windows OS Error Check & Repair via Command Line
This guide explains how to check and fix system errors on Windows using the command line tools. We'll cover the necessary commands and steps to identify and resolve common issues.

## 🛠 1. System File Checker (SFC)
### 🔧 Steps

1. Open Command Prompt as Administrator: Press Windows + X → select Command Prompt (Admin) or Windows Terminal (Admin).
2. Run the following.
```
sfc /scannow
```

3. Wait until the scan completes. Do not close the window during the process.

## 🛠 2. Deployment Imaging Service and Management Tool (DISM)
The DISM tool repairs the Windows system image and component store.
### ✅ Commands to Run in Sequence
```
DISM /Online /Cleanup-Image /CheckHealth
```
```
DISM /Online /Cleanup-Image /ScanHealth
```
```
DISM /Online /Cleanup-Image /RestoreHealth
```

### 🔍 Description
- /CheckHealth – Quickly checks for known corruption.

- /ScanHealth – Performs a deeper scan for problems.

- /RestoreHealth – Repairs the image using Windows Update or a specified source.

### ✅ Recommended Full Repair Sequence
1. Open terminal as Administrator.
2. Run the following
```
DISM /Online /Cleanup-Image /RestoreHealth
```
3. Then run
```
sfc /scannow
```

## ⚙️ Automate with a Batch File
Instead of running each command manually, you can use the included `RepairWindows.bat` to automate the full repair sequence.

### ✨ Features
- **Auto-elevates to Administrator** — double-clicking the file will automatically trigger a UAC prompt. No need to right-click and select "Run as Administrator".
- **Runs all 4 repair steps in sequence** — DISM CheckHealth, ScanHealth, RestoreHealth, then SFC.
- **Summary report** — after all steps complete, a formatted report is shown in the terminal with a `[PASS]`, `[WARN]`, `[DONE]`, or `[FAIL]` status for each step.
- **Stays open until dismissed** — the window remains open after the report so you can review the results. Press **Enter** to close.

### ▶️ How to Run
1. Double-click `RepairWindows.bat`.
2. Click **Yes** on the UAC (User Account Control) prompt to allow administrator access.
3. Wait for all steps to complete — this may take several minutes.
4. Review the **Repair Summary Report** displayed at the end.
5. Press **Enter** to close the window.

### 📋 Report Status Codes
| Status | Meaning |
|--------|---------|
| `[PASS]` | Step completed successfully with no issues |
| `[WARN]` | Issues were detected (review DISM output above) |
| `[DONE]` | SFC found and repaired integrity violations |
| `[FAIL]` | Step failed — check the error code and logs above |

## ℹ️ Notes
- These tools are built into Windows and safe to use.

- Requires an internet connection for DISM if using Windows Update as the repair source.

- You can use these commands to fix issues like:
    - Missing/corrupt system files
    - Random crashes or BSODs
    - Windows Update problems