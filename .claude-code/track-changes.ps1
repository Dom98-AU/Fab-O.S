#!/usr/bin/env pwsh
# Simple change tracking for Claude Code hooks

param(
    [string]$FilePath = "",
    [string]$Command = ""
)

# Track C#/Razor changes (including CSS isolation)
if ($FilePath -match '\.(cs|razor|razor\.css|cshtml|csproj)$') {
    # Create marker file
    "C# changes detected at $(Get-Date)" | Out-File -FilePath "./.claude-code/cs-changes.marker"
    
    # Different message for CSS isolation files
    if ($FilePath -match '\.razor\.css$') {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  🎨 Blazor CSS Isolation file changed!" -ForegroundColor Cyan
        Write-Host "  File: $(Split-Path $FilePath -Leaf)" -ForegroundColor Gray
        Write-Host "  " -ForegroundColor Yellow
        Write-Host "  CSS isolation compiles at build time!" -ForegroundColor Yellow
        Write-Host "  Required action: .\rebuild.ps1" -ForegroundColor Green
        Write-Host "  (Full rebuild needed for scoped styles)" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  🚨 C#/Razor file changed!" -ForegroundColor Yellow
        Write-Host "  File: $(Split-Path $FilePath -Leaf)" -ForegroundColor Gray
        Write-Host "  " -ForegroundColor Yellow
        Write-Host "  Required action: .\rebuild.ps1" -ForegroundColor Green
        Write-Host "  (NOT docker-compose restart!)" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""
    }
}

# Clear marker after rebuild
if ($Command -match 'rebuild\.ps1') {
    Remove-Item "./.claude-code/cs-changes.marker" -ErrorAction SilentlyContinue
    Write-Host "✅ Rebuild completed - tracking cleared" -ForegroundColor Green
}