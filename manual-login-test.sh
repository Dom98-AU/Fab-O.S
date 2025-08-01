#!/bin/bash
echo "Testing login..."
curl -s http://localhost:8080/Account/Login | grep -c "Continue with Microsoft"