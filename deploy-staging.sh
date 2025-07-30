#!/bin/bash

echo "Starting manual deployment to staging..."

# Build the project
echo "Building project..."
dotnet publish SteelEstimation.Web/SteelEstimation.Web.csproj -c Release -o ./publish

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create deployment package
echo "Creating deployment package..."
cd publish
zip -r ../deploy.zip .
cd ..

# Get file size
FILESIZE=$(stat -c%s "deploy.zip")
echo "Deployment package size: $((FILESIZE / 1024 / 1024)) MB"

# Deploy to Azure
echo "Deploying to Azure staging slot..."
az webapp deployment source config-zip \
    --resource-group rg-steel-estimation \
    --name app-steel-estimation-prod \
    --slot staging \
    --src deploy.zip

# Check deployment status
if [ $? -eq 0 ]; then
    echo "Deployment successful!"
    echo "Your app should be available at: https://app-steel-estimation-prod-staging.azurewebsites.net"
    echo ""
    echo "Test these URLs:"
    echo "  - Homepage: https://app-steel-estimation-prod-staging.azurewebsites.net"
    echo "  - Login: https://app-steel-estimation-prod-staging.azurewebsites.net/login"
    echo "  - Diagnostic: https://app-steel-estimation-prod-staging.azurewebsites.net/diagnostic"
else
    echo "Deployment failed!"
    exit 1
fi

# Clean up
echo "Cleaning up..."
rm -f deploy.zip
rm -rf publish

echo "Done!"