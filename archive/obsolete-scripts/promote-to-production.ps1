# Promote develop branch to master and deploy to production
param(
    [switch]$SkipTests,
    [switch]$SwapSlots
)

Write-Host "=== Promote Develop to Production ===" -ForegroundColor Yellow
Write-Host ""

# Step 1: Check current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Step 2: Ensure working directory is clean
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "ERROR: You have uncommitted changes:" -ForegroundColor Red
    git status --short
    Write-Host "Commit or stash changes before promoting to production" -ForegroundColor Red
    exit 1
}

# Step 3: Show what will be promoted
Write-Host ""
Write-Host "Changes to be promoted from develop to master:" -ForegroundColor Cyan
git log master..develop --oneline

$commitCount = (git rev-list --count master..develop)
if ($commitCount -eq 0) {
    Write-Host "No new commits to promote" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Total commits to promote: $commitCount" -ForegroundColor Yellow

# Step 4: Run tests (unless skipped)
if (-not $SkipTests) {
    Write-Host ""
    Write-Host "Running tests..." -ForegroundColor Cyan
    dotnet test
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Tests failed! Fix issues before promoting to production" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Confirm promotion
Write-Host ""
Write-Host "⚠️  You are about to promote $commitCount commits to PRODUCTION" -ForegroundColor Red
Write-Host ""
$response = Read-Host "Continue with promotion? (y/N)"
if ($response -ne 'y') {
    Write-Host "Promotion cancelled" -ForegroundColor Yellow
    exit 0
}

# Step 6: Checkout master and merge develop
Write-Host ""
Write-Host "Checking out master branch..." -ForegroundColor Cyan
git checkout master

Write-Host "Pulling latest master..." -ForegroundColor Cyan
git pull origin master

Write-Host "Merging develop into master..." -ForegroundColor Cyan
git merge develop --no-ff -m "Promote develop to production: $commitCount commits"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Merge failed! Resolve conflicts and try again" -ForegroundColor Red
    exit 1
}

# Step 7: Push to origin
Write-Host ""
Write-Host "Pushing to origin/master..." -ForegroundColor Cyan
git push origin master

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed! Check your credentials and try again" -ForegroundColor Red
    exit 1
}

# Step 8: Deploy or swap slots
if ($SwapSlots) {
    Write-Host ""
    Write-Host "Swapping staging and production slots..." -ForegroundColor Cyan
    az webapp deployment slot swap `
        --resource-group "NWIApps" `
        --name "app-steel-estimation-prod" `
        --slot "staging"
        
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Slot swap successful!" -ForegroundColor Green
    } else {
        Write-Host "✗ Slot swap failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Deploying to production..." -ForegroundColor Cyan
    & ".\deploy-from-master.ps1" -Force
}

# Step 9: Tag the release
$version = Read-Host "Enter version tag (e.g., v1.2.0) or press Enter to skip"
if ($version) {
    git tag -a $version -m "Release $version"
    git push origin $version
    Write-Host "Tagged release: $version" -ForegroundColor Green
}

# Step 10: Switch back to develop
Write-Host ""
Write-Host "Switching back to develop branch..." -ForegroundColor Cyan
git checkout develop

Write-Host ""
Write-Host "✓ Promotion complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Production URL: https://app-steel-estimation-prod.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Monitor production for issues"
Write-Host "2. Check application health"
Write-Host "3. Continue development on develop branch"