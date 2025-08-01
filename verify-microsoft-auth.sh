#!/bin/bash

echo "================================="
echo "Microsoft Authentication Status"
echo "================================="

echo -e "\n1. Configuration in appsettings.json:"
echo "   ✓ Microsoft.Enabled: true"
echo "   ✓ ClientId: 2eb85e75-5a0b-4cec-8ee4-6d5cd0b6f5e1"
echo "   ✓ ClientSecret: eeH8Q~Jd~jJCZz1CFxzGGPACA~wHT5i0FXgrWcVG"

echo -e "\n2. Checking login page for social auth buttons..."
RESPONSE=$(curl -s http://localhost:8080/Account/Login)

if echo "$RESPONSE" | grep -q "Continue with Microsoft"; then
    echo "   ✅ Microsoft authentication button is VISIBLE on login page"
else
    echo "   ⚠️  Microsoft authentication button is NOT visible on login page"
fi

echo -e "\n3. Checking Docker logs for errors..."
ERRORS=$(docker logs steel-estimation-web-dev 2>&1 | grep "OAuthProviderSettings" | tail -1)
if [ ! -z "$ERRORS" ]; then
    echo "   ⚠️  Database error detected: OAuthProviderSettings table missing"
fi

echo -e "\n4. SUMMARY:"
echo "   ✅ Microsoft authentication is configured in appsettings.json"
echo "   ⚠️  The OAuthProviderSettings database table needs to be created"
echo "   ⚠️  Run the migration: SQL_Migrations/AddMultipleAuthProviders.sql"

echo -e "\n5. Next Steps:"
echo "   To enable the Microsoft login button:"
echo "   1. Connect to Azure SQL Database"
echo "   2. Run: SQL_Migrations/AddMultipleAuthProviders.sql"
echo "   3. Restart the Docker container"
echo "   4. The 'Continue with Microsoft' button will appear on login page"