#!/bin/bash

echo "Diagnosing Staging Environment Issues"
echo "===================================="

# Check if the app is running
echo -e "\n1. Checking if app is responding..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://app-steel-estimation-prod-staging.azurewebsites.net)
echo "HTTP Response Code: $HTTP_CODE"

# Check app settings
echo -e "\n2. Checking app settings..."
az webapp config appsettings list --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --query "[].{name:name, value:value}" -o table | head -20

# Check connection string
echo -e "\n3. Checking connection string..."
az webapp config connection-string list --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --query "[0].{name:name, type:type}" -o table

# Check runtime configuration
echo -e "\n4. Checking runtime configuration..."
az webapp config show --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --query "{netFrameworkVersion:netFrameworkVersion, windowsFxVersion:windowsFxVersion, use32BitWorkerProcess:use32BitWorkerProcess}" -o table

# Get deployment log URL
echo -e "\n5. Latest deployment info..."
az webapp log deployment show --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --deployment-id latest --query "{status:status, message:message, endTime:end_time}" -o table

echo -e "\nDiagnosis complete!"