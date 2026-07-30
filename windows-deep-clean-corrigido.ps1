# ============================================================
#   WINDOWS 10/11 UNIVERSAL DEEP CLEAN - CORRIGIDO
#   Adapta automaticamente às specs do seu PC
#   Execute como Administrador
# ============================================================
#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

# Helper pra rodar reg.exe sem poluir o console com erros
function Reg-Add {
    param($path, $name, $type, $value)
    reg add $path /v $name /t $type /d $value /f 2>$null | Out-Null
}
function Reg-Delete {
    param($path)
    if (Test-Path "Registry::$path") {
        reg delete $path /f 2>$null | Out-Null
    }
}

# ============================================================
# DETECT PC SPECS
# ============================================================
$RAM_GB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$OS = (Get-CimInstance Win32_OperatingSystem).Caption
$isDrivesSSD = $false

# Detecta se o disco do sistema (onde fica C:) é SSD, de forma mais confiável
try {
    $systemPartition = Get-Partition -DriveLetter C -ErrorAction Stop
    $systemDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $systemPartition.DiskNumber }
    if ($systemDisk.MediaType -eq "SSD") { $isDrivesSSD = $true }
} catch {
    # fallback: assume SSD se não conseguir detectar (maioria dos PCs hoje é SSD)
    $isDrivesSSD = $true
}

$isLaptop = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes -in @(8,9,10,11,12,14,18,21)
$CPU_Cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   WINDOWS UNIVERSAL DEEP CLEAN" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Specs detectadas:" -ForegroundColor White
Write-Host "  OS: $OS" -ForegroundColor Gray
Write-Host "  RAM: $RAM_GB GB" -ForegroundColor Gray
Write-Host "  SSD: $isDrivesSSD" -ForegroundColor Gray
Write-Host "  Notebook: $isLaptop" -ForegroundColor Gray
Write-Host "  Núcleos de CPU: $CPU_Cores" -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 2

# ============================================================
# [1/8] BLOATWARE (lista revisada - removi apps de risco)
# ============================================================
Write-Host "[1/8] Removendo bloatware..." -ForegroundColor Yellow

# REMOVIDOS da lista original por serem arriscados:
#  - Microsoft.HEIFImageExtension / VP9VideoExtensions / WebMediaExtensions / WebpImageExtension
#    -> removê-los quebra abertura de fotos vindas de iPhone/WhatsApp (.heic, .webp)
#  - Microsoft.MSPaint / Microsoft.ScreenSketch
#    -> ferramentas usadas no dia a dia por muita gente
$bloatware = @(
    "*YourPhone*", "*ZuneMusic*", "*ZuneVideo*", "*MixedReality*",
    "*Solitaire*", "*BingWeather*", "*BingNews*", "*BingFinance*",
    "*BingSports*", "*People*", "*WindowsMaps*", "*WindowsFeedbackHub*",
    "*WindowsAlarms*", "*WindowsCamera*", "*SkypeApp*",
    "*3DViewer*", "*Print3D*", "*GetHelp*", "*Getstarted*",
    "*XboxApp*", "*XboxGaming*", "*XboxGameOverlay*", "*XboxGamingOverlay*",
    "*XboxIdentityProvider*", "*XboxSpeechToTextOverlay*",
    "*GamingServices*", "*GamingApp*",
    "*Messaging*", "*OneConnect*", "*windowscommunicationsapps*",
    "*Microsoft.Wallet*", "*Microsoft.Whiteboard*",
    "*Microsoft.NetworkSpeedTest*",
    "*Microsoft.StorePurchaseApp*"
)

foreach ($app in $bloatware) {
    Get-AppxPackage $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-Host "  Bloatware removido!" -ForegroundColor Green

# ============================================================
# [2/8] ARQUIVOS TEMPORÁRIOS
# ============================================================
Write-Host "`n[2/8] Limpando arquivos temporários..." -ForegroundColor Yellow

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
    "C:\Windows\System32\LogFiles\*"
)
# OBS: removi "C:\Windows\*.log" da lista original -> apagar logs soltos direto na raiz
# do System32/Windows pode incluir logs em uso por serviços do sistema (gera erros/risco)

foreach ($folder in $junkfolders) {
    Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  Arquivos temporários limpos!" -ForegroundColor Green

# ============================================================
# [3/8] HIBERNAÇÃO E MEMÓRIA VIRTUAL (ADAPTATIVO)
# ============================================================
Write-Host "`n[3/8] Otimizando hibernação e memória virtual..." -ForegroundColor Yellow

if ($isLaptop) {
    Write-Host "  Notebook detectado — mantendo hibernação ativa." -ForegroundColor Gray
} else {
    powercfg /hibernate off
    Write-Host "  Hibernação desativada (desktop)." -ForegroundColor Gray
}

# Pagefile: só mexe se RAM >= 8GB. Com menos que isso, deixa 100% automático (mais seguro)
if ($RAM_GB -ge 8) {
    if ($RAM_GB -ge 32) { $pageSize = 2048 }
    elseif ($RAM_GB -ge 16) { $pageSize = 4096 }
    else { $pageSize = 8192 }

    try {
        $cs = Get-CimInstance -Class Win32_ComputerSystem
        Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile = $false} -ErrorAction Stop

        $pf = Get-CimInstance -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
        if ($pf) {
            Set-CimInstance -InputObject $pf -Property @{InitialSize = $pageSize; MaximumSize = $pageSize}
        } else {
            Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create `
                -Arguments @{ Name = "C:\pagefile.sys"; InitialSize = $pageSize; MaximumSize = $pageSize } -ErrorAction Stop
        }
        Write-Host "  Pagefile ajustado para $($pageSize/1024)GB (RAM: ${RAM_GB}GB)." -ForegroundColor Gray
    } catch {
        Write-Host "  Não foi possível ajustar o pagefile automaticamente. Mantendo configuração atual." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  RAM < 8GB: pagefile mantido automático (mais seguro para pouca RAM)." -ForegroundColor DarkYellow
}

Write-Host "  Memória otimizada!" -ForegroundColor Green

# ============================================================
# [4/8] SERVIÇOS DESNECESSÁRIOS (ADAPTATIVO)
# ============================================================
Write-Host "`n[4/8] Desativando serviços desnecessários..." -ForegroundColor Yellow

$services = @(
    "Fax",
    "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc",
    "MapsBroker",
    "RetailDemo",
    "wisvc",
    "WerSvc", "wercplsupport",
    "DiagTrack", "dmwappushservice",
    "RemoteRegistry",
    "TrkWks",
    "WMPNetworkSvc"
)
# REMOVIDO: WSearch -> desativar isso quebra a busca do menu Iniciar e do Explorer.
# REMOVIDO: HomeGroupListener/HomeGroupProvider -> não existem mais desde o Windows 10 1803, é lixo de script antigo.

if (-not $isLaptop) {
    $services += @("TabletInputService", "icssvc", "PhoneSvc", "lfsvc")
}

if ($isDrivesSSD) {
    $services += "SysMain"
    Write-Host "  SSD detectado: desativando SysMain (Superfetch)." -ForegroundColor Gray
} else {
    Write-Host "  HDD detectado: mantendo SysMain ativo." -ForegroundColor DarkYellow
}

$hasBiometrics = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -like "*fingerprint*" -or $_.Name -like "*biometric*" }
if (-not $hasBiometrics) {
    $services += "WbioSrvc"
    Write-Host "  Sem biometria detectada: desativando serviço biométrico." -ForegroundColor Gray
} else {
    Write-Host "  Dispositivo biométrico encontrado: mantendo serviço ativo." -ForegroundColor DarkYellow
}

foreach ($s in $services) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Desativado: $s" -ForegroundColor Gray
    }
}

Write-Host "  Serviços desativados!" -ForegroundColor Green

# ============================================================
# [5/8] TELEMETRIA, CORTANA E PRIVACIDADE
# ============================================================
Write-Host "`n[5/8] Desativando telemetria, Cortana e rastreamento..." -ForegroundColor Yellow

Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "REG_DWORD" 1
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" "REG_DWORD" 1
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" "REG_DWORD" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353698Enabled" "REG_DWORD" 0

Write-Host "  Telemetria e rastreamento desativados!" -ForegroundColor Green

# ============================================================
# [6/8] OTIMIZAÇÕES DE PERFORMANCE (ADAPTATIVO)
# ============================================================
Write-Host "`n[6/8] Aplicando otimizações de performance..." -ForegroundColor Yellow

Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" "REG_DWORD" 2
Reg-Add "HKCU\Control Panel\Desktop\WindowMetrics" "MinAnimate" "REG_SZ" 0
Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowInfoTip" "REG_DWORD" 0
Reg-Add "HKCU\System\GameConfigStore" "GameDVR_Enabled" "REG_DWORD" 0
Reg-Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" "REG_DWORD" 0

if ($CPU_Cores -ge 4) {
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" "REG_DWORD" 38
    Write-Host "  CPU multi-core: prioridade em primeiro plano ajustada." -ForegroundColor Gray
}

if (-not $isLaptop) {
    Reg-Add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" "REG_DWORD" 1
    Write-Host "  Desktop: Power Throttling desativado." -ForegroundColor Gray
} else {
    Write-Host "  Notebook: Power Throttling mantido (economiza bateria)." -ForegroundColor DarkYellow
}

if ($RAM_GB -le 4) {
    Reg-Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" "REG_DWORD" 3
    Write-Host "  RAM baixa detectada: todos os efeitos visuais desativados." -ForegroundColor DarkYellow
}

Write-Host "  Otimizações aplicadas!" -ForegroundColor Green

# ============================================================
# [7/8] LIMPEZA DE REGISTRO
# ============================================================
Write-Host "`n[7/8] Limpando entradas obsoletas do registro..." -ForegroundColor Yellow

Reg-Delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\SHC"
Reg-Delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
Reg-Delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
Reg-Delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"

Write-Host "  Registro limpo!" -ForegroundColor Green

# ============================================================
# [8/8] PLANO DE ENERGIA (ADAPTATIVO)
# ============================================================
Write-Host "`n[8/8] Configurando plano de energia..." -ForegroundColor Yellow

if ($isLaptop) {
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    Write-Host "  Notebook: plano definido como Equilibrado (economiza bateria)." -ForegroundColor Gray
} else {
    # O plano "Alto Desempenho" às vezes fica OCULTO no Windows - isso "desoculta" antes de ativar
    powercfg -attributes 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ATTRIB_HIDE 2>$null
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "  Desktop: plano definido como Alto Desempenho." -ForegroundColor Gray
}

Write-Host "  Plano de energia configurado!" -ForegroundColor Green

# ============================================================
# FIM
# ============================================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   LIMPEZA PROFUNDA CONCLUÍDA!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Resumo para seu PC ($RAM_GB GB RAM | SSD: $isDrivesSSD | Notebook: $isLaptop):" -ForegroundColor White
Write-Host "  [1] Bloatware removido (lista revisada, sem quebrar codecs de imagem)" -ForegroundColor Gray
Write-Host "  [2] Temporários, cache e lixo limpos" -ForegroundColor Gray
Write-Host "  [3] Memória otimizada para $RAM_GB GB de RAM" -ForegroundColor Gray
Write-Host "  [4] Serviços desnecessários desativados (busca do Windows preservada)" -ForegroundColor Gray
Write-Host "  [5] Telemetria, Cortana e rastreamento desativados" -ForegroundColor Gray
Write-Host "  [6] Otimizações de performance aplicadas" -ForegroundColor Gray
Write-Host "  [7] Registro limpo" -ForegroundColor Gray
if ($isLaptop) {
    Write-Host "  [8] Plano de energia: Equilibrado (modo notebook)" -ForegroundColor Gray
} else {
    Write-Host "  [8] Plano de energia: Alto Desempenho (modo desktop)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  REINICIE O PC AGORA para aplicar todas as mudanças!" -ForegroundColor Yellow
