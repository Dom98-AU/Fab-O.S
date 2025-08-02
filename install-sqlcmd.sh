#!/bin/bash
# Install sqlcmd on Ubuntu 24.04 LTS
# Run this script with: sudo bash install-sqlcmd.sh

echo "=== Installing SQL Server Command Line Tools (sqlcmd) on Ubuntu 24.04 ==="
echo ""

# Update package list
echo "1. Updating package list..."
apt-get update

# Install curl if not present
echo "2. Installing required dependencies..."
apt-get install -y curl apt-transport-https

# Add Microsoft GPG key
echo "3. Adding Microsoft GPG key..."
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Add Microsoft repository for Ubuntu 24.04
# Note: Microsoft might not have specific repo for 24.04 yet, so we'll use 22.04
echo "4. Adding Microsoft SQL Server repository..."
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Update package list again
echo "5. Updating package list with Microsoft repository..."
apt-get update

# Install SQL Server command-line tools
echo "6. Installing mssql-tools18 and unixODBC developer..."
ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

# Add tools to PATH (optional - for current session)
echo "7. Adding sqlcmd to PATH..."
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "To use sqlcmd immediately, run:"
echo "  export PATH=\"\$PATH:/opt/mssql-tools18/bin\""
echo ""
echo "Or restart your terminal session to load the PATH automatically."
echo ""
echo "Test sqlcmd with:"
echo "  sqlcmd -?"
echo ""
echo "Note: sqlcmd is now installed at /opt/mssql-tools18/bin/sqlcmd"