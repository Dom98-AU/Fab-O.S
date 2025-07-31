# Steel Estimation Platform - Docker Edition

A comprehensive steel fabrication estimation platform built with ASP.NET Core 8.0, Blazor Server, and Azure SQL Database. This cloud-ready version enables easy deployment with Docker containerization and Azure integration.

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

### For All Development
- .NET 8 SDK
- Visual Studio 2022 or VS Code
- Docker Desktop (for containerized development)
- PowerShell (for scripts)
- Access to Azure SQL Database (connection details in appsettings)

## Getting Started

### 🐳 Docker Quick Start (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/Dom98-AU/Fab-O.S.git
   cd Fab-O.S
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

### 💻 Local Development

2. **Run the application**
   ```powershell
   .\run-local.ps1
   ```
   Access at: https://localhost:5003 or http://localhost:5002

### Running with Docker

```bash
# Default Docker setup
docker-compose up

# Or use Azure-specific configuration
docker-compose -f docker-compose-azure.yml up
```

### Database Information

The application uses Azure SQL Database:
- Server: nwiapps.database.windows.net
- Database: sqldb-steel-estimation-sandbox
- Connection details are in appsettings files

### Running Migrations

To apply database migrations to Azure SQL:
```powershell
.\run-migration.ps1
```

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
- **Database**: Azure SQL Database
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

### Database Operations

For database backup/restore operations with Azure SQL, use:
```powershell
# Use SqlPackage for Azure SQL backup/restore
.\migrate-to-azure.ps1
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

#All environments now use Azure SQL Database. Connection strings are configured in:
- `appsettings.Development.json` - For local development
- `appsettings.DockerLocal.json` - For Docker with Development environment
- `appsettings.DockerAzure.json` - For Docker with Azure-specific settings

### Key Settings
- `ConnectionStrings:DefaultConnection` - Database connection
- `Authentication:Cookie` - Session timeout and cookie settings
- `ABRWebServices` - Australian Business Register integration
- `FileUpload` - Upload size and type restrictions

## 🛠️ Troubleshooting

### Docker Issues
- **Port conflicts**: Change ports in docker-compose.yml if 8080 is in use
- **Connection issues**: Check Azure SQL firewall rules
- **Permission errors**: Ensure Docker Desktop is running

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