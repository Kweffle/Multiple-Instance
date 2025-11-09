param(
    [Parameter(Mandatory=$false)]
    [string]$TargetProcess = "RobloxPlayerBeta.exe",
    
    [Parameter(Mandatory=$false)]
    [string]$HandleFilter = "ROBLOX_singletonEvent",
    
    [Parameter(Mandatory=$false)]
    [int]$CheckIntervalMs = 500
)

$handleExePath = "C:\Users\parke\Downloads\AutoInstance\handle64.exe"
if (-not (Test-Path $handleExePath)) {
    Write-Host "ERROR: handle64.exe not found!" -ForegroundColor Red
    Write-Host "Download from: https://learn.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor Yellow
    Write-Host "Place handle64.exe in the same directory as this script." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -TargetProcess `"$TargetProcess`" -HandleFilter `"$HandleFilter`" -CheckIntervalMs $CheckIntervalMs" -Verb RunAs
    exit
}

Write-Host ""
Write-Host "█▀▄▀█ █░█ █░░ ▀█▀ █ █▀█ █░░ █▀▀   █ █▄░█ █▀ ▀█▀ ▄▀█ █▄░█ █▀▀ █▀▀" -ForegroundColor Cyan
Write-Host "█░▀░█ █▄█ █▄▄ ░█░ █ █▀▀ █▄▄ ██▄   █ █░▀█ ▄█ ░█░ █▀█ █░▀█ █▄▄ ██▄" -ForegroundColor Cyan
Write-Host ""
Write-Host "Made by @kweffle on discord | For updates: https://github.com/Kweffle/Multiple-Instance" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor Yellow
Write-Host ""

$seenPIDs = @{}
$Host.UI.RawUI.WindowTitle = "RobloxMultiInstance v1.00 | Made by @Kweffle"

while ($true) {
    try {
        $processes = Get-Process -Name $TargetProcess.Replace(".exe", "") -ErrorAction SilentlyContinue

        foreach ($proc in $processes) {
            $processId = $proc.Id
            
            if ($seenPIDs.ContainsKey($processId)) {
                continue
            }
            
            $seenPIDs[$processId] = $true
            
            $maxAttempts = 10
            $handleFound = $false
            
            for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                Start-Sleep -Milliseconds 100
                
                $handleOutput = & $handleExePath -a -p $processId -nobanner 2>&1 | Out-String
                
                $lines = $handleOutput -split "`n"
                
                foreach ($line in $lines) {
                    if ($line -match $HandleFilter -and $line -match '\bEvent\b') {
                        if ($line -match '\s+([0-9a-fA-F]+):') {
                            $handleId = $matches[1]
                            $handleFound = $true
                            
                            & $handleExePath -p $processId -c $handleId -y -nobanner 2>&1 | Out-Null
                            break
                        }
                    }
                }
                
                if ($handleFound) {
                    break
                }
            }
        }
        
        $currentPIDs = (Get-Process -ErrorAction SilentlyContinue).Id
        $seenPIDs.Keys | Where-Object { $_ -notin $currentPIDs } | ForEach-Object {
            $seenPIDs.Remove($_)
        }
        
        Start-Sleep -Milliseconds $CheckIntervalMs
        
    } catch {
    }
}