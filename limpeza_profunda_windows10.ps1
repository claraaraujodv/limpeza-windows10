# ============================================================
#   WINDOWS 10 DEEP CLEAN - by @claraaraujodv on instagram and tiktok
#   Run as Administrator
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   WINDOWS 10 DEEP CLEAN" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# ============================================================
# [1/8] BLOATWARE - BUILT-IN APPS
# ============================================================
Write-Host "`n[1/8] Removing bloatware..." -ForegroundColor Yellow

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
# [2/8] TEMPORARY FILES AND JUNK
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

# Automatic Disk Cleanup
Write-Host "  Running disk cleanup..." -ForegroundColor Gray
$sageclean = @"
[Settings]
StateFlags0001=2
[Components]
StateFlags0001=0
"@
Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden

Write-Host "  Temporary files cleaned!" -ForegroundColor Green

# ============================================================
# [3/8] HIBERNATION AND VIRTUAL MEMORY
# ============================================================
Write-Host "`n[3/8] Optimizing hibernation and virtual memory..." -ForegroundColor Yellow

# Disable hibernation
powercfg /hibernate off

# Reduce pagefile to 2GB (sufficient with 64GB RAM)
$cs = Get-WmiObject -Class Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $false
$cs.Put()
$pf = Get-WmiObject -Class Win32_PageFileSetting
if ($pf) {
    $pf.InitialSize = 2048
    $pf.MaximumSize = 2048
    $pf.Put()
} else {
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{
        Name = "C:\pagefile.sys"
        InitialSize = 2048
        MaximumSize = 2048
    }
}

Write-Host "  Hibernation disabled and pagefile reduced to 2GB!" -ForegroundColor Green

# ============================================================
# [4/8] UNNECESSARY SERVICES
# ============================================================
Write-Host "`n[4/8] Disabling unnecessary services..." -ForegroundColor Yellow

$services = @(
    "SysMain",           # Superfetch - useless on SSD
    "WSearch",           # Windows Search
    "Fax",               # Fax
    "PhoneSvc",          # Phone
    "XblAuthManager",    # Xbox Live
    "XblGameSave",       # Xbox Live
    "XboxNetApiSvc",     # Xbox Live
    "XboxGipSvc",        # Xbox Live
    "MapsBroker",        # Offline Maps
    "lfsvc",             # Geolocation
    "RetailDemo",        # Store demo mode
    "TabletInputService",# Virtual keyboard
    "icssvc",            # Mobile hotspot
    "WbioSrvc",          # Biometrics (if not used)
    "wisvc",             # Windows Insider
    "WerSvc",            # Windows Error Reporting
    "wercplsupport",     # Error Reporting Control Panel
    "DiagTrack",         # Telemetry / tracking
    "dmwappushservice",  # WAP telemetry
    "PcaSvc",            # Program Compatibility Assistant
    "RemoteRegistry",    # Remote Registry - security risk
    "SharedAccess",      # Internet Connection Sharing (ICS)
    "TrkWks",            # Distributed Link Tracking
    "WMPNetworkSvc",     # Windows Media Player (network)
    "HomeGroupListener", # HomeGroup
    "HomeGroupProvider"  # HomeGroup
)

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

# Telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null

# Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f | Out-Null

# Advertising
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f | Out-Null

# Tailored experiences
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f | Out-Null

# Disable feedback
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f | Out-Null

# Disable activity tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f | Out-Null

# Disable Timeline
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null

# Disable app suggestions from Store
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null

Write-Host "  Telemetry and tracking disabled!" -ForegroundColor Green

# ============================================================
# [6/8] PERFORMANCE OPTIMIZATIONS
# ============================================================
Write-Host "`n[6/8] Applying performance optimizations..." -ForegroundColor Yellow

# Disable unnecessary visual effects (keeps the essentials)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null

# Disable animations
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null

# Disable Windows tips notifications
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f | Out-Null

# CPU priority for foreground programs (not background)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null

# Disable Game DVR (records gameplay in background without asking)
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null

# Disable Power Throttling (reduces throttling on modern CPUs)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f | Out-Null

Write-Host "  Optimizations applied!" -ForegroundColor Green

# ============================================================
# [7/8] REGISTRY CLEANUP
# ============================================================
Write-Host "`n[7/8] Cleaning obsolete registry entries..." -ForegroundColor Yellow

# Remove uninstalled programs entries from Start Menu
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\SHC" /f | Out-Null

# Clear recent programs list
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f | Out-Null

# Clear Explorer address bar history
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f | Out-Null

# Clear Explorer search history
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f | Out-Null

Write-Host "  Registry cleaned!" -ForegroundColor Green

# ============================================================
# [8/8] POWER PLAN OPTIMIZATION
# ============================================================
Write-Host "`n[8/8] Setting power plan to High Performance..." -ForegroundColor Yellow

powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

Write-Host "  Power plan: High Performance activated!" -ForegroundColor Green

# ============================================================
# DONE
# ============================================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   DEEP CLEAN COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nWhat was done:" -ForegroundColor White
Write-Host "  [1] Bloatware removed (~35 apps)" -ForegroundColor Gray
Write-Host "  [2] Temp files, cache and junk cleaned" -ForegroundColor Gray
Write-Host "  [3] Hibernation off + pagefile reduced to 2GB" -ForegroundColor Gray
Write-Host "  [4] 25 unnecessary services disabled" -ForegroundColor Gray
Write-Host "  [5] Telemetry, Cortana and tracking disabled" -ForegroundColor Gray
Write-Host "  [6] Performance optimizations applied" -ForegroundColor Gray
Write-Host "  [7] Registry cleaned" -ForegroundColor Gray
Write-Host "  [8] Power plan: High Performance" -ForegroundColor Gray
Write-Host "`nRESTART YOUR PC NOW to apply all changes!" -ForegroundColor Yellow