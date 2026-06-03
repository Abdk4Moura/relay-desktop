# Relay desktop receiver — one-line installer for Windows.
#
#   irm https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.ps1 | iex
#
# Downloads the prebuilt receiver, installs it to %LOCALAPPDATA%\Relay, enables
# start-on-login, and launches it. No build tools needed.

$ErrorActionPreference = 'Stop'
$repo = 'Abdk4Moura/relay-desktop'
$asset = 'relay-desktop-windows-x86_64.zip'
$url = "https://github.com/$repo/releases/latest/download/$asset"
$dir = Join-Path $env:LOCALAPPDATA 'Relay'

function Say($m) { Write-Host "> $m" -ForegroundColor Green }

Say "Downloading $asset..."
$tmp = Join-Path $env:TEMP $asset
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing

Say "Installing to $dir..."
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Expand-Archive -Path $tmp -DestinationPath $dir -Force
Remove-Item $tmp -Force
$exe = Join-Path $dir 'relay-desktop.exe'

# Put it on PATH for the current user (so `relay-desktop` works in new shells).
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$dir*") {
  [Environment]::SetEnvironmentVariable('Path', "$userPath;$dir", 'User')
}

Say "Enabling start-on-login..."
& $exe autostart on | Out-Null

Say "Starting Relay..."
Start-Process -FilePath $exe -WindowStyle Hidden
Start-Sleep -Seconds 1

Say "Done. Relay is running - control panel: http://127.0.0.1:47601"
Say "Open the Relay app on your phone; it'll discover this computer automatically."
Write-Host ""
Write-Host "Note: Windows SmartScreen may warn on first launch (unsigned). Click 'More info' -> 'Run anyway'." -ForegroundColor Yellow
