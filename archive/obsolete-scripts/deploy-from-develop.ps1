# Deploy from develop branch to sandbox/staging environment
param(
    [switch]$SkipBuild
)

Write-Host "=== Deploying from 'develop' branch to Sandbox/Staging ===" -ForegroundColor Yellow

# Ensure we're on develop branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "develop") {
    Write-Host "ERROR: You must be on the 'develop' branch to deploy to sandbox" -ForegroundColor Red
    Write-Host "Current branch: $currentBranch" -ForegroundColor Red
    Write-Host "Run: git checkout develop" -ForegroundColor Yellow
    exit 1
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "WARNING: You have uncommitted changes:" -ForegroundColor Yellow
    git status --short
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y') {
        exit 1
    }
}

# Pull latest changes
Write-Host "Pulling latest changes from origin/develop..." -ForegroundColor Cyan
git pull origin develop

if (-not $SkipBuild) {
    # Build the application
    Write-Host "Building application..." -ForegroundColor Cyan
    dotnet publish SteelEstimation.Web\SteelEstimation.Web.csproj -c Release -o publish
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Cyan
if (Test-Path "staging-deploy.zip") {
    Remove-Item "staging-deploy.zip"
}

# Create zip using PowerShell
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory("publish", "staging-deploy.zip")

# Deploy to staging slot
Write-Host "Deploying to staging slot..." -ForegroundColor Cyan
az webapp deployment source config-zip `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --slot "staging" `
    --src "staging-deploy.zip"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Sandbox URL: https://app-steel-estimation-prod-staging.azurewebsites.net" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Test the sandbox environment thoroughly"
    Write-Host "2. When ready to promote to production, run: .\promote-to-production.ps1"
} else {
    Write-Host "✗ Deployment failed!" -ForegroundColor Red
}