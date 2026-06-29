# ============================================================
#   LIMPEZA PROFUNDA WINDOWS 10 - by @claraaraujodv instagram no instagram e tiktok
#   Execute como Administrador
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   LIMPEZA PROFUNDA WINDOWS 10" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# ============================================================
# [1/8] BLOATWARE - APPS NATIVOS
# ============================================================
Write-Host "`n[1/8] Removendo bloatware..." -ForegroundColor Yellow

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

Write-Host "  Bloatware removido!" -ForegroundColor Green

# ============================================================
# [2/8] ARQUIVOS TEMPORÁRIOS E LIXO
# ============================================================
Write-Host "`n[2/8] Limpando arquivos temporários..." -ForegroundColor Yellow

$pastaslixo = @(
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

foreach ($pasta in $pastaslixo) {
    Remove-Item -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue
}

# Limpeza de Disco automatica
Write-Host "  Rodando limpeza de disco..." -ForegroundColor Gray
$sageclean = @"
[Settings]
StateFlags0001=2
[Components]
StateFlags0001=0
"@
Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden

Write-Host "  Temporários limpos!" -ForegroundColor Green

# ============================================================
# [3/8] HIBERNAÇÃO E MEMÓRIA VIRTUAL
# ============================================================
Write-Host "`n[3/8] Otimizando hibernacao e memoria virtual..." -ForegroundColor Yellow

# Desativa hibernação
powercfg /hibernate off

# Reduz pagefile para 2GB (suficiente com 64GB RAM)
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

Write-Host "  Hibernacao desativada e pagefile reduzido para 2GB!" -ForegroundColor Green

# ============================================================
# [4/8] SERVIÇOS DESNECESSÁRIOS
# ============================================================
Write-Host "`n[4/8] Desativando servicos desnecessarios..." -ForegroundColor Yellow

$servicos = @(
    "SysMain",           # Superfetch - inutil em SSD
    "WSearch",           # Windows Search
    "Fax",               # Fax
    "PhoneSvc",          # Telefone
    "XblAuthManager",    # Xbox Live
    "XblGameSave",       # Xbox Live
    "XboxNetApiSvc",     # Xbox Live
    "XboxGipSvc",        # Xbox Live
    "MapsBroker",        # Mapas offline
    "lfsvc",             # Geolocalização
    "RetailDemo",        # Modo demonstração de loja
    "TabletInputService",# Teclado virtual
    "icssvc",            # Hotspot movel
    "WbioSrvc",          # Biometria (se nao usa)
    "wisvc",             # Windows Insider
    "WerSvc",            # Relatorio de erros Windows
    "wercplsupport",     # Painel de relatorio de erros
    "DiagTrack",         # Telemetria / rastreamento
    "dmwappushservice",  # Telemetria WAP
    "PcaSvc",            # Assistente de compatibilidade de programa
    "RemoteRegistry",    # Registro remoto - risco de segurança
    "SharedAccess",      # Compartilhamento de internet (ICS)
    "TrkWks",            # Rastreamento de links distribuídos
    "WMPNetworkSvc",     # Windows Media Player (rede)
    "HomeGroupListener", # HomeGroup
    "HomeGroupProvider"  # HomeGroup
)

foreach ($s in $servicos) {
    try {
        Stop-Service -Name $s -Force
        Set-Service -Name $s -StartupType Disabled
        Write-Host "  Desativado: $s" -ForegroundColor Gray
    } catch {
        Write-Host "  Nao encontrado: $s" -ForegroundColor DarkGray
    }
}

Write-Host "  Servicos desativados!" -ForegroundColor Green

# ============================================================
# [5/8] TELEMETRIA, CORTANA E PRIVACIDADE
# ============================================================
Write-Host "`n[5/8] Desativando telemetria, Cortana e rastreamento..." -ForegroundColor Yellow

# Telemetria
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null

# Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f | Out-Null

# Publicidade
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f | Out-Null

# Experiencias personalizadas
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f | Out-Null

# Desativa feedback
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f | Out-Null

# Desativa rastreamento de atividade
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f | Out-Null

# Desativa linha do tempo (Timeline)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null

# Desativa sugestoes de apps na loja
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null

Write-Host "  Telemetria e rastreamento desativados!" -ForegroundColor Green

# ============================================================
# [6/8] OTIMIZAÇÕES DE DESEMPENHO
# ============================================================
Write-Host "`n[6/8] Aplicando otimizacoes de desempenho..." -ForegroundColor Yellow

# Desativa efeitos visuais desnecessários (mantém o essencial)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null

# Desativa animações
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null

# Desativa notificações de dicas do Windows
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f | Out-Null

# Prioridade de CPU para programas (não background)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null

# Desativa Game DVR (grava gameplay em background mesmo sem pedir)
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null

# Desativa Power Throttling (reduz throttle em CPUs modernas)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f | Out-Null

Write-Host "  Otimizacoes aplicadas!" -ForegroundColor Green

# ============================================================
# [7/8] LIMPEZA DE REGISTRO
# ============================================================
Write-Host "`n[7/8] Limpando entradas obsoletas do registro..." -ForegroundColor Yellow

# Remove entradas de programas desinstalados do menu iniciar
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\SHC" /f | Out-Null

# Limpa lista de programas recentes
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f | Out-Null

# Limpa historico de barra de enderecos do Explorer
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f | Out-Null

# Limpa historico de pesquisa do Explorer
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f | Out-Null

Write-Host "  Registro limpo!" -ForegroundColor Green

# ============================================================
# [8/8] OTIMIZAÇÃO DO PLANO DE ENERGIA
# ============================================================
Write-Host "`n[8/8] Configurando plano de energia para Alto Desempenho..." -ForegroundColor Yellow

powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

Write-Host "  Plano de energia: Alto Desempenho ativado!" -ForegroundColor Green

# ============================================================
# CONCLUÍDO
# ============================================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   LIMPEZA CONCLUIDA COM SUCESSO!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "`nO que foi feito:" -ForegroundColor White
Write-Host "  [1] Bloatware removido (~35 apps)" -ForegroundColor Gray
Write-Host "  [2] Temporarios, cache e lixo limpos" -ForegroundColor Gray
Write-Host "  [3] Hibernacao off + pagefile reduzido para 2GB" -ForegroundColor Gray
Write-Host "  [4] 25 servicos desnecessarios desativados" -ForegroundColor Gray
Write-Host "  [5] Telemetria, Cortana e rastreamento desativados" -ForegroundColor Gray
Write-Host "  [6] Otimizacoes de desempenho aplicadas" -ForegroundColor Gray
Write-Host "  [7] Registro limpo" -ForegroundColor Gray
Write-Host "  [8] Plano de energia: Alto Desempenho" -ForegroundColor Gray
Write-Host "`nREINICIE O PC AGORA para aplicar tudo!" -ForegroundColor Yellow