# Multi-Tenant Architecture Setup Guide

## Overview

The Steel Estimation Platform includes a foundation for multi-tenant architecture using a database-per-tenant pattern. This feature is **disabled by default** and requires specific Azure resources to enable.

## Architecture Pattern

- **Database-per-Tenant**: Each tenant gets their own isolated database
- **Elastic Pool**: Shared compute resources across tenant databases
- **Key Vault**: Secure storage of tenant connection strings
- **Master Registry**: Central database tracking all tenants

## Prerequisites

Before enabling multi-tenant mode, you need:

1. **Azure SQL Database** with Elastic Pool support
2. **Azure Key Vault** for secure connection string storage
3. **Managed Identity** or Service Principal with appropriate permissions
4. **Master Database** for tenant registry

## Setup Instructions

### 1. Create Azure SQL Elastic Pool

```bash
# Create elastic pool with shared resources
az sql elastic-pool create \
  --resource-group myResourceGroup \
  --server myserver \
  --name TenantPool \
  --edition Standard \
  --dtu 100 \
  --db-dtu-max 20 \
  --db-dtu-min 5
```

### 2. Create Master Database

Run the migration script to create tenant registry tables:

```sql
-- Run on your master database
:r SteelEstimation.Infrastructure/Migrations/AddTenantRegistry.sql
```

### 3. Configure Azure Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name steel-estimation-kv \
  --resource-group myResourceGroup \
  --location eastus

# Grant access to your app
az keyvault set-policy \
  --name steel-estimation-kv \
  --object-id <your-app-identity> \
  --secret-permissions get list set delete
```

### 4. Update Configuration

Add to your `appsettings.Production.json`:

```json
{
  "MultiTenant": {
    "EnableDatabasePerTenant": true,
    "DatabaseServer": "your-server.database.windows.net",
    "ElasticPoolName": "TenantPool"
  },
  "ConnectionStrings": {
    "MasterDatabase": "Server=your-server.database.windows.net;Database=SteelEstimation_Master;Authentication=Active Directory Default;"
  },
  "KeyVault": {
    "Url": "https://your-keyvault.vault.azure.net/"
  }
}
```

### 5. Enable Multi-Tenant Services

The services are automatically registered when `EnableDatabasePerTenant` is set to `true`.

## API Endpoints

When multi-tenant mode is enabled, the following endpoints become available:

### Register New Tenant
```http
POST /api/tenantonboarding/register
Authorization: Bearer <token>
Content-Type: application/json

{
  "companyName": "Acme Corporation",
  "companyCode": "ACME",
  "adminEmail": "admin@acme.com",
  "adminFirstName": "John",
  "adminLastName": "Doe",
  "subscriptionTier": "Standard",
  "maxUsers": 10
}
```

### Get Tenant Status
```http
GET /api/tenantonboarding/{tenantId}/status
Authorization: Bearer <token>
```

### List All Tenants
```http
GET /api/tenantonboarding/list
Authorization: Bearer <token>
```

## Tenant Provisioning Process

When a new tenant is registered:

1. Unique tenant ID is generated
2. Database created in elastic pool
3. Connection string stored in Key Vault
4. Database schema initialized (EF migrations)
5. Default data seeded (roles, material types)
6. Admin user created with temporary password
7. Tenant registered in master registry
8. Welcome email sent to admin

## Security Considerations

1. **Isolation**: Each tenant has complete database isolation
2. **Connection Security**: Connection strings stored in Key Vault
3. **Access Control**: Only SystemAdministrators can provision tenants
4. **Data Residency**: Consider regional requirements for data storage

## Cost Optimization

1. **Elastic Pool Sizing**: Start small and scale based on usage
2. **Database Density**: Monitor DTU usage per database
3. **Idle Database Management**: Consider pausing inactive tenants
4. **Storage Monitoring**: Track database sizes and growth

## Monitoring

Key metrics to monitor:

- Elastic pool DTU utilization
- Per-database resource usage
- Storage consumption per tenant
- Failed provisioning attempts
- Tenant activity patterns

## Maintenance Tasks

### Backup Strategy
- Automated backups via Azure SQL
- Point-in-time restore capability
- Consider cross-region backup for DR

### Schema Updates
- Apply migrations to all tenant databases
- Use rolling deployment strategy
- Test on subset before full rollout

### Tenant Cleanup
- Remove inactive tenants
- Archive old data
- Reclaim unused resources

## Troubleshooting

### Common Issues

1. **Provisioning Fails**
   - Check elastic pool has capacity
   - Verify Key Vault access
   - Review SQL permissions

2. **Connection Errors**
   - Verify connection string in Key Vault
   - Check firewall rules
   - Validate managed identity

3. **Performance Issues**
   - Review elastic pool DTU usage
   - Check for noisy neighbors
   - Consider pool scaling

## Development and Testing

For local development without Azure resources:

1. Keep `EnableDatabasePerTenant: false`
2. Use single database for all development
3. Mock Key Vault with configuration
4. Test provisioning logic separately

## Future Enhancements

Planned features not yet implemented:

- Tenant database backup/restore
- Subscription tier management
- Usage-based billing integration
- Automated tenant suspension
- Cross-tenant reporting
- Tenant data export/import

## References

- [Azure SQL Elastic Pools](https://docs.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-overview)
- [Multi-tenant SaaS patterns](https://docs.microsoft.com/en-us/azure/azure-sql/database/saas-tenancy-app-design-patterns)
- [Key Vault best practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)