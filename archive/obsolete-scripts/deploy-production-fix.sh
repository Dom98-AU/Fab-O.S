#!/bin/bash

echo "Building updated application with migration fix..."

# Navigate to project directory
cd "/mnt/c/Steel Estimation Platform/SteelEstimation"

# Clean previous build
rm -rf publish-fixed/

# Build with updated Program.cs
dotnet publish SteelEstimation.Web/SteelEstimation.Web.csproj -c Release -o publish-fixed

if [ $? -eq 0 ]; then
    echo "Build successful. Creating deployment archive..."
    
    # Create tar archive
    tar -czf production-fix-new.tar.gz -C publish-fixed .
    
    echo "Deploying to production..."
    
    # Deploy using Azure CLI
    az webapp deployment source config-zip \
        --resource-group "NWIApps" \
        --name "app-steel-estimation-prod" \
        --src "production-fix-new.tar.gz"
    
    echo "Restarting production app..."
    az webapp restart --resource-group "NWIApps" --name "app-steel-estimation-prod"
    
    echo "Deployment complete!"
    echo "Production should be working with Managed Identity in about 60 seconds"
    
else
    echo "Build failed! Please check the build errors above."
    exit 1
fi