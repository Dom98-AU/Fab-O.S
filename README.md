# Steel Estimation Platform - Docker Edition

A comprehensive steel fabrication estimation platform built with ASP.NET Core 8.0, Blazor Server, and SQL Server. This Docker-ready version enables easy deployment and development with full containerization support.

## Project Structure

```
SteelEstimation/
├── SteelEstimation.Web/          # Blazor Server web application
│   ├── Components/               # Blazor components
│   ├── Controllers/              # API controllers
│   ├── Pages/                    # Razor pages
│   ├── Services/                 # Application services
│   ├── Shared/                   # Shared components
│   └── wwwroot/                  # Static files
├── SteelEstimation.Core/         # Core business logic
│   ├── DTOs/                     # Data transfer objects
│   ├── Entities/                 # Domain entities
│   ├── Interfaces/               # Service interfaces
│   └── Services/                 # Business services
├── SteelEstimation.Infrastructure/ # Data access and external services
│   ├── Data/                     # Entity Framework context
│   ├── Migrations/               # Database migrations
│   ├── Repositories/             # Repository implementations
│   └── Services/                 # Infrastructure services
└── SteelEstimation.Tests/        # Unit and integration tests
    ├── Unit/                     # Unit tests
    ├── Integration/              # Integration tests
    └── E2E/                      # End-to-end tests
```

## 🚀 Key Features

- **Project Management**: Create and manage steel fabrication projects with multi-user collaboration
- **Advanced Estimation**: Welding, processing, and delivery estimation with time tracking
- **Pack & Delivery Bundles**: Organize items for handling and logistics operations
- **Efficiency Management**: Configurable efficiency rates by company
- **Real-time Analytics**: Welding time dashboards with detailed breakdowns
- **Multi-tenant Support**: Company-based data isolation
- **Role-Based Security**: Administrator, Project Manager, Senior Estimator, Estimator, and Viewer roles
- **Docker Ready**: Fully containerized with Docker Compose for easy deployment

## Prerequisites

### For Docker Development (Recommended)
- Docker Desktop
- Docker Compose
- PowerShell (for migration scripts)

### For Local Development
- .NET 8 SDK
- SQL Server 2022 (or SQL Server 2019+)
- Visual Studio 2022 or VS Code
- PowerShell (Run as Administrator for database setup)

## Getting Started

### 🐳 Docker Quick Start (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/[your-username]/steel-estimation-docker.git
   cd steel-estimation-docker
   ```

2. **Start the containers**
   ```bash
   docker-compose up -d
   ```

3. **Migrate existing database** (if you have one)
   ```powershell
   .\backup-restore-to-docker.ps1
   ```

4. **Access the application**
   - URL: http://localhost:8080
   - Login: admin@steelestimation.com
   - Password: Admin@123

### 💻 Local Development with SQL Server

2. **Set up local database** (Run PowerShell as Administrator)
   ```powershell
   .\setup-local-db.ps1
   ```
   This will:
   - Create the database
   - Run all migrations
   - Seed admin user (admin@steelestimation.com / Admin@123)

3. **Run the application**
   ```powershell
   .\run-local.ps1
   ```
   Access at: https://localhost:5001

### Manual Database Setup (Alternative)

If you prefer to set up the database manually:

1. **Create database in SQL Server**
2. **Run migrations**
   ```bash
   cd SteelEstimation.Web
   dotnet ef database update --project ..\SteelEstimation.Infrastructure
   ```

4. **Run the application**
   ```bash
   cd SteelEstimation.Web
   dotnet run
   ```

5. **Access the application**
   - Navigate to `https://localhost:5001`
   - Default login: admin@steelestimation.com / Admin@123

## Features

- **User Authentication & Authorization**
  - Cookie-based authentication with 8-hour sliding expiration
  - Role-based access control (5 roles)
  - Password reset functionality
  - PBKDF2 password hashing with HMACSHA256

- **Project Management**
  - Create and manage estimation projects
  - User access control per project
  - Project ownership and collaboration

- **Material Processing & Handling**
  - Material takeoff with quantities and dimensions
  - Bundle and pack grouping
  - Time-based labor calculations

- **Welding & Fabrication**
  - Connection-based estimations
  - Welding time calculations
  - Quality check tracking

- **Import/Export**
  - Excel file import/export
  - Bulk data operations
  - Template-based imports

- **Real-time Updates**
  - Live calculation updates
  - Collaborative editing
  - SignalR integration

## Technology Stack

- **Backend**: .NET 8, ASP.NET Core, Entity Framework Core 8
- **Frontend**: Blazor Server-Side Rendering, Bootstrap 5
- **Database**: SQL Server 2022 (Docker or Azure SQL)
- **Authentication**: Cookie-based with ASP.NET Core Identity
- **Containerization**: Docker, Docker Compose
- **Architecture**: Clean Architecture with DDD principles
- **File Processing**: EPPlus for Excel operations
- **Testing**: xUnit, Moq, FluentAssertions

## Development

### Database Migrations

#### Recent Features Added:
- **Time Tracking**: Automatic estimation time tracking with pause detection
- **Multiple Welding Connections**: Support for multiple connection types per item
- **Processing Efficiency**: Filter processing hours by efficiency percentage
- **Pack Bundles**: Group processing items for handling operations

#### Adding a new migration
```bash
cd SteelEstimation.Web
dotnet ef migrations add [MigrationName] --project ..\SteelEstimation.Infrastructure
```

#### Apply migrations
```powershell
.\run-migration.ps1
```

### Running tests
```bash
dotnet test
```

### Building for production
```bash
dotnet publish -c Release -o ./publish
```

## 🐳 Docker Operations

### Container Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker logs steel-estimation-web --follow
docker logs steel-estimation-sql --tail 100

# Restart services
docker-compose restart
```

### Database Backup/Restore
```powershell
# Backup from Docker
docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "BACKUP DATABASE SteelEstimationDB TO DISK = '/var/opt/mssql/backup/backup.bak'"

# Copy backup locally
docker cp steel-estimation-sql:/var/opt/mssql/backup/backup.bak ./backup.bak
```

## Deployment

### Docker Deployment
```bash
# Build image
docker build -t steel-estimation:latest .

# Push to registry
docker tag steel-estimation:latest [registry]/steel-estimation:latest
docker push [registry]/steel-estimation:latest

# Deploy with compose
docker-compose -f docker-compose.prod.yml up -d
```

### Azure Deployment Options

#### Option 1: Azure Container Instances
- Quick deployment for smaller workloads
- Managed container service

#### Option 2: Azure Kubernetes Service (AKS)
- For production scalability
- Full orchestration capabilities

#### Option 3: Traditional Azure App Service
- App Service Plan (Standard S1 or higher)
- Azure SQL Database (Standard S2 or higher)
- Key Vault (for secrets)
- Application Insights (for monitoring)

## Configuration

### Environment-Specific Settings

#### Docker Environment (`appsettings.Docker.json`)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=sql-server;Database=SteelEstimationDB;..."
  }
}
```

#### Local Development (`appsettings.Development.json`)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;..."
  }
}
```

### Key Settings
- `ConnectionStrings:DefaultConnection` - Database connection
- `Authentication:Cookie` - Session timeout and cookie settings
- `ABRWebServices` - Australian Business Register integration
- `FileUpload` - Upload size and type restrictions

## 🛠️ Troubleshooting

### Docker Issues
- **SQL Server not starting**: Wait 30-60 seconds for initialization
- **Port conflicts**: Change ports in docker-compose.yml if 8080 or 1433 are in use
- **Permission errors**: Run PowerShell as Administrator

### Database Migration Issues
- **Login failed**: Check SA password matches docker-compose.yml
- **Schema mismatch**: Use backup-restore method for exact migration
- **Connection timeout**: Ensure Docker Desktop is running

## Security Considerations

- Change default passwords before production deployment
- Use environment variables for sensitive configuration
- Enable HTTPS in production
- Regular security updates for base images
- Implement proper backup strategies

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support and questions, please contact the development team or open an issue.

---

Built with ❤️ for the steel fabrication industry