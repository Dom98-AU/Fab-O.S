# Steel Estimation Platform - Docker Setup

## Prerequisites
- Docker Desktop installed and running
- Docker Compose installed
- At least 4GB of RAM allocated to Docker

## Quick Start

1. **Build and start the containers:**
   ```bash
   docker-compose up -d --build
   ```

2. **Access the application:**
   - Web Application: http://localhost:8080
   - SQL Server: localhost:1433
   - Nginx (Production): http://localhost

3. **Default credentials:**
   - Web App: admin@steelestimation.com / Admin@123
   - SQL Server SA: sa / YourStrong@Password123

## Container Structure

- **steel-estimation-sql**: SQL Server 2022 with your database
- **steel-estimation-web**: ASP.NET Core 8.0 application
- **steel-estimation-nginx**: Nginx reverse proxy (optional)

## Database Management

### Export data from local SQL Server:
```powershell
.\export-database.ps1
```

### Connect to SQL Server in Docker:
```bash
docker exec -it steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Password123
```

### Backup database from Docker:
```bash
docker exec steel-estimation-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P YourStrong@Password123 -Q "BACKUP DATABASE [SteelEstimationDB] TO DISK = N'/var/opt/mssql/backup/SteelEstimationDB.bak'"
docker cp steel-estimation-sql:/var/opt/mssql/backup/SteelEstimationDB.bak ./backup/
```

## Development Commands

### View logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
```

### Restart services:
```bash
docker-compose restart web
```

### Stop all services:
```bash
docker-compose down
```

### Remove all data (careful!):
```bash
docker-compose down -v
```

## Production Deployment

1. **Update environment variables** in docker-compose.yml:
   - Change SA password
   - Update connection strings
   - Configure SSL certificates

2. **Enable HTTPS** in nginx.conf:
   - Uncomment HTTPS server block
   - Add SSL certificates to docker/nginx/ssl/
   - Update server_name

3. **Scale the application:**
   ```bash
   docker-compose up -d --scale web=3
   ```

## Troubleshooting

### SQL Server won't start:
- Check Docker has enough memory (4GB minimum)
- Verify password meets complexity requirements
- Check logs: `docker-compose logs sql-server`

### Can't connect to application:
- Ensure all containers are healthy: `docker-compose ps`
- Check web logs: `docker-compose logs web`
- Verify ports aren't already in use

### Database initialization failed:
- Check init script permissions: `chmod +x docker/sql-init.sh`
- Verify SQL script syntax in docker/sql/init-database.sql
- Manually run initialization if needed

## Customization

### Change ports:
Edit docker-compose.yml and update port mappings

### Add environment variables:
Add to web service environment section in docker-compose.yml

### Custom SQL scripts:
Add .sql files to docker/sql/ directory - they'll run on first start

## Security Notes

Before production deployment:
1. Change all default passwords
2. Use secrets management for sensitive data
3. Enable HTTPS with valid certificates
4. Restrict database access
5. Review and update firewall rules