#Requires -Version 5.1
<#
.SYNOPSIS
    Windows System Repair Tool — menu-driven DISM, SFC, CHKDSK, Update reset, network, Store, and temp cleanup.
.NOTES
    Run as Administrator (auto-elevates). Double-click RepairWindows.bat or:
    powershell -ExecutionPolicy Bypass -File .\RepairWindows.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ── Globals ──────────────────────────────────────────────────────────────────
$script:Results = [System.Collections.Generic.List[object]]::new()
$script:LogPath = $null
$script:SessionStart = Get-Date

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    if (Test-IsAdministrator) { return }
    Write-Host 'Requesting administrator privileges...' -ForegroundColor Yellow
    $psi = @{
        FilePath     = 'powershell.exe'
        Verb         = 'RunAs'
        ArgumentList = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$PSCommandPath`""
        )
    }
    try {
        Start-Process @psi | Out-Null
    }
    catch {
        Write-Host 'Elevation cancelled or failed. Exiting.' -ForegroundColor Red
    }
    exit
}

function Initialize-Log {
    $dir = Join-Path $env:TEMP 'WindowsRepairTool'
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:LogPath = Join-Path $dir "repair-$stamp.log"
    "Windows System Repair Tool log — started $($script:SessionStart.ToString('o'))" |
        Out-File -FilePath $script:LogPath -Encoding utf8
}

function Write-Log {
    param([string]$Message)
    if ($script:LogPath) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Message" |
            Out-File -FilePath $script:LogPath -Append -Encoding utf8
    }
}

function Write-StepHeader {
    param([string]$Title)
    Write-Host ''
    Write-Host ('=' * 50) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('=' * 50) -ForegroundColor Cyan
    Write-Log "BEGIN: $Title"
}

function Add-Result {
    param(
        [string]$Step,
        [ValidateSet('PASS', 'WARN', 'DONE', 'FAIL', 'SKIP')]
        [string]$Status,
        [string]$Detail
    )
    $script:Results.Add([pscustomobject]@{
            Step   = $Step
            Status = $Status
            Detail = $Detail
        })
    Write-Log "RESULT [$Status] $Step — $Detail"
}

function Invoke-External {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    $argString = ($ArgumentList | ForEach-Object {
            if ($_ -match '\s') { "`"$_`"" } else { $_ }
        }) -join ' '
    Write-Log "EXEC: $FilePath $argString"

    # Stream tool output to the console/log only. Do NOT emit it to the
    # success pipeline — otherwise callers capture progress text as $code
    # and status checks / summary details break (SFC/DISM false FAILs).
    & $FilePath @ArgumentList 2>&1 | ForEach-Object {
        $line = "$_"
        Write-Host $line
        Write-Log $line
    }

    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) { $exitCode = 0 }
    return [int]$exitCode
}

function Get-ExitCodeHex {
    param([int]$Code)
    $unsigned = [BitConverter]::ToUInt32([BitConverter]::GetBytes($Code), 0)
    return ('0x{0:X8}' -f $unsigned)
}

function Format-ExitCode {
    param([int]$Code)
    if ($Code -lt 0) {
        return ('{0} ({1})' -f $Code, (Get-ExitCodeHex $Code))
    }
    return "$Code"
}

function Show-Menu {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host '     Windows System Repair Tool' -ForegroundColor Green
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host ''
    Write-Host '  1) Create system restore point'
    Write-Host '  2) DISM CheckHealth'
    Write-Host '  3) DISM ScanHealth'
    Write-Host '  4) DISM RestoreHealth (Windows Update)'
    Write-Host '  5) DISM RestoreHealth with Source (ISO/WIM/ESD)'
    Write-Host '  6) DISM StartComponentCleanup'
    Write-Host '  7) SFC /scannow'
    Write-Host '  8) CHKDSK (online scan)'
    Write-Host '  9) CHKDSK schedule /f (reboot required)'
    Write-Host ' 10) Reset Windows Update components'
    Write-Host ' 11) Network reset (DNS / Winsock / IP)'
    Write-Host ' 12) Re-register Microsoft Store apps'
    Write-Host ' 13) Clear temp folders'
    Write-Host ' 14) Rebuild icon cache'
    Write-Host ' 15) Run full recommended sequence'
    Write-Host '     (restore point -> DISM RestoreHealth -> SFC -> component cleanup)'
    Write-Host ' 16) Show session summary'
    Write-Host '  0) Exit'
    Write-Host ''
    if ($script:LogPath) {
        Write-Host "  Log: $($script:LogPath)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

# ── Repair actions ────────────────────────────────────────────────────────────

function Invoke-CreateRestorePoint {
    Write-StepHeader 'Create system restore point'
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description 'Windows System Repair Tool' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host 'Restore point created successfully.' -ForegroundColor Green
        Add-Result -Step 'Restore point' -Status 'PASS' -Detail 'Checkpoint created'
    }
    catch {
        $msg = $_.Exception.Message
        Write-Host "Could not create restore point: $msg" -ForegroundColor Yellow
        # Fallback via WMI SystemRestore class method
        try {
            $result = (Invoke-CimMethod -Namespace 'root/default' -ClassName 'SystemRestore' -MethodName 'CreateRestorePoint' -Arguments @{
                    Description      = 'Windows System Repair Tool'
                    RestorePointType = 12
                    EventType        = 100
                } -ErrorAction Stop).ReturnValue
            if ($result -eq 0) {
                Write-Host 'Restore point created via WMI fallback.' -ForegroundColor Green
                Add-Result -Step 'Restore point' -Status 'PASS' -Detail 'Created via WMI'
            }
            else {
                Write-Host "WMI CreateRestorePoint returned $result" -ForegroundColor Yellow
                Add-Result -Step 'Restore point' -Status 'WARN' -Detail "Unavailable or failed (code $result). System Restore may be disabled."
            }
        }
        catch {
            Add-Result -Step 'Restore point' -Status 'WARN' -Detail "Skipped: $($_.Exception.Message)"
        }
    }
}

function Invoke-DismCheckHealth {
    Write-StepHeader 'DISM CheckHealth'
    $code = Invoke-External -FilePath 'DISM.exe' -ArgumentList @('/Online', '/Cleanup-Image', '/CheckHealth')
    if ($code -eq 0) {
        Add-Result -Step 'DISM CheckHealth' -Status 'PASS' -Detail 'No issues detected'
    }
    else {
        Add-Result -Step 'DISM CheckHealth' -Status 'FAIL' -Detail ("Error code " + (Format-ExitCode $code))
    }
}

function Invoke-DismScanHealth {
    Write-StepHeader 'DISM ScanHealth'
    $code = Invoke-External -FilePath 'DISM.exe' -ArgumentList @('/Online', '/Cleanup-Image', '/ScanHealth')
    if ($code -eq 0) {
        Add-Result -Step 'DISM ScanHealth' -Status 'PASS' -Detail 'Component store is healthy'
    }
    else {
        Add-Result -Step 'DISM ScanHealth' -Status 'WARN' -Detail ("Issues found (code " + (Format-ExitCode $code) + ")")
    }
}

function Resolve-DismSourcePath {
    param([string]$InputPath)

    if ([string]::IsNullOrWhiteSpace($InputPath)) { return $null }

    $path = $InputPath.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "Path not found: $path" -ForegroundColor Red
        return $null
    }

    $item = Get-Item -LiteralPath $path
    if ($item.PSIsContainer) {
        foreach ($name in @('install.wim', 'install.esd')) {
            $candidate = Join-Path $item.FullName $name
            if (Test-Path -LiteralPath $candidate) { return $candidate }
            $candidate = Join-Path $item.FullName (Join-Path 'sources' $name)
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
        Write-Host 'Folder has no install.wim / install.esd (checked root and sources\).' -ForegroundColor Red
        return $null
    }

    $ext = $item.Extension.ToLowerInvariant()
    if ($ext -in '.wim', '.esd') {
        return $item.FullName
    }

    if ($ext -eq '.iso') {
        Write-Host "Mounting ISO: $($item.FullName)" -ForegroundColor Yellow
        try {
            $mount = Mount-DiskImage -ImagePath $item.FullName -PassThru -ErrorAction Stop
            $vol = $mount | Get-Volume -ErrorAction Stop
            $driveRoot = "$($vol.DriveLetter):\"
            foreach ($name in @('install.wim', 'install.esd')) {
                $candidate = Join-Path $driveRoot (Join-Path 'sources' $name)
                if (Test-Path -LiteralPath $candidate) {
                    return [pscustomobject]@{
                        SourcePath = $candidate
                        IsoPath    = $item.FullName
                    }
                }
            }
            Dismount-DiskImage -ImagePath $item.FullName -ErrorAction SilentlyContinue | Out-Null
            Write-Host 'ISO mounted but sources\install.wim / install.esd was not found.' -ForegroundColor Red
            return $null
        }
        catch {
            Write-Host "Could not mount ISO: $($_.Exception.Message)" -ForegroundColor Red
            return $null
        }
    }

    Write-Host 'Provide a .wim, .esd, .iso, or a folder that contains sources\install.wim.' -ForegroundColor Red
    return $null
}

function Complete-DismRestoreHealthResult {
    param(
        [int]$Code,
        [string]$StepName = 'DISM RestoreHealth'
    )
    if ($Code -eq 0) {
        Add-Result -Step $StepName -Status 'PASS' -Detail 'Image repaired successfully'
    }
    elseif ((Get-ExitCodeHex $Code) -eq '0x800F0915') {
        Add-Result -Step $StepName -Status 'FAIL' -Detail '0x800F0915 — repair content not found (try menu option 5 with an ISO/WIM source)'
        Write-Host ''
        Write-Host 'Tip: use option 5 (RestoreHealth with Source) and point at a matching Windows ISO or install.wim.' -ForegroundColor Yellow
    }
    else {
        Add-Result -Step $StepName -Status 'FAIL' -Detail ("Repair failed (code " + (Format-ExitCode $Code) + ")")
    }
}

function Invoke-DismRestoreHealth {
    Write-StepHeader 'DISM RestoreHealth'
    Write-Host 'This may take several minutes and needs internet if using Windows Update as source...' -ForegroundColor Yellow
    $code = Invoke-External -FilePath 'DISM.exe' -ArgumentList @('/Online', '/Cleanup-Image', '/RestoreHealth')
    Complete-DismRestoreHealthResult -Code $code -StepName 'DISM RestoreHealth'
}

function Invoke-DismRestoreHealthFromSource {
    Write-StepHeader 'DISM RestoreHealth with Source'
    Write-Host 'Use a Windows ISO, install.wim/install.esd, or a mounted install media folder.' -ForegroundColor Yellow
    Write-Host 'The image build should match this PC as closely as possible.' -ForegroundColor Yellow
    $inputPath = Read-Host 'Path to ISO / WIM / ESD / sources folder'
    $resolved = Resolve-DismSourcePath -InputPath $inputPath
    if (-not $resolved) {
        Add-Result -Step 'DISM RestoreHealth (Source)' -Status 'FAIL' -Detail 'No valid source path provided'
        return
    }

    $sourcePath = $resolved
    $isoPath = $null
    if ($resolved -is [pscustomobject] -and $resolved.PSObject.Properties.Name -contains 'SourcePath') {
        $sourcePath = $resolved.SourcePath
        $isoPath = $resolved.IsoPath
    }

    Write-Host "Using source: $sourcePath" -ForegroundColor Cyan
    Write-Log "DISM source: $sourcePath"
    $args = @(
        '/Online'
        '/Cleanup-Image'
        '/RestoreHealth'
        "/Source:$sourcePath"
        '/LimitAccess'
    )
    try {
        $code = Invoke-External -FilePath 'DISM.exe' -ArgumentList $args
        Complete-DismRestoreHealthResult -Code $code -StepName 'DISM RestoreHealth (Source)'
    }
    finally {
        if ($isoPath) {
            Write-Host "Dismounting ISO: $isoPath" -ForegroundColor DarkGray
            Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Invoke-DismComponentCleanup {
    Write-StepHeader 'DISM StartComponentCleanup'
    $code = Invoke-External -FilePath 'DISM.exe' -ArgumentList @('/Online', '/Cleanup-Image', '/StartComponentCleanup')
    if ($code -eq 0) {
        Add-Result -Step 'DISM ComponentCleanup' -Status 'PASS' -Detail 'Component store cleaned'
    }
    else {
        Add-Result -Step 'DISM ComponentCleanup' -Status 'FAIL' -Detail ("Failed (code " + (Format-ExitCode $code) + ")")
    }
}

function Invoke-SfcScan {
    Write-StepHeader 'SFC /scannow'
    $code = Invoke-External -FilePath 'sfc.exe' -ArgumentList @('/scannow')
    if ($code -eq 0) {
        Add-Result -Step 'SFC /scannow' -Status 'PASS' -Detail 'No integrity violations found'
    }
    elseif ($code -eq 1) {
        # Some Windows builds return 1 when repairs were made; treat carefully
        Add-Result -Step 'SFC /scannow' -Status 'DONE' -Detail 'Completed with repairs or warnings (code 1)'
    }
    elseif ($code -eq 2) {
        Add-Result -Step 'SFC /scannow' -Status 'DONE' -Detail 'Violations found and repaired'
    }
    else {
        Add-Result -Step 'SFC /scannow' -Status 'FAIL' -Detail ("Could not repair all files (code " + (Format-ExitCode $code) + ")")
    }
}

function Invoke-ChkdskScan {
    Write-StepHeader 'CHKDSK online scan'
    $drive = $env:SystemDrive
    if (-not $drive) { $drive = 'C:' }
    $code = Invoke-External -FilePath 'chkdsk.exe' -ArgumentList @($drive, '/scan')
    if ($code -eq 0) {
        Add-Result -Step 'CHKDSK /scan' -Status 'PASS' -Detail "No problems found on $drive"
    }
    else {
        Add-Result -Step 'CHKDSK /scan' -Status 'WARN' -Detail ("Completed with code " + (Format-ExitCode $code) + " — review output above")
    }
}

function Invoke-ChkdskScheduleFix {
    Write-StepHeader 'CHKDSK schedule /f'
    Write-Host 'This schedules a full disk check on the next reboot. No reboot will be forced.' -ForegroundColor Yellow
    $drive = $env:SystemDrive
    if (-not $drive) { $drive = 'C:' }
    # echo Y to confirm volume-in-use prompt
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = "/c echo Y| chkdsk $drive /f"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    if ($stdout) { Write-Host $stdout }
    if ($stderr) { Write-Host $stderr -ForegroundColor Yellow }
    Write-Log "CHKDSK /f stdout: $stdout"
    if ($proc.ExitCode -eq 0) {
        Write-Host 'CHKDSK /f has been scheduled. Reboot when ready to run the check.' -ForegroundColor Green
        Add-Result -Step 'CHKDSK /f schedule' -Status 'DONE' -Detail "Scheduled for $drive — reboot required"
    }
    else {
        Add-Result -Step 'CHKDSK /f schedule' -Status 'FAIL' -Detail "Failed (code $($proc.ExitCode))"
    }
}

function Invoke-WindowsUpdateReset {
    Write-StepHeader 'Reset Windows Update components'
    $services = @('wuauserv', 'cryptSvc', 'bits', 'msiserver')
    foreach ($svc in $services) {
        Write-Host "Stopping $svc..."
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Log "Stopped service $svc (attempted)"
    }

    $sd = Join-Path $env:SystemRoot 'SoftwareDistribution'
    $cr = Join-Path $env:SystemRoot 'System32\catroot2'
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    $ok = $true

    foreach ($pair in @(
            @{ Path = $sd; Name = 'SoftwareDistribution' }
            @{ Path = $cr; Name = 'catroot2' }
        )) {
        if (Test-Path $pair.Path) {
            $dest = "$($pair.Path).bak-$stamp"
            try {
                Rename-Item -Path $pair.Path -NewName (Split-Path $dest -Leaf) -ErrorAction Stop
                Write-Host "Renamed $($pair.Name) -> $(Split-Path $dest -Leaf)" -ForegroundColor Green
                Write-Log "Renamed $($pair.Path) to $dest"
            }
            catch {
                Write-Host "Could not rename $($pair.Name): $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Log "Rename failed $($pair.Name): $($_.Exception.Message)"
                $ok = $false
            }
        }
    }

    foreach ($svc in $services) {
        Write-Host "Starting $svc..."
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Log "Started service $svc (attempted)"
    }

    if ($ok) {
        Add-Result -Step 'Windows Update reset' -Status 'PASS' -Detail 'Services cycled; folders renamed'
    }
    else {
        Add-Result -Step 'Windows Update reset' -Status 'WARN' -Detail 'Completed with some rename failures'
    }
}

function Invoke-NetworkReset {
    Write-StepHeader 'Network reset'
    Write-Host 'A reboot may be required after Winsock/IP reset. No reboot will be forced.' -ForegroundColor Yellow

    $flush = Invoke-External -FilePath 'ipconfig.exe' -ArgumentList @('/flushdns')
    $winsock = Invoke-External -FilePath 'netsh.exe' -ArgumentList @('winsock', 'reset')
    $ip = Invoke-External -FilePath 'netsh.exe' -ArgumentList @('int', 'ip', 'reset')

    $codes = @($flush, $winsock, $ip)
    if (($codes | Where-Object { $_ -ne 0 }).Count -eq 0) {
        Add-Result -Step 'Network reset' -Status 'PASS' -Detail 'DNS flushed; Winsock and IP reset — reboot recommended'
    }
    else {
        Add-Result -Step 'Network reset' -Status 'WARN' -Detail "Completed with codes flush=$flush winsock=$winsock ip=$ip — reboot recommended"
    }
}

function Invoke-StoreAppsReregister {
    Write-StepHeader 'Re-register Microsoft Store apps'
    Write-Host 'This can take several minutes...' -ForegroundColor Yellow
    $ok = 0
    $fail = 0
    try {
        $packages = Get-AppxPackage -AllUsers -ErrorAction Stop
    }
    catch {
        # Fall back to current user if AllUsers fails
        Write-Host 'AllUsers query failed; using current-user packages.' -ForegroundColor Yellow
        $packages = Get-AppxPackage -ErrorAction Stop
    }

    foreach ($pkg in $packages) {
        $manifest = Join-Path $pkg.InstallLocation 'AppxManifest.xml'
        if (-not (Test-Path $manifest)) { continue }
        try {
            Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop | Out-Null
            $ok++
        }
        catch {
            $fail++
            Write-Log "Store re-register failed for $($pkg.Name): $($_.Exception.Message)"
        }
    }

    Write-Host "Re-registered $ok package(s); $fail failure(s)." -ForegroundColor Cyan
    if ($fail -eq 0) {
        Add-Result -Step 'Store apps re-register' -Status 'PASS' -Detail "Re-registered $ok package(s)"
    }
    elseif ($ok -gt 0) {
        Add-Result -Step 'Store apps re-register' -Status 'WARN' -Detail "Re-registered $ok; $fail failed"
    }
    else {
        Add-Result -Step 'Store apps re-register' -Status 'FAIL' -Detail 'No packages re-registered'
    }
}

function Invoke-TempCleanup {
    Write-StepHeader 'Clear temp folders'
    $targets = @(
        $env:TEMP
        (Join-Path $env:SystemRoot 'Temp')
    )
    $removed = 0
    $skipped = 0
    foreach ($dir in $targets) {
        if (-not (Test-Path $dir)) { continue }
        Write-Host "Cleaning $dir ..."
        Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                $removed++
            }
            catch {
                $skipped++
            }
        }
    }
    Write-Host "Removed $removed item(s); skipped $skipped locked/in-use item(s)." -ForegroundColor Cyan
    Add-Result -Step 'Temp cleanup' -Status 'PASS' -Detail "Removed $removed; skipped $skipped"
}

function Invoke-IconCacheRebuild {
    Write-StepHeader 'Rebuild icon cache'
    Write-Host 'Stops Explorer briefly, deletes iconcache_*.db, then restarts Explorer. No reboot.' -ForegroundColor Yellow

    $explorerDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Explorer'
    $removed = 0
    $skipped = 0

    try {
        & "$env:SystemRoot\System32\ie4uinit.exe" -show 2>$null | Out-Null
    }
    catch {
        Write-Log "ie4uinit skipped: $($_.Exception.Message)"
    }

    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if (Test-Path -LiteralPath $explorerDir) {
        Get-ChildItem -LiteralPath $explorerDir -Filter 'iconcache_*.db' -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                $removed++
                Write-Log "Removed $($_.FullName)"
            }
            catch {
                $skipped++
                Write-Log "Could not remove $($_.FullName): $($_.Exception.Message)"
            }
        }
        Get-ChildItem -LiteralPath $explorerDir -Filter 'thumbcache_*.db' -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                $removed++
            }
            catch {
                $skipped++
            }
        }
    }

    Start-Process -FilePath explorer.exe | Out-Null
    Write-Host "Removed $removed cache file(s); skipped $skipped. Desktop/taskbar should refresh shortly." -ForegroundColor Cyan
    if ($removed -gt 0 -or $skipped -eq 0) {
        Add-Result -Step 'Icon cache rebuild' -Status 'DONE' -Detail "Removed $removed cache file(s); Explorer restarted"
    }
    else {
        Add-Result -Step 'Icon cache rebuild' -Status 'WARN' -Detail "Explorer restarted; could not delete locked cache files ($skipped)"
    }
}

function Invoke-FullSequence {
    Write-StepHeader 'Full recommended sequence'
    Write-Host 'Running: restore point -> DISM RestoreHealth -> SFC -> component cleanup' -ForegroundColor Yellow
    Invoke-CreateRestorePoint
    Invoke-DismRestoreHealth
    if ($script:Results.Count -gt 0) {
        $lastDism = @($script:Results | Where-Object { $_.Step -eq 'DISM RestoreHealth' } | Select-Object -Last 1)
        if ($lastDism -and $lastDism.Status -eq 'FAIL' -and $lastDism.Detail -like '*0x800F0915*') {
            Write-Host ''
            Write-Host 'DISM failed with 0x800F0915. Optionally retry with a local ISO/WIM source now.' -ForegroundColor Yellow
            $retry = Read-Host 'Run RestoreHealth with Source now? (Y/N)'
            if ($retry -match '^[Yy]') {
                Invoke-DismRestoreHealthFromSource
            }
        }
    }
    Invoke-SfcScan
    Invoke-DismComponentCleanup
    Write-Host ''
    Write-Host 'Full recommended sequence finished.' -ForegroundColor Green
}

function Show-Summary {
    Write-Host ''
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host '         REPAIR SUMMARY REPORT' -ForegroundColor Green
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host ''

    if ($script:Results.Count -eq 0) {
        Write-Host '  No steps have been run in this session yet.' -ForegroundColor Yellow
    }
    else {
        foreach ($r in $script:Results) {
            $color = switch ($r.Status) {
                'PASS' { 'Green' }
                'DONE' { 'Cyan' }
                'WARN' { 'Yellow' }
                'FAIL' { 'Red' }
                default { 'Gray' }
            }
            $line = '  [{0}] {1,-28} : {2}' -f $r.Status, $r.Step, $r.Detail
            Write-Host $line -ForegroundColor $color
        }
    }

    Write-Host ''
    Write-Host '==============================================' -ForegroundColor Green
    if ($script:LogPath) {
        Write-Host "Log file: $($script:LogPath)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

# ── Main ──────────────────────────────────────────────────────────────────────

Request-Elevation
Initialize-Log
Write-Log "Running as $env:USERNAME on $env:COMPUTERNAME"

$exitAfterSummary = $false
do {
    Show-Menu
    $choice = Read-Host 'Select an option'
    switch ($choice) {
        '1'  { Invoke-CreateRestorePoint }
        '2'  { Invoke-DismCheckHealth }
        '3'  { Invoke-DismScanHealth }
        '4'  { Invoke-DismRestoreHealth }
        '5'  { Invoke-DismRestoreHealthFromSource }
        '6'  { Invoke-DismComponentCleanup }
        '7'  { Invoke-SfcScan }
        '8'  { Invoke-ChkdskScan }
        '9'  { Invoke-ChkdskScheduleFix }
        '10' { Invoke-WindowsUpdateReset }
        '11' { Invoke-NetworkReset }
        '12' { Invoke-StoreAppsReregister }
        '13' { Invoke-TempCleanup }
        '14' { Invoke-IconCacheRebuild }
        '15' { Invoke-FullSequence }
        '16' { Show-Summary }
        '0'  {
            Show-Summary
            $exitAfterSummary = $true
        }
        default {
            Write-Host 'Invalid selection.' -ForegroundColor Yellow
        }
    }
    if (-not $exitAfterSummary) {
        Write-Host ''
        Read-Host 'Press Enter to return to the menu'
    }
} while (-not $exitAfterSummary)

Write-Log 'Session ended'
Write-Host 'Press Enter to close...'
Read-Host | Out-Null
