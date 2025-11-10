Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$handleExePath = "C:\Users\\Downloads\AutoInstance\handle64.exe"
$iconPath = "C:\Users\\Downloads\AutoInstance\Logo.ico"

if (-not (Test-Path $handleExePath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "handle64.exe not found!`n`nDownload from:`nhttps://learn.microsoft.com/en-us/sysinternals/downloads/handle`n`nPlace handle64.exe in the same directory as this script.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "v1.01"
$form.Size = New-Object System.Drawing.Size(380, 240)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.MinimizeBox = $true

if (Test-Path $iconPath) {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
}

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Fill"
$form.Controls.Add($panel)

$panel.Add_Paint({
    param($sender, $e)
    $rect = $sender.ClientRectangle
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::Black,
        [System.Drawing.Color]::FromArgb(201, 90, 90),
        45
    )
    $e.Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()
})

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "RobloxMultiInstance"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.Location = New-Object System.Drawing.Point(0, 30)
$titleLabel.Size = New-Object System.Drawing.Size(380, 40)
$titleLabel.TextAlign = "MiddleCenter"
$panel.Controls.Add($titleLabel)

$authorLabel = New-Object System.Windows.Forms.Label
$authorLabel.Text = "Made by @kweffle on discord"
$authorLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$authorLabel.ForeColor = [System.Drawing.Color]::White
$authorLabel.BackColor = [System.Drawing.Color]::Transparent
$authorLabel.Location = New-Object System.Drawing.Point(0, 80)
$authorLabel.Size = New-Object System.Drawing.Size(380, 20)
$authorLabel.TextAlign = "MiddleCenter"
$panel.Controls.Add($authorLabel)

$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.Text = "Check for updates"
$linkLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$linkLabel.LinkColor = [System.Drawing.Color]::White
$linkLabel.ActiveLinkColor = [System.Drawing.Color]::FromArgb(255, 150, 100)
$linkLabel.VisitedLinkColor = [System.Drawing.Color]::White
$linkLabel.BackColor = [System.Drawing.Color]::Transparent
$linkLabel.Location = New-Object System.Drawing.Point(0, 105)
$linkLabel.Size = New-Object System.Drawing.Size(380, 20)
$linkLabel.TextAlign = "MiddleCenter"
$linkLabel.Add_LinkClicked({
    Start-Process "https://github.com/Kweffle/Multiple-Instance/releases"
})
$panel.Controls.Add($linkLabel)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "V1.01"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$versionLabel.ForeColor = [System.Drawing.Color]::White
$versionLabel.BackColor = [System.Drawing.Color]::Transparent
$versionLabel.Location = New-Object System.Drawing.Point(0, 130)
$versionLabel.Size = New-Object System.Drawing.Size(380, 20)
$versionLabel.TextAlign = "MiddleCenter"
$panel.Controls.Add($versionLabel)

$keepOpenLabel = New-Object System.Windows.Forms.Label
$keepOpenLabel.Text = "Keep open to work"
$keepOpenLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$keepOpenLabel.ForeColor = [System.Drawing.Color]::White
$keepOpenLabel.BackColor = [System.Drawing.Color]::Transparent
$keepOpenLabel.Location = New-Object System.Drawing.Point(0, 160)
$keepOpenLabel.Size = New-Object System.Drawing.Size(380, 25)
$keepOpenLabel.TextAlign = "MiddleCenter"
$panel.Controls.Add($keepOpenLabel)

$seenPIDs = @{}
$isRunning = $true

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

$timer.Add_Tick({
    if (-not $isRunning) { return }
    
    try {
        $processes = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
        
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
                    if ($line -match "ROBLOX_singletonEvent" -and $line -match '\bEvent\b') {
                        if ($line -match '\s+([0-9a-fA-F]+):') {
                            $handleId = $matches[1]
                            $handleFound = $true
                            
                            & $handleExePath -p $processId -c $handleId -y -nobanner 2>&1 | Out-Null
                            break
                        }
                    }
                }
                
                if ($handleFound) { break }
            }
        }
        
        $currentPIDs = (Get-Process -ErrorAction SilentlyContinue).Id
        $seenPIDs.Keys | Where-Object { $_ -notin $currentPIDs } | ForEach-Object {
            $seenPIDs.Remove($_)
        }
        
    } catch {}
})

$form.Add_FormClosing({
    $timer.Stop()
    $script:isRunning = $false
})

$timer.Start()

[void]$form.ShowDialog()
$timer.Dispose()
$form.Dispose()
