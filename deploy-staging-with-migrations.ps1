# Enhanced staging deployment script with migration support
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging",
    [switch]$SkipMigrations,
    [switch]$UseSqlAuth,
    [string]$SqlUsername = "sqladmin",
    [SecureString]$SqlPassword
)

Write-Host "Starting deployment to STAGING/SANDBOX environment..." -ForegroundColor Yellow
Write-Host "This will deploy to the staging slot, not production!" -ForegroundColor Yellow

# Confirm deployment
$confirm = Read-Host "Are you sure you want to deploy to STAGING? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Red
    exit 0
}

# 1. Build and publish
Write-Host "`nBuilding application..." -ForegroundColor Yellow
dotnet build ./SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# 2. Apply migrations if not skipped
if (-not $SkipMigrations) {
    Write-Host "`nApplying database migrations..." -ForegroundColor Yellow
    
    # Set environment to staging
    $env:ASPNETCORE_ENVIRONMENT = "Staging"
    
    # Check for pending migrations
    $pendingMigrations = dotnet ef migrations list `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext | Select-String "(pending)"
    
    if ($pendingMigrations) {
        Write-Host "Pending migrations found. Applying..." -ForegroundColor Cyan
        
        if ($UseSqlAuth) {
            if (-not $SqlPassword) {
                $SqlPassword = Read-Host "Enter SQL Password" -AsSecureString
            }
            $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
            
            $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            
            dotnet ef database update `
                --project SteelEstimation.Infrastructure `
                --startup-project SteelEstimation.Web `
                --context ApplicationDbContext `
                --connection $connectionString
        } else {
            dotnet ef database update `
                --project SteelEstimation.Infrastructure `
                --startup-project SteelEstimation.Web `
                --context ApplicationDbContext
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Migration failed! Use -UseSqlAuth if you're having authentication issues."
            exit 1
        }
        
        Write-Host "Migrations applied successfully!" -ForegroundColor Green
    } else {
        Write-Host "No pending migrations." -ForegroundColor Green
    }
} else {
    Write-Host "`nSkipping migrations (use -SkipMigrations:$false to apply)" -ForegroundColor Yellow
}

# 3. Publish application
$publishFolder = "./publish-staging"
if (Test-Path $publishFolder) {
    Remove-Item $publishFolder -Recurse -Force
}

Write-Host "`nPublishing application for staging..." -ForegroundColor Yellow
dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj `
    --configuration Release `
    --output $publishFolder `
    --runtime win-x64 `
    --self-contained false

if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed!"
    exit 1
}

# 4. Create deployment package
Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
$zipPath = "./deploy-staging.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($publishFolder, $zipPath)

# 5. Deploy to Azure
try {
    Write-Host "`nChecking Azure login..." -ForegroundColor Yellow
    $account = Get-AzContext
    if (-not $account) {
        Write-Host "Not logged in to Azure. Please login." -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    Write-Host "`nDeploying to Azure staging slot..." -ForegroundColor Yellow
    
    # Ensure staging slot exists
    $slot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName -ErrorAction SilentlyContinue
    if (-not $slot) {
        Write-Host "Creating staging slot..." -ForegroundColor Yellow
        New-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
    }
    
    # Deploy package
    Publish-AzWebApp `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServiceName `
        -Slot $SlotName `
        -ArchivePath $zipPath `
        -Force
    
    # Set environment variables
    Write-Host "Setting environment variables..." -ForegroundColor Yellow
    $appSettings = @{
        "ASPNETCORE_ENVIRONMENT" = "Staging"
        "Environment:Name" = "Staging"
    }
    
    Set-AzWebAppSlot `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServiceName `
        -Slot $SlotName `
        -AppSettings $appSettings
    
    # Restart the slot
    Write-Host "Restarting staging slot..." -ForegroundColor Yellow
    Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
    
    # Clean up
    Remove-Item $zipPath -Force
    
    # Wait for restart
    Write-Host "Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # 6. Test staging
    $stagingUrl = "https://$AppServiceName-$SlotName.azurewebsites.net"
    Write-Host "`nTesting staging application..." -ForegroundColor Yellow
    Write-Host "URL: $stagingUrl" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $stagingUrl -UseBasicParsing -TimeoutSec 30
        Write-Host "Success! Staging returned: $($response.StatusCode)" -ForegroundColor Green
        
        # Test database connectivity
        Write-Host "`nTesting database connectivity..." -ForegroundColor Yellow
        try {
            $dbTestResponse = Invoke-WebRequest -Uri "$stagingUrl/dbtest" -UseBasicParsing -TimeoutSec 30
            Write-Host "Database test page accessible" -ForegroundColor Green
        } catch {
            Write-Host "Database test page not accessible (might require authentication)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Staging test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check the Log Stream in Azure Portal for details" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Deployment failed: $_"
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $publishFolder -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Staging Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Staging URL: https://$AppServiceName-$SlotName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Database Test: https://$AppServiceName-$SlotName.azurewebsites.net/dbtest" -ForegroundColor Cyan
Write-Host "Auth Test: https://$AppServiceName-$SlotName.azurewebsites.net/authtest" -ForegroundColor Cyan
Write-Host "`nTo swap staging to production later, run:" -ForegroundColor Yellow
Write-Host "Switch-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -SourceSlotName $SlotName -DestinationSlotName 'production'" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan