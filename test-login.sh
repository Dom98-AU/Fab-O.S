#\!/bin/bash

echo "Testing Steel Estimation Platform Login..."

# Get login page and extract token
TOKEN=$(curl -s http://localhost:8080/Account/Login | grep -oP 'name="__RequestVerificationToken".*?value="\K[^"]+')

if [ -z "$TOKEN" ]; then
    echo "❌ Could not find verification token"
    exit 1
fi

echo "✅ Found verification token"

# Submit login form
RESPONSE=$(curl -s -i -X POST http://localhost:8080/Account/Login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Input.Email=admin@steelestimation.com" \
  -d "Input.Password=Admin@123" \
  -d "Input.RememberMe=false" \
  -d "__RequestVerificationToken=$TOKEN" \
  --cookie-jar cookies.txt)

# Check response
if echo "$RESPONSE" | grep -q "Location:"; then
    echo "✅ Login successful - received redirect"
    LOCATION=$(echo "$RESPONSE" | grep -oP 'Location: \K[^\r]+')
    echo "   Redirecting to: $LOCATION"
else
    echo "❌ Login failed"
fi

# Test authenticated access
echo ""
echo "Testing authenticated endpoints..."
curl -s -b cookies.txt http://localhost:8080/Projects -o /dev/null -w "Projects: %{http_code}\n"
curl -s -b cookies.txt http://localhost:8080/Customers -o /dev/null -w "Customers: %{http_code}\n"

echo ""
echo "✅ Test completed\!"
