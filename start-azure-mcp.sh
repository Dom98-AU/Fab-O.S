#!/bin/bash
# Azure MCP Server starter script with authentication

# Set Azure credentials as environment variables
export AZURE_SUBSCRIPTION_ID="8b10df28-e826-4de8-b929-4d5698853b5d"
export AZURE_TENANT_ID="0dc6b780-5b9e-4809-afb6-6bc499280f23"
export AZURE_CLIENT_ID="7e7da08a-c540-4e2c-97d5-ab954970484f"
export AZURE_CLIENT_SECRET="zqR8Q~3fnNUgSKk1o8vTU9ToFvrVa9jyk~c5Lc2s"

# Set Azure credential file location
export AZURE_CREDENTIALS_FILE="/mnt/c/Fab O.S/.azure/credentials"

# Start the Azure MCP server
exec npx @azure/mcp@latest server start --subscription-id "$AZURE_SUBSCRIPTION_ID"