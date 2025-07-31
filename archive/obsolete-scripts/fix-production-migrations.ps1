# Fix production by deploying updated code that skips migrations with Managed Identity

Write-Host "Building application..."
dotnet publish SteelEstimation.Web\SteelEstimation.Web.csproj -c Release -o publish

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deploying to production..."
    
    # Deploy to production
    az webapp deployment source config-zip `
        --resource-group "NWIApps" `
        --name "app-steel-estimation-prod" `
        --src "publish.zip"
    
    Write-Host "Restarting production app..."
    az webapp restart --resource-group "NWIApps" --name "app-steel-estimation-prod"
    
    Write-Host "Production deployment complete!"
    Write-Host "The app now skips migrations when using Managed Identity"
} else {
    Write-Host "Build failed!" -ForegroundColor Red
}