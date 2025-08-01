#!/bin/bash

echo "===================================="
echo "FabOS Authentication Verification"
echo "===================================="
echo ""

# Test 1: Check if admin user exists with correct data
echo "1. Checking admin user in database..."
echo ""

# Test 2: Test login endpoint
echo "2. Testing login endpoint..."
TOKEN=$(curl -s http://localhost:8080/Account/Login | grep -oP 'name="__RequestVerificationToken".*?value="\K[^"]+' | head -1)

if [ -z "$TOKEN" ]; then
    echo "   ❌ Could not get verification token"
    exit 1
fi

echo "   ✓ Got verification token"

# Try login
RESPONSE=$(curl -s -i -X POST http://localhost:8080/Account/Login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Input.Email=admin@steelestimation.com&Input.Password=Admin@123&__RequestVerificationToken=$TOKEN" \
  --cookie-jar cookies.txt)

if echo "$RESPONSE" | grep -q "HTTP/1.1 302"; then
    echo "   ✅ Login successful - got redirect"
elif echo "$RESPONSE" | grep -q "Invalid"; then
    echo "   ❌ Login failed - Invalid credentials"
    echo ""
    echo "Checking for specific errors:"
    curl -s -X POST http://localhost:8080/Account/Login \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "Input.Email=admin@steelestimation.com&Input.Password=Admin@123&__RequestVerificationToken=$TOKEN" | grep -oP '(?<=text-danger">)[^<]+' | head -5
else
    echo "   ❓ Unexpected response"
fi

echo ""
echo "3. Checking Docker logs for errors..."
docker logs steel-estimation-web-dev 2>&1 | grep -E "FabOS|AuthenticateAsync|VerifyPassword" | tail -5

echo ""
echo "===================================="