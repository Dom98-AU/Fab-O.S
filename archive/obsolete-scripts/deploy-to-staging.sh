#!/bin/bash

# Deploy to Azure App Service Staging Slot using Kudu API
# This script works around the limitations of not having dotnet CLI

RESOURCE_GROUP="NWIApps"
APP_NAME="app-steel-estimation-prod"
SLOT_NAME="staging"

echo "Deploying to staging slot..."

# Get publishing credentials
echo "Getting deployment credentials..."
CREDS=$(az webapp deployment list-publishing-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --slot "$SLOT_NAME" \
    --query "{username:publishingUserName, password:publishingPassword}" \
    -o json)

USERNAME=$(echo $CREDS | jq -r '.username')
PASSWORD=$(echo $CREDS | jq -r '.password')

if [ -z "$USERNAME" ] || [ "$USERNAME" == "null" ]; then
    echo "Failed to get deployment credentials"
    exit 1
fi

# Deploy using Kudu REST API
KUDU_URL="https://${APP_NAME}-${SLOT_NAME}.scm.azurewebsites.net"

# First, let's check if Kudu is accessible
echo "Checking Kudu accessibility..."
curl -k -u "$USERNAME:$PASSWORD" \
    "${KUDU_URL}/api/environment" \
    -o /dev/null -s -w "%{http_code}\n"

# Try to trigger a sync from repository
echo "Attempting repository sync..."
curl -k -X POST -u "$USERNAME:$PASSWORD" \
    "${KUDU_URL}/api/sync" \
    -H "Content-Type: application/json" \
    -d "{}"

echo "Deployment initiated. Check the Azure portal for status."