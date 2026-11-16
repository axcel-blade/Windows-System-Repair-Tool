# Troubleshooting

## UAC prompt never appears / script closes immediately

- Confirm you launched `RepairWindows.bat` or an elevated PowerShell session.
- Corporate policy may block elevation — ask an admin or run from an already-elevated terminal.

## PowerShell execution policy errors

The bat launcher uses `-ExecutionPolicy Bypass` for this script only. If you run the `.ps1` yourself and see a policy error:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\RepairWindows.ps1
```

## Restore point failed (`WARN`)

System Restore may be disabled, or Windows may rate-limit restore points.

- Enable System Protection for the system drive in System Properties.
- Continue with repairs if you accept the risk, or create a restore point manually first.

## DISM RestoreHealth fails

- Check internet connectivity (Windows Update source).
- Free disk space on the system drive.
- Review `%windir%\Logs\DISM\dism.log` and the tool session log under `%TEMP%\WindowsRepairTool\`.

### Error `0x800F0915` (repair content could not be found)

Windows Update did not supply repair files. This is a servicing/source problem, not proof that every system file is broken (SFC may still report no integrity violations).

1. Confirm Windows Update works and you are online.
2. In the repair tool, choose option **5** and point at:
   - a matching Windows ISO, or
   - `sources\install.wim` / `install.esd` from install media
3. Re-run SFC (option **7**) after a successful Source repair.
4. Optional: create a temporary local account (`WinTest`) to see if icons/startup issues are profile-specific — do not delete your main account.

## Blank or missing icons

- Restart Explorer (Task Manager → Windows Explorer → Restart), then use menu option **14** to rebuild the icon cache.
- If a new local test account looks fine, the issue is more likely the user profile than the Windows image.

## SFC could not repair all files

- Re-run DISM RestoreHealth (option **4**, or **5** with Source if Update fails), then SFC again.
- If files remain unrepaired, offline repair from Windows installation media may still be required.

## CHKDSK `/f` scheduled but nothing happened

A reboot is required before the scheduled check runs. Reboot when convenient; the tool does not reboot for you.

## Network issues after option 10

Reboot once after Winsock / IP reset. If problems persist, check VPN / third-party firewall software.

## Store re-register reports failures

Some packages lack a usable `AppxManifest.xml` or are provisioned oddly. Partial `WARN` results are common; focus on whether the Store / apps you care about work afterward.

## Still stuck?

See [SUPPORT.md](../SUPPORT.md) for how to open an issue with the right details.
