#!/usr/bin/env pwsh
# Claude Code hook script to check if Docker rebuild is needed

param(
    [string]$FileName = "",
    [string]$Action = ""
)

# Track changed files in this session
$sessionFile = "./.claude-code/session-changes.txt"
if (-not (Test-Path $sessionFile)) {
    New-Item -ItemType File -Path $sessionFile -Force | Out-Null
}

# Add current file to session changes
if ($FileName) {
    Add-Content -Path $sessionFile -Value $FileName
}

# Check what types of files have been changed
$changes = Get-Content $sessionFile -ErrorAction SilentlyContinue
$csChanges = $changes | Where-Object { $_ -match '\.(cs|razor|cshtml|csproj)$' }
$staticChanges = $changes | Where-Object { $_ -match '\.(css|js|html|png|jpg|svg)$' }

if ($csChanges) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║         🚨 C#/RAZOR CHANGES DETECTED IN SESSION!         ║" -ForegroundColor Red
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║  Changed files requiring rebuild:                         ║" -ForegroundColor Yellow
    
    $csChanges | Select-Object -Unique | ForEach-Object {
        $file = [System.IO.Path]::GetFileName($_)
        if ($file.Length -gt 50) { $file = "..." + $file.Substring($file.Length - 47) }
        $paddedFile = "║    - $file".PadRight(59) + "║"
        Write-Host $paddedFile -ForegroundColor Gray
    }
    
    Write-Host "║                                                           ║" -ForegroundColor Yellow
    Write-Host "║  🔧 REQUIRED ACTION:                                      ║" -ForegroundColor Red
    Write-Host "║     Run: .\rebuild.ps1                                   ║" -ForegroundColor Green
    Write-Host "║                                                           ║" -ForegroundColor Yellow
    Write-Host "║  ⚠️  Do NOT use: docker-compose restart                   ║" -ForegroundColor Yellow
    Write-Host "║     (It won't reload compiled DLLs!)                     ║" -ForegroundColor Gray
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    
    # Create a marker file to remind us
    "REBUILD_REQUIRED" | Out-File -FilePath "./.claude-code/rebuild-required.marker"
}
elseif ($staticChanges -and -not $csChanges) {
    Write-Host "✅ Only static files changed - volume mounts will handle these" -ForegroundColor Green
}