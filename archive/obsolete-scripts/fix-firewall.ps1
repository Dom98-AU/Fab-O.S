# Fix Windows Firewall for local development
Write-Host "Fixing Windows Firewall for Steel Estimation Platform..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script must be run as Administrator to modify firewall rules." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Add firewall rules for dotnet.exe
Write-Host "`nAdding firewall rules for dotnet.exe..." -ForegroundColor Yellow

# Remove existing rules if any
Remove-NetFirewallRule -DisplayName "Steel Estimation - Dotnet Core" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Steel Estimation - HTTP" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Steel Estimation - HTTPS" -ErrorAction SilentlyContinue

# Add new rules
New-NetFirewallRule -DisplayName "Steel Estimation - Dotnet Core" `
    -Direction Inbound `
    -Program "C:\Program Files\dotnet\dotnet.exe" `
    -Action Allow `
    -Protocol TCP

New-NetFirewallRule -DisplayName "Steel Estimation - HTTP" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5000 `
    -Action Allow

New-NetFirewallRule -DisplayName "Steel Estimation - HTTPS" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5001 `
    -Action Allow

Write-Host "Firewall rules added successfully!" -ForegroundColor Green

# Check localhost binding
Write-Host "`nChecking localhost configuration..." -ForegroundColor Yellow
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile -Raw

if ($hostsContent -match "127\.0\.0\.1\s+localhost") {
    Write-Host "Localhost is properly configured in hosts file." -ForegroundColor Green
} else {
    Write-Host "Adding localhost to hosts file..." -ForegroundColor Yellow
    Add-Content -Path $hostsFile -Value "`n127.0.0.1       localhost"
    Write-Host "Localhost added to hosts file." -ForegroundColor Green
}

Write-Host "`n=== Firewall Configuration Complete ===" -ForegroundColor Cyan
Write-Host "Please restart your browser and try accessing:" -ForegroundColor Yellow
Write-Host "http://localhost:5000" -ForegroundColor White
Write-Host "`nIf still having issues, try:" -ForegroundColor Yellow
Write-Host "1. Use 127.0.0.1:5000 instead of localhost:5000" -ForegroundColor White
Write-Host "2. Try a different browser (Edge, Chrome)" -ForegroundColor White
Write-Host "3. Disable any VPN or proxy software" -ForegroundColor White