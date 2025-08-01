#!/bin/bash

echo "========================================"
echo " Fab.OS Product Licensing Migration"
echo " Docker Version"
echo "========================================"
echo ""

# Check if docker container is running
CONTAINER_NAME="steel-estimation-web-dev"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Docker container '${CONTAINER_NAME}' is not running."
    echo "Please ensure the application is running with: docker-compose up"
    exit 1
fi

echo "Running migration inside Docker container..."
echo ""

# Execute the migration inside the Docker container
docker exec -it ${CONTAINER_NAME} /bin/bash -c "cd /app && dotnet exec --runtimeconfig SteelEstimation.Web.runtimeconfig.json --depsfile SteelEstimation.Web.deps.json /usr/bin/sqlcmd -S tcp:nwiapps.database.windows.net,1433 -d sqldb-steel-estimation-sandbox -U 'admin@nwi@nwiapps' -P 'Natweigh88' -i SQL_Migrations/AddProductLicensing.sql -b"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo " Migration completed successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Restart the application to load new configuration"
    echo "2. Users will need to log out and back in to get product claims"
    echo "3. The module switcher will appear in the UI"
else
    echo ""
    echo "Error: Migration failed"
    exit 1
fi