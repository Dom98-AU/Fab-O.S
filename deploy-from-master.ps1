# Deploy from master branch to production environment
param(
    [switch]$SkipBuild,
    [switch]$Force
)

Write-Host "=== Deploying from 'master' branch to PRODUCTION ===" -ForegroundColor Red
Write-Host "⚠️  WARNING: This will deploy directly to production!" -ForegroundColor Yellow

# Ensure we're on master branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "master") {
    Write-Host "ERROR: You must be on the 'master' branch to deploy to production" -ForegroundColor Red
    Write-Host "Current branch: $currentBranch" -ForegroundColor Red
    Write-Host "Run: git checkout master" -ForegroundColor Yellow
    exit 1
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "ERROR: You have uncommitted changes:" -ForegroundColor Red
    git status --short
    Write-Host "Commit or stash your changes before deploying to production" -ForegroundColor Red
    exit 1
}

# Confirm production deployment
if (-not $Force) {
    Write-Host ""
    Write-Host "You are about to deploy to PRODUCTION" -ForegroundColor Red
    Write-Host "This will affect all users immediately" -ForegroundColor Yellow
    Write-Host ""
    $confirmText = "DEPLOY TO PRODUCTION"
    Write-Host "Type '$confirmText' to continue: " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    
    if ($response -ne $confirmText) {
        Write-Host "Deployment cancelled" -ForegroundColor Green
        exit 0
    }
}

# Pull latest changes
Write-Host "Pulling latest changes from origin/master..." -ForegroundColor Cyan
git pull origin master

# Show what will be deployed
Write-Host ""
Write-Host "Commits to be deployed:" -ForegroundColor Cyan
git log --oneline -10

if (-not $SkipBuild) {
    # Build the application
    Write-Host ""
    Write-Host "Building application..." -ForegroundColor Cyan
    dotnet publish SteelEstimation.Web\SteelEstimation.Web.csproj -c Release -o publish-prod
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Cyan
if (Test-Path "production-deploy.zip") {
    Remove-Item "production-deploy.zip"
}

# Create zip using PowerShell
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory("publish-prod", "production-deploy.zip")

# Deploy to production
Write-Host "Deploying to production..." -ForegroundColor Red
az webapp deployment source config-zip `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --src "production-deploy.zip"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Production deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Production URL: https://app-steel-estimation-prod.azurewebsites.net" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Post-deployment checklist:" -ForegroundColor Yellow
    Write-Host "□ Check application health endpoint"
    Write-Host "□ Test critical user flows"
    Write-Host "□ Monitor error logs"
    Write-Host "□ Verify database connectivity"
    Write-Host ""
    Write-Host "If issues occur, run: .\swap-slots.ps1 (to rollback)" -ForegroundColor Yellow
} else {
    Write-Host "✗ Production deployment failed!" -ForegroundColor Red
    Write-Host "Check the logs and try again" -ForegroundColor Yellow
}