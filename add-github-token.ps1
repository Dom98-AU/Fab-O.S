# Add GitHub token to Azure App Service settings
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

Write-Host "Adding GitHub token to production app settings..."

# Add GitHub settings to production
az webapp config appsettings set `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --settings "GitHub:AccessToken=$GitHubToken" "GitHub:RepoOwner=Dom98-AU" "GitHub:RepoName=Steel-Estimation-Platform"

Write-Host "Adding GitHub token to staging app settings..."

# Add GitHub settings to staging slot
az webapp config appsettings set `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --slot "staging" `
    --settings "GitHub:AccessToken=$GitHubToken" "GitHub:RepoOwner=Dom98-AU" "GitHub:RepoName=Steel-Estimation-Platform"

Write-Host "GitHub token configured successfully!"
Write-Host "You can now use the deployment management UI at:"
Write-Host "  Production: https://app-steel-estimation-prod.azurewebsites.net/admin/deployment"
Write-Host "  Staging: https://app-steel-estimation-prod-staging.azurewebsites.net/admin/deployment"