# Steel Estimation Platform - Configuration Best Practices

## Overview
This guide documents the proper configuration approach for the Steel Estimation Platform, using ASP.NET Core's built-in configuration system with Azure SQL Database for all environments.

## Configuration Strategy

### 1. Environment-Based Configuration
We use ASP.NET Core's standard environment-based configuration loading:
- `appsettings.json` - Base configuration (no secrets)
- `appsettings.Development.json` - Local development
- `appsettings.DockerLocal.json` - Docker with local SQL (if needed)
- `appsettings.Staging.json` - Staging environment
- `appsettings.Production.json` - Production environment

### 2. Configuration Loading Order
```csharp
// Program.cs - Clean configuration loading
var builder = WebApplication.CreateBuilder(args);

// Configuration is automatically loaded in this order:
// 1. appsettings.json
// 2. appsettings.{Environment}.json
// 3. Environment variables
// 4. Command line arguments
```

### 3. Connection String Management
Since we're using Azure SQL for all development:
```json
// appsettings.Development.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:nwiapps.database.windows.net,1433;..."
  }
}
```

## Docker Configuration

### For Development (Using Azure SQL)
```bash
# Use the simplified docker-compose
docker-compose -f docker-compose-dev.yml up
```

### docker-compose-dev.yml
```yaml
services:
  web:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      # Connection string comes from appsettings.Development.json
```

## Running Locally

### Option 1: Direct Development
```bash
cd SteelEstimation.Web
dotnet run
# Uses appsettings.Development.json automatically
```

### Option 2: Docker Development
```bash
docker-compose -f docker-compose-dev.yml up
# Uses appsettings.Development.json via environment variable
```

### Option 3: Override with Environment Variable
```bash
# Windows PowerShell
$env:ConnectionStrings__DefaultConnection="Server=tcp:different-server..."
dotnet run

# Linux/Mac
export ConnectionStrings__DefaultConnection="Server=tcp:different-server..."
dotnet run
```

## Best Practices Applied

### ✅ DO:
1. **Use standard ASP.NET Core configuration**
   - Let the framework handle configuration loading
   - Use environment-specific files

2. **Keep secrets out of appsettings.json**
   - Use Azure Key Vault for production
   - Use user secrets for local development
   - Environment variables for Docker

3. **Use consistent environment names**
   - Development, Staging, Production
   - Avoid custom names like "Docker" or "Azure"

4. **One Dockerfile for all environments**
   - Use environment variables to control behavior
   - Don't create environment-specific Dockerfiles

### ❌ DON'T:
1. **Don't detect Docker at runtime**
   ```csharp
   // Bad - removed this
   var isDocker = Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER");
   ```

2. **Don't load configuration conditionally**
   ```csharp
   // Bad - removed this
   if (isDocker) {
       builder.Configuration.AddJsonFile("appsettings.Docker.json");
   }
   ```

3. **Don't modify containers to delete files**
   ```dockerfile
   # Bad - we removed this approach
   RUN rm -f appsettings.Docker.json
   ```

## Production Recommendations

### 1. Use Azure Key Vault
```csharp
// Program.cs
if (builder.Environment.IsProduction())
{
    var keyVaultName = builder.Configuration["KeyVaultName"];
    var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(keyVaultUri, new DefaultAzureCredential());
}
```

### 2. Use Managed Identity
```json
// For production Azure SQL
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:server.database.windows.net;Database=db;Authentication=Active Directory Default;"
  }
}
```

### 3. Use Application Settings in Azure App Service
- Override configuration via Azure Portal
- No passwords in code or config files
- Automatic encryption at rest

## Migration from Old Approach

### What Changed:
1. Removed Docker detection from Program.cs
2. Removed appsettings.Docker.json
3. Using standard environment names
4. Single Dockerfile for all environments
5. Configuration via environment-specific files

### Benefits:
- Simpler, more maintainable code
- Follows .NET best practices
- Works consistently across all hosting environments
- Easier for new team members to understand
- Better security with proper secret management