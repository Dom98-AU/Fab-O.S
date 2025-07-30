#!/bin/bash

echo "Restoring production to working state..."

# Clear problematic settings
az webapp config appsettings set --resource-group "NWIApps" --name "app-steel-estimation-prod" \
  --settings ASPNETCORE_ENVIRONMENT=Production

# Remove startup command that might be causing issues
az webapp config set --resource-group "NWIApps" --name "app-steel-estimation-prod" \
  --startup-file ""

# Restart
az webapp restart --resource-group "NWIApps" --name "app-steel-estimation-prod"

echo "Production restored. Please redeploy the previous working version."