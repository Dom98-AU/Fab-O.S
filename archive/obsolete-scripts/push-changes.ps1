# Push changes to GitHub to trigger deployment
Write-Host "Pushing changes to GitHub..." -ForegroundColor Green

# First, check if we need to commit the deployment script
git add deploy-simple.ps1 2>$null
git commit -m "Add deployment script" 2>$null

# Push to GitHub
Write-Host "Pushing to origin/develop..." -ForegroundColor Yellow
git push origin develop

if ($LASTEXITCODE -eq 0) {
    Write-Host "Push successful! Deployment should start automatically." -ForegroundColor Green
    Write-Host "Check deployment status at: https://github.com/Dom98-AU/Steel-Estimation-Platform/actions" -ForegroundColor Cyan
} else {
    Write-Host "Push failed. You may need to authenticate with GitHub." -ForegroundColor Red
    Write-Host "Try running: git push origin develop" -ForegroundColor Yellow
}