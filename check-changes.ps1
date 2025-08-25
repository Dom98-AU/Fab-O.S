#!/usr/bin/env pwsh
# Detects what type of changes were made and suggests the correct action

$csChanges = git diff --name-only HEAD | Where-Object { $_ -match '\.(cs|razor|cshtml|csproj)$' }
$staticChanges = git diff --name-only HEAD | Where-Object { $_ -match '\.(css|js|html|png|jpg|svg)$' }

Write-Host "`n📋 CHANGE DETECTION REPORT" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if ($csChanges) {
    Write-Host "`n⚠️  C#/Razor Changes Detected:" -ForegroundColor Yellow
    $csChanges | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    
    Write-Host "`n🔧 REQUIRED ACTION:" -ForegroundColor Red
    Write-Host "   Run: .\rebuild.ps1" -ForegroundColor Green
    Write-Host "   This will clear all Docker cache and rebuild from scratch" -ForegroundColor Gray
    
    # Offer to run it automatically
    $response = Read-Host "`nRun rebuild.ps1 now? (y/n)"
    if ($response -eq 'y') {
        & .\rebuild.ps1
    }
}
elseif ($staticChanges) {
    Write-Host "`n✅ Only Static File Changes Detected:" -ForegroundColor Green
    $staticChanges | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    
    Write-Host "`n🔧 REQUIRED ACTION:" -ForegroundColor Yellow
    Write-Host "   Run: docker-compose restart web" -ForegroundColor Green
    Write-Host "   Volume mounts will handle these changes" -ForegroundColor Gray
    
    # Offer to run it automatically
    $response = Read-Host "`nRestart container now? (y/n)"
    if ($response -eq 'y') {
        docker-compose restart web
    }
}
else {
    Write-Host "`n✅ No uncommitted changes detected" -ForegroundColor Green
    Write-Host "   If you've already committed, check git log for recent changes" -ForegroundColor Gray
}

Write-Host "`n📖 Quick Reference:" -ForegroundColor Cyan
Write-Host "   Static files (CSS/JS) → docker-compose restart web" -ForegroundColor Gray
Write-Host "   C#/Razor files       → .\rebuild.ps1" -ForegroundColor Gray
Write-Host "   Database changes     → .\run-migration.ps1`n" -ForegroundColor Gray