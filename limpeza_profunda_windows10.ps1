# ============================================================
#   WINDOWS 10/11 UNIVERSAL DEEP CLEAN - by @claraaraujodv
#   Automatically adapts to your PC specs
#   Run as Administrator
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# DETECT PC SPECS
# ============================================================
$RAM_GB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$OS = (Get-WmiObject Win32_OperatingSystem).Caption
$isDrivesSSD = $false

# Check if system drive is SSD
$diskDrive = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE MediaType='Fixed hard disk media' OR MediaType='Solid-state drive (SSD)'"
$systemDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 }
if ($systemDisk.MediaType -eq "SSD") { $isDrivesSSD = $true }

$isLaptop = (Get-WmiObject Win32_SystemEnclosure).ChassisTypes -in @(8,9,10,11,12,14,18,21)
$CPU_Cores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   WINDOWS UNIVERSAL DEEP CLEAN" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Detected specs:" -ForegroundColor White
Write-Host "  OS: $OS" -ForegroundColor Gray
Write-Host "  RAM: $RAM_GB GB" -ForegroundColor Gray
Write-Host "  SSD: $isDrivesSSD" -ForegroundColor Gray
Write-Host "  Laptop: $isLaptop" -ForegroundColor Gray
Write-Host "  CPU Cores: $CPU_Cores" -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 2

# ============================================================
# [1/8] BLOATWARE
# ============================================================
Write-Host "[1/8] Removing bloatware..." -ForegroundColor Yellow

$bloatware = @(
    "*YourPhone*", "*ZuneMusic*", "*ZuneVideo*", "*MixedReality*",
    "*Solitaire*", "*BingWeather*", "*BingNews*", "*BingFinance*",
    "*BingSports*", "*People*", "*WindowsMaps*", "*WindowsFeedbackHub*",
    "*WindowsAlarms*", "*WindowsCamera*", "*SkypeApp*", "*Office.OneNote*",
    "*3DViewer*", "*Print3D*", "*GetHelp*", "*Getstarted*",
    "*XboxApp*", "*XboxGaming*", "*XboxGameOverlay*", "*XboxGamingOverlay*",
    "*XboxIdentityProvider*", "*XboxSpeechToTextOverlay*",
    "*GamingServices*", "*GamingApp*", "*MicrosoftTeams*",
    "*Messaging*", "*OneConnect*", "*windowscommunicationsapps*",
    "*Microsoft.Wallet*", "*Microsoft.Whiteboard*",
    "*Microsoft.NetworkSpeedTest*", "*Microsoft.MSPaint*",
    "*Microsoft.HEIFImageExtension*", "*Microsoft.VP9VideoExtensions*",
    "*Microsoft.WebMediaExtensions*", "*Microsoft.WebpImageExtension*",
    "*Microsoft.ScreenSketch*", "*Microsoft.StorePurchaseApp*"
)

foreach ($app in $bloatware) {
    Get-AppxPackage $app | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
}

Write-Host "  Bloatware removed!" -ForegroundColor Green

# ============================================================
# [2/8] TEMPORARY FILES
# ============================================================
Write-Host "`n[2/8] Cleaning temporary files..." -ForegroundColor Yellow

$junkfolders = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\Prefetch\*",
    "$env:LOCALAPPDATA\Temp\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
    "C:\Windows\SoftwareDistribution\Download\*",
    "$env:APPDATA\Microsoft\Windows\Recent\*",
    "C:\Windows\Logs\*",
    "C:\Windows\*.log",
    "C:\Windows\System32\LogFiles\*"
)

foreach ($folder in $junkfolders) {
    Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  Running disk cleanup..." -ForegroundColor Gray
Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
Write-Host "  Temporary files cleaned!" -ForegroundColor Green

# ============================================================
# [3/8] HIBERNATION AND VIRTUAL MEMORY (ADAPTIVE)
# ============================================================
Write-Host "`n[3/8] Optimizing hibernation and virtual memory..." -ForegroundColor Yellow

# Always disable hibernation on desktops; keep on laptops
if ($isLaptop) {
    Write-Host "  Laptop detected — keeping hibernation enabled." -ForegroundColor Gray
} else {
    powercfg /hibernate off
    Write-Host "  Hibernation disabled (desktop)." -ForegroundColor Gray
}

# Pagefile size based on RAM
$cs = Get-WmiObject -Class Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $false
$cs.Put()
$pf = Get-WmiObject -Class Win32_PageFileSetting

if ($RAM_GB -ge 32) {
    $pageSize = 2048
    Write-Host "  RAM >= 32GB: pagefile set to 2GB." -ForegroundColor Gray
} elseif ($RAM_GB -ge 16) {
    $pageSize = 4096
    Write-Host "  RAM >= 16GB: pagefile set to 4GB." -ForegroundColor Gray
} elseif ($RAM_GB -ge 8) {
    $pageSize = 8192
    Write-Host "  RAM >= 8GB: pagefile set to 8GB." -ForegroundColor Gray
} else {
    $pageSize = 0  # Keep automatic for low RAM PCs
    $cs.AutomaticManagedPagefile = $true
    $cs.Put()
    Write-Host "  RAM < 8GB: pagefile kept automatic (low RAM detected)." -ForegroundColor DarkYellow
}

if ($pageSize -gt 0 -and $pf) {
    $pf.InitialSize = $pageSize
    $pf.MaximumSize = $pageSize
    $pf.Put()
} elseif ($pageSize -gt 0) {
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{
        Name = "C:\pagefile.sys"
        InitialSize = $pageSize
        MaximumSize = $pageSize
    }
}

Write-Host "  Memory optimized!" -ForegroundColor Green

# ============================================================
# [4/8] UNNECESSARY SERVICES (ADAPTIVE)
# ============================================================
Write-Host "`n[4/8] Disabling unnecessary services..." -ForegroundColor Yellow

# Base services — safe for ALL PCs
$services = @(
    "Fax",               # Fax
    "XblAuthManager",    # Xbox Live
    "XblGameSave",       # Xbox Live
    "XboxNetApiSvc",     # Xbox Live
    "XboxGipSvc",        # Xbox Live
    "MapsBroker",        # Offline Maps
    "RetailDemo",        # Store demo mode
    "wisvc",             # Windows Insider
    "WerSvc",            # Windows Error Reporting
    "wercplsupport",     # Error Reporting Panel
    "DiagTrack",         # Telemetry
    "dmwappushservice",  # WAP Telemetry
    "RemoteRegistry",    # Remote Registry - security risk
    "TrkWks",            # Distributed Link Tracking
    "WMPNetworkSvc",     # Windows Media Player network
    "HomeGroupListener",
    "HomeGroupProvider"
)

# Only disable on desktops (laptops may need these)
if (-not $isLaptop) {
    $services += @(
        "TabletInputService", # Virtual keyboard
        "icssvc",             # Mobile hotspot
        "PhoneSvc"            # Phone integration
    )
}

# Only disable SysMain on SSDs (useful on HDD)
if ($isDrivesSSD) {
    $services += "SysMain"
    Write-Host "  SSD detected: disabling SysMain (Superfetch)." -ForegroundColor Gray
} else {
    Write-Host "  HDD detected: keeping SysMain active." -ForegroundColor DarkYellow
}

# Only disable Windows Search on high RAM PCs
if ($RAM_GB -ge 8) {
    $services += "WSearch"
    Write-Host "  RAM sufficient: disabling Windows Search indexing." -ForegroundColor Gray
} else {
    Write-Host "  Low RAM: keeping Windows Search (needed for performance)." -ForegroundColor DarkYellow
}

# Geolocation — disable on desktops, keep on laptops
if (-not $isLaptop) {
    $services += "lfsvc"
}

# Biometrics — disable only if no fingerprint reader detected
$hasBiometrics = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like "*fingerprint*" -or $_.Name -like "*biometric*" }
if (-not $hasBiometrics) {
    $services += "WbioSrvc"
    Write-Host "  No biometrics detected: disabling biometric service." -ForegroundColor Gray
} else {
    Write-Host "  Biometric device found: keeping biometric service." -ForegroundColor DarkYellow
}

foreach ($s in $services) {
    try {
        Stop-Service -Name $s -Force
        Set-Service -Name $s -StartupType Disabled
        Write-Host "  Disabled: $s" -ForegroundColor Gray
    } catch {
        Write-Host "  Not found: $s" -ForegroundColor DarkGray
    }
}

Write-Host "  Services disabled!" -ForegroundColor Green

# ============================================================
# [5/8] TELEMETRY, CORTANA AND PRIVACY
# ============================================================
Write-Host "`n[5/8] Disabling telemetry, Cortana and tracking..." -ForegroundColor Yellow

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null

Write-Host "  Telemetry and tracking disabled!" -ForegroundColor Green

# ============================================================
# [6/8] PERFORMANCE OPTIMIZATIONS (ADAPTIVE)
# ============================================================
Write-Host "`n[6/8] Applying performance optimizations..." -ForegroundColor Yellow

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null

# CPU priority — only tweak on multi-core systems
if ($CPU_Cores -ge 4) {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null
    Write-Host "  Multi-core CPU: foreground priority boosted." -ForegroundColor Gray
}

# Power Throttling — disable only on desktops
if (-not $isLaptop) {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f | Out-Null
    Write-Host "  Desktop: Power Throttling disabled." -ForegroundColor Gray
} else {
    Write-Host "  Laptop: Power Throttling kept (saves battery)." -ForegroundColor DarkYellow
}

# Low RAM extra optimization: reduce visual effects further
if ($RAM_GB -le 4) {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f | Out-Null
    Write-Host "  Low RAM detected: all visual effects disabled for maximum performance." -ForegroundColor DarkYellow
}

Write-Host "  Optimizations applied!" -ForegroundColor Green

# ============================================================
# [7/8] REGISTRY CLEANUP
# ============================================================
Write-Host "`n[7/8] Cleaning obsolete registry entries..." -ForegroundColor Yellow

reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\SHC" /f | Out-Null
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f | Out-Null
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f | Out-Null
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f | Out-Null

Write-Host "  Registry cleaned!" -ForegroundColor Green

# ============================================================
# [8/8] POWER PLAN (ADAPTIVE)
# ============================================================
Write-Host "`n[8/8] Configuring power plan..." -ForegroundColor Yellow

if ($isLaptop) {
    # Balanced for laptops — preserves battery
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    Write-Host "  Laptop: power plan set to Balanced (preserves battery)." -ForegroundColor Gray
} else {
    # High Performance for desktops
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "  Desktop: power plan set to High Performance." -ForegroundColor Gray
}

Write-Host "  Power plan configured!" -ForegroundColor Green

# ============================================================
# DONE
# ============================================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   DEEP CLEAN COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Summary for your PC ($RAM_GB GB RAM | SSD: $isDrivesSSD | Laptop: $isLaptop):" -ForegroundColor White
Write-Host "  [1] Bloatware removed (~35 apps)" -ForegroundColor Gray
Write-Host "  [2] Temp files, cache and junk cleaned" -ForegroundColor Gray
Write-Host "  [3] Memory optimized for $RAM_GB GB RAM" -ForegroundColor Gray
Write-Host "  [4] Unnecessary services disabled" -ForegroundColor Gray
Write-Host "  [5] Telemetry, Cortana and tracking disabled" -ForegroundColor Gray
Write-Host "  [6] Performance optimizations applied" -ForegroundColor Gray
Write-Host "  [7] Registry cleaned" -ForegroundColor Gray
if ($isLaptop) {
    Write-Host "  [8] Power plan: Balanced (laptop mode)" -ForegroundColor Gray
} else {
    Write-Host "  [8] Power plan: High Performance (desktop mode)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  RESTART YOUR PC NOW to apply all changes!" -ForegroundColor Yellow
Read-Host "`nPressione ENTER para fechar"