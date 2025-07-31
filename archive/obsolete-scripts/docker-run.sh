#!/bin/bash

# Shell script to run Steel Estimation Platform in Docker

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions for colored output
success() { echo -e "${GREEN}$1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }
warning() { echo -e "${YELLOW}$1${NC}"; }

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    warning "Docker is not running. Please start Docker."
    exit 1
fi

# Parse command line arguments
case "$1" in
    stop)
        info "Stopping containers..."
        docker-compose down
        success "Containers stopped."
        exit 0
        ;;
    clean)
        warning "This will remove all containers, volumes, and data!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            info "Cleaning up Docker environment..."
            docker-compose down -v --remove-orphans
            success "Cleanup complete."
        fi
        exit 0
        ;;
    logs)
        info "Showing logs (Ctrl+C to exit)..."
        docker-compose logs -f
        exit 0
        ;;
    build)
        BUILD=true
        ;;
esac

# Main execution
info "Starting Steel Estimation Platform in Docker..."

# Build if requested or if images don't exist
if [ "$BUILD" = true ] || [ -z "$(docker images -q steel-estimation-clouddev_web)" ]; then
    info "Building Docker images..."
    docker-compose build
fi

# Make SQL init script executable
if [ -f "./docker/sql-init.sh" ]; then
    chmod +x ./docker/sql-init.sh
fi

# Start containers
info "Starting containers..."
docker-compose up -d

# Wait for SQL Server to be ready
info "Waiting for SQL Server to initialize..."
max_attempts=30
attempt=0
sql_ready=false

while [ $attempt -lt $max_attempts ] && [ "$sql_ready" = false ]; do
    attempt=$((attempt + 1))
    sleep 2
    
    if docker exec steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -Q "SELECT 1" >/dev/null 2>&1; then
        sql_ready=true
    else
        echo -n "."
    fi
done

echo ""

if [ "$sql_ready" = true ]; then
    success "SQL Server is ready!"
    
    # Run database initialization
    info "Initializing database..."
    docker exec steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -i /docker-entrypoint-initdb.d/init-database.sql
    
    success "
Steel Estimation Platform is running!

Access the application at:
- Web App: http://localhost:8080
- Login: admin@steelestimation.com
- Password: Admin@123

SQL Server:
- Server: localhost,1433
- SA Password: YourStrong@Password123

Commands:
- View logs: ./docker-run.sh logs
- Stop: ./docker-run.sh stop
- Clean up: ./docker-run.sh clean
"
else
    warning "SQL Server failed to start. Check logs with: docker-compose logs sql-server"
fi