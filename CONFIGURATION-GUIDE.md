# Configuration Guide - Microsoft Best Practices

This application follows Microsoft's recommended configuration patterns for cloud-ready ASP.NET Core applications.

## Configuration Hierarchy

ASP.NET Core loads configuration in the following order (later sources override earlier ones):
1. appsettings.json
2. appsettings.{Environment}.json
3. User secrets (Development only)
4. Environment variables
5. Command-line arguments

## Environment Setup

### 1. Create Your .env File

Copy the example and update with your credentials:
```bash
cp .env.example .env
```

### 2. Environment Variables Format

Following Microsoft's naming conventions:
- Connection strings: `SQLCONNSTR_DefaultConnection`
- Nested configuration: `Authentication__Microsoft__ClientId`

### 3. Docker Development

```bash
# Using default .env file
docker-compose up

# Docker will automatically use .env file
docker-compose up
```

## Security Best Practices

✅ **DO:**
- Store secrets in .env files (not in Git)
- Use Azure Key Vault for production
- Keep appsettings.json free of secrets
- Use environment-specific configuration files

❌ **DON'T:**
- Commit .env files to Git
- Store passwords in appsettings.json
- Share .env files via insecure channels

## Configuration Files

### appsettings.json
Base configuration without any secrets. This file is committed to Git.

### appsettings.Development.json
Development-specific settings. Not committed to Git.

### appsettings.Docker.json
Docker-specific settings. Committed to Git but contains no secrets.

### .env
Environment variables for local development and Docker. Never committed to Git.

## Cross-Device Development

All developers on the team:
1. Create their own `.env` file with shared Azure SQL credentials
2. Run `docker-compose up`
3. Access the same Azure SQL database
4. Work with synchronized data

## Testing Configuration

```bash
# Test if environment variables are loaded
docker-compose exec web sh -c 'echo $SQLCONNSTR_DefaultConnection'

# Check application logs
docker-compose logs web
```

## Troubleshooting

### Connection String Not Working
1. Check .env file exists and has correct values
2. Verify environment variable format: `ConnectionStrings__DefaultConnection`
3. Check Docker logs: `docker-compose logs web`

### Credentials Still in appsettings.json
Run `git status` to ensure changes are saved. The credentials should be removed.

### Docker Can't Connect to Azure SQL
1. Verify Azure SQL firewall rules allow your IP
2. Check connection string format in .env
3. Ensure password doesn't contain special characters that need escaping

## Production Deployment

For Azure deployment:
1. Use Azure Key Vault for secrets
2. Use Managed Identity for database connection
3. Set environment variables in Azure App Service Configuration
4. Never store production credentials in code

## References

- [Microsoft Configuration Documentation](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Azure Key Vault Configuration Provider](https://docs.microsoft.com/en-us/aspnet/core/security/key-vault-configuration)