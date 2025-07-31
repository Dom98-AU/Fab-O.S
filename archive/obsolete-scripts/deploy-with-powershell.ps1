# Deploy to Azure using PowerShell Az module
Write-Host "Checking for Azure PowerShell module..." -ForegroundColor Green

# Check if Az module is installed
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Host "Azure PowerShell module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
}

# Variables
$resourceGroup = "NWIApps"
$appServiceName = "app-steel-estimation-prod"
$publishFolder = "./publish"

# Login to Azure
Write-Host "Please login to Azure..." -ForegroundColor Green
Connect-AzAccount

# Set subscription (if you have multiple)
# Set-AzContext -SubscriptionId "your-subscription-id"

Write-Host "Building and publishing application..." -ForegroundColor Green

# Build and publish
dotnet build --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

dotnet publish --configuration Release --output $publishFolder
if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed!"
    exit 1
}

Write-Host "Creating deployment package..." -ForegroundColor Green

# Create zip file
$zipPath = "deploy.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}
Compress-Archive -Path "$publishFolder\*" -DestinationPath $zipPath

Write-Host "Deploying to Azure App Service..." -ForegroundColor Green

# Deploy to App Service
try {
    # Get publishing profile
    $publishingProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $resourceGroup -Name $appServiceName -OutputFile "publish.xml"
    
    # Deploy using Kudu ZIP Deploy API
    $webApp = Get-AzWebApp -ResourceGroupName $resourceGroup -Name $appServiceName
    $username = $webApp.PublishingUserName
    $password = $webApp.PublishingPassword
    
    # Upload using WebClient
    $apiUrl = "https://${appServiceName}.scm.azurewebsites.net/api/zipdeploy"
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Basic $base64Auth")
    
    Write-Host "Uploading deployment package..." -ForegroundColor Yellow
    $webClient.UploadFile($apiUrl, "PUT", $zipPath)
    
    Write-Host "Deployment successful!" -ForegroundColor Green
    Write-Host "Application URL: https://${appServiceName}.azurewebsites.net" -ForegroundColor Cyan
    
    # Clean up
    Remove-Item $zipPath
    Remove-Item "publish.xml"
    
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host "`nDeployment complete! Your application should be running at:" -ForegroundColor Green
Write-Host "https://${appServiceName}.azurewebsites.net" -ForegroundColor Cyan