#!/bin/bash

echo "Deploying to staging with Azure build service..."

# Create a zip of source files
echo "Creating source package..."

# Create temp directory
TEMP_DIR="/tmp/steel-deploy-$$"
mkdir -p "$TEMP_DIR"

# Copy essential files
cp -r SteelEstimation.Web "$TEMP_DIR/"
cp -r SteelEstimation.Core "$TEMP_DIR/"
cp -r SteelEstimation.Infrastructure "$TEMP_DIR/"
cp SteelEstimation.sln "$TEMP_DIR/"
cp .deployment "$TEMP_DIR/"

# Create deployment package
cd "$TEMP_DIR"
zip -r deploy-source.zip . -q

# Get file size
SIZE=$(stat -c%s deploy-source.zip)
echo "Package size: $((SIZE / 1024 / 1024)) MB"

# Deploy using Azure CLI
echo "Deploying to staging slot..."
az webapp deployment source config-zip \
    --resource-group "NWIApps" \
    --name "app-steel-estimation-prod" \
    --slot "staging" \
    --src deploy-source.zip

# Clean up
cd -
rm -rf "$TEMP_DIR"

echo "Deployment initiated. Azure will build and deploy the application."
echo "This may take 5-10 minutes..."

# Wait a bit
sleep 30

# Check status
echo -e "\nChecking deployment status..."
az webapp log deployment list \
    --resource-group "NWIApps" \
    --name "app-steel-estimation-prod" \
    --slot "staging" \
    --query "[0].{status:status, message:message, time:end_time}" \
    -o json