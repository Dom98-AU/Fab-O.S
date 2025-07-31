# PowerShell script to run Steel Estimation Platform in Docker

param(
    [switch]$Build,
    [switch]$Clean,
    [switch]$Logs,
    [switch]$Stop
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

# Check if Docker is running
if (!(docker info 2>$null)) {
    Write-Warning "Docker is not running. Please start Docker Desktop."
    exit 1
}

# Stop containers
if ($Stop) {
    Write-Info "Stopping containers..."
    docker-compose down
    Write-Success "Containers stopped."
    exit 0
}

# Clean up everything
if ($Clean) {
    Write-Warning "This will remove all containers, volumes, and data!"
    $confirm = Read-Host "Are you sure? (yes/no)"
    if ($confirm -eq "yes") {
        Write-Info "Cleaning up Docker environment..."
        docker-compose down -v --remove-orphans
        Write-Success "Cleanup complete."
    }
    exit 0
}

# Show logs
if ($Logs) {
    Write-Info "Showing logs (Ctrl+C to exit)..."
    docker-compose logs -f
    exit 0
}

# Main execution
Write-Info "Starting Steel Estimation Platform in Docker..."

# Build if requested or if images don't exist
if ($Build -or !(docker images steel-estimation-clouddev_web -q)) {
    Write-Info "Building Docker images..."
    docker-compose build
}

# Make SQL init script executable (for Linux containers)
if (Test-Path ".\docker\sql-init.sh") {
    # Convert to Unix line endings if needed
    $content = Get-Content ".\docker\sql-init.sh" -Raw
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText(".\docker\sql-init.sh", $content)
}

# Start containers
Write-Info "Starting containers..."
docker-compose up -d

# Wait for SQL Server to be ready
Write-Info "Waiting for SQL Server to initialize..."
$maxAttempts = 30
$attempt = 0
$sqlReady = $false

while ($attempt -lt $maxAttempts -and !$sqlReady) {
    $attempt++
    Start-Sleep -Seconds 2
    
    try {
        docker exec steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -Q "SELECT 1" 2>$null | Out-Null
        $sqlReady = $true
    } catch {
        Write-Host "." -NoNewline
    }
}

Write-Host ""

if ($sqlReady) {
    Write-Success "SQL Server is ready!"
    
    # Run database initialization
    Write-Info "Initializing database..."
    docker exec steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -i /docker-entrypoint-initdb.d/init-database.sql
    
    Write-Success @"

Steel Estimation Platform is running!

Access the application at:
- Web App: http://localhost:8080
- Login: admin@steelestimation.com
- Password: Admin@123

SQL Server:
- Server: localhost,1433
- SA Password: YourStrong@Password123

Commands:
- View logs: .\docker-run.ps1 -Logs
- Stop: .\docker-run.ps1 -Stop
- Clean up: .\docker-run.ps1 -Clean

"@
} else {
    Write-Warning "SQL Server failed to start. Check logs with: docker-compose logs sql-server"
}