#!/bin/bash

echo "Simple staging deployment script"
echo "================================"

# Get deployment credentials
echo "Getting deployment credentials..."
USERNAME=$(az webapp deployment list-publishing-credentials \
    --resource-group "NWIApps" \
    --name "app-steel-estimation-prod" \
    --slot "staging" \
    --query "publishingUserName" -o tsv)

PASSWORD=$(az webapp deployment list-publishing-credentials \
    --resource-group "NWIApps" \
    --name "app-steel-estimation-prod" \
    --slot "staging" \
    --query "publishingPassword" -o tsv)

echo "Username: $USERNAME"

# Check Kudu
echo -e "\nChecking Kudu API..."
HTTP_CODE=$(curl -k -u "$USERNAME:$PASSWORD" \
    "https://app-steel-estimation-prod-staging.scm.azurewebsites.net/api/environment" \
    -o /dev/null -s -w "%{http_code}")

echo "Kudu API response: $HTTP_CODE"

if [ "$HTTP_CODE" == "200" ]; then
    echo "Kudu API is accessible!"
    
    # Get current runtime
    echo -e "\nChecking runtime info..."
    curl -k -u "$USERNAME:$PASSWORD" \
        "https://app-steel-estimation-prod-staging.scm.azurewebsites.net/api/diagnostics/runtime" \
        2>/dev/null | head -20
else
    echo "Kudu API is not accessible. Response code: $HTTP_CODE"
fi

# Check deployment status
echo -e "\n\nChecking recent deployments..."
az webapp log deployment list \
    --resource-group "NWIApps" \
    --name "app-steel-estimation-prod" \
    --slot "staging" \
    --query "[0:3].{id:id, status:status, message:message, time:end_time}" \
    -o table

echo -e "\nDone!"