#!/usr/bin/env pwsh
Write-Host "Testing Claude Code Hooks Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test 1: Check if settings file exists
Write-Host "`nTest 1: Checking for hook configuration files..."
$projectSettings = "./.claude-code-project/settings.json"
$userSettings = "$env:USERPROFILE\.claude-code\settings.json"

if (Test-Path $projectSettings) {
    Write-Host "✅ Project settings found: $projectSettings" -ForegroundColor Green
} else {
    Write-Host "❌ Project settings not found" -ForegroundColor Red
}

# Test 2: Simulate a C# file change
Write-Host "`nTest 2: Simulating C# file change..."
& powershell.exe ./.claude-code/track-changes.ps1 -FilePath "Test.cs"

# Test 3: Check if marker was created
if (Test-Path "./.claude-code/cs-changes.marker") {
    Write-Host "✅ Change tracking marker created" -ForegroundColor Green
} else {
    Write-Host "❌ Marker not created" -ForegroundColor Red
}

# Test 4: Simulate docker-compose restart attempt
Write-Host "`nTest 4: Testing docker-compose restart warning..."
if (Test-Path "./.claude-code/cs-changes.marker") {
    Write-Host "❌ STOP! You have C# changes - use .\rebuild.ps1 instead!" -ForegroundColor Red
} else {
    Write-Host "✅ No C# changes - docker-compose restart is OK" -ForegroundColor Green
}

# Cleanup
Remove-Item "./.claude-code/cs-changes.marker" -ErrorAction SilentlyContinue

Write-Host "`n✅ Hook system test complete!" -ForegroundColor Green