using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;
using System.Text;

namespace SteelEstimation.Infrastructure.Services;

/// <summary>
/// Service for provisioning and managing tenant databases
/// Note: This is disabled by default. Enable by setting EnableMultiTenantMode in configuration
/// </summary>
public class TenantProvisioningService : ITenantProvisioningService
{
    private readonly IConfiguration _configuration;
    private readonly IKeyVaultService _keyVault;
    private readonly ILogger<TenantProvisioningService> _logger;
    private readonly MasterDbContext _masterContext;
    private readonly bool _isEnabled;

    public TenantProvisioningService(
        IConfiguration configuration,
        IKeyVaultService keyVault,
        ILogger<TenantProvisioningService> logger,
        MasterDbContext masterContext)
    {
        _configuration = configuration;
        _keyVault = keyVault;
        _logger = logger;
        _masterContext = masterContext;
        _isEnabled = configuration.GetValue<bool>("MultiTenant:EnableDatabasePerTenant", false);
    }

    public async Task<TenantInfo> ProvisionTenantAsync(string tenantId, TenantRegistrationRequest request)
    {
        if (!_isEnabled)
        {
            throw new InvalidOperationException("Multi-tenant mode is not enabled. Set MultiTenant:EnableDatabasePerTenant to true in configuration.");
        }

        try
        {
            _logger.LogInformation("Starting tenant provisioning for {TenantId}", tenantId);

            // 1. Create database in elastic pool
            var databaseName = $"tenant_{tenantId}";
            await CreateDatabaseInPoolAsync(databaseName);

            // 2. Build connection string
            var connectionString = BuildConnectionString(databaseName);

            // 3. Store connection string securely
            await _keyVault.StoreSecretAsync($"tenant-{tenantId}-connectionstring", connectionString);

            // 4. Initialize database schema
            await InitializeTenantDatabaseAsync(connectionString);

            // 5. Seed initial data
            await SeedTenantDataAsync(connectionString, request);

            // 6. Register tenant in master tenant registry
            await RegisterTenantAsync(tenantId, databaseName, request);

            _logger.LogInformation("Successfully provisioned tenant {TenantId}", tenantId);

            return new TenantInfo
            {
                TenantId = tenantId,
                DatabaseName = databaseName,
                ConnectionString = connectionString,
                CompanyName = request.CompanyName,
                AdminEmail = request.AdminEmail,
                CreatedAt = DateTime.UtcNow,
                SubscriptionTier = request.SubscriptionTier
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to provision tenant {TenantId}", tenantId);
            
            // Attempt cleanup
            await CleanupFailedProvisioningAsync(tenantId);
            
            throw;
        }
    }

    private async Task CreateDatabaseInPoolAsync(string databaseName)
    {
        var masterConnectionString = _configuration.GetConnectionString("MasterDatabase");
        var elasticPoolName = _configuration["MultiTenant:ElasticPoolName"] ?? "TenantPool";
        
        using var connection = new SqlConnection(masterConnectionString);
        await connection.OpenAsync();
        
        var commandText = $@"
            IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '{databaseName}')
            BEGIN
                CREATE DATABASE [{databaseName}]
                (SERVICE_OBJECTIVE = ELASTIC_POOL(name = {elasticPoolName}))
            END";
        
        using var command = new SqlCommand(commandText, connection);
        await command.ExecuteNonQueryAsync();
        
        _logger.LogInformation("Created database {DatabaseName} in elastic pool {PoolName}", databaseName, elasticPoolName);
    }

    private string BuildConnectionString(string databaseName)
    {
        var template = _configuration.GetConnectionString("TenantDatabaseTemplate") 
            ?? _configuration.GetConnectionString("DefaultConnection");
            
        if (string.IsNullOrEmpty(template))
        {
            throw new InvalidOperationException("No connection string template found");
        }

        var builder = new SqlConnectionStringBuilder(template)
        {
            InitialCatalog = databaseName
        };
        
        return builder.ConnectionString;
    }

    private async Task InitializeTenantDatabaseAsync(string connectionString)
    {
        var optionsBuilder = new DbContextOptionsBuilder<TenantDbContext>();
        optionsBuilder.UseSqlServer(connectionString);
        
        using var context = new TenantDbContext(optionsBuilder.Options);
        
        // Run migrations
        await context.Database.MigrateAsync();
        
        _logger.LogInformation("Initialized tenant database schema");
    }

    private async Task SeedTenantDataAsync(string connectionString, TenantRegistrationRequest request)
    {
        var optionsBuilder = new DbContextOptionsBuilder<TenantDbContext>();
        optionsBuilder.UseSqlServer(connectionString);
        
        using var context = new TenantDbContext(optionsBuilder.Options);
        
        // Create company
        var company = new Company
        {
            Name = request.CompanyName,
            Code = request.CompanyCode,
            IsActive = true,
            SubscriptionLevel = request.SubscriptionTier,
            MaxUsers = request.MaxUsers,
            CreatedDate = DateTime.UtcNow,
            LastModified = DateTime.UtcNow
        };
        
        context.Companies.Add(company);
        await context.SaveChangesAsync();
        
        // Create admin user
        var adminUser = new User
        {
            Username = request.AdminEmail,
            Email = request.AdminEmail,
            FirstName = request.AdminFirstName,
            LastName = request.AdminLastName,
            CompanyId = company.Id,
            PhoneNumber = request.PhoneNumber,
            IsActive = true,
            IsEmailConfirmed = false,
            EmailConfirmationToken = GenerateToken(),
            CreatedDate = DateTime.UtcNow,
            LastModified = DateTime.UtcNow,
            PasswordHash = HashPassword(GenerateTemporaryPassword())
        };
        
        context.Users.Add(adminUser);
        await context.SaveChangesAsync();
        
        // Assign admin role
        var adminRole = await context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Administrator");
        if (adminRole == null)
        {
            // Seed roles if they don't exist
            await SeedRolesAsync(context);
            adminRole = await context.Roles.FirstAsync(r => r.RoleName == "Administrator");
        }
        
        context.UserRoles.Add(new UserRole
        {
            UserId = adminUser.Id,
            RoleId = adminRole.Id,
            AssignedDate = DateTime.UtcNow
        });
        
        await context.SaveChangesAsync();
        
        // Copy default material settings
        await SeedMaterialSettingsAsync(context, company.Id);
        
        _logger.LogInformation("Seeded initial data for tenant");
    }

    private async Task RegisterTenantAsync(string tenantId, string databaseName, TenantRegistrationRequest request)
    {
        var registry = new TenantRegistry
        {
            TenantId = tenantId,
            DatabaseName = databaseName,
            CompanyName = request.CompanyName,
            CompanyCode = request.CompanyCode,
            AdminEmail = request.AdminEmail,
            CreatedAt = DateTime.UtcNow,
            LastModified = DateTime.UtcNow,
            IsActive = true,
            SubscriptionTier = request.SubscriptionTier,
            MaxUsers = request.MaxUsers,
            ConnectionStringKeyVaultName = $"tenant-{tenantId}-connectionstring",
            DatabaseServer = _configuration["MultiTenant:DatabaseServer"],
            ElasticPoolName = _configuration["MultiTenant:ElasticPoolName"],
            Settings = request.AdditionalSettings
        };
        
        _masterContext.TenantRegistries.Add(registry);
        await _masterContext.SaveChangesAsync();
        
        _logger.LogInformation("Registered tenant {TenantId} in master registry", tenantId);
    }

    private async Task SeedRolesAsync(TenantDbContext context)
    {
        var roles = new[]
        {
            new Role { RoleName = "Administrator", Description = "Full system access", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = true, CanViewAllProjects = true, CanManageUsers = true, CanExportData = true, CanImportData = true },
            new Role { RoleName = "Project Manager", Description = "Can manage all projects and users", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = true, CanViewAllProjects = true, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { RoleName = "Senior Estimator", Description = "Can create and edit projects", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { RoleName = "Estimator", Description = "Can edit assigned projects", CanCreateProjects = false, CanEditProjects = true, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { RoleName = "Viewer", Description = "Read-only access to assigned projects", CanCreateProjects = false, CanEditProjects = false, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = false }
        };
        
        context.Roles.AddRange(roles);
        await context.SaveChangesAsync();
    }

    private async Task SeedMaterialSettingsAsync(TenantDbContext context, int companyId)
    {
        // Seed default material types
        var materialTypes = new[]
        {
            new CompanyMaterialType { CompanyId = companyId, TypeName = "Beam", Description = "Structural beams and columns", HourlyRate = 65.00m, DefaultColor = "#007bff", DisplayOrder = 1, IsActive = true, CreatedDate = DateTime.UtcNow, LastModified = DateTime.UtcNow },
            new CompanyMaterialType { CompanyId = companyId, TypeName = "Plate", Description = "Steel plates and flat materials", HourlyRate = 65.00m, DefaultColor = "#17a2b8", DisplayOrder = 2, IsActive = true, CreatedDate = DateTime.UtcNow, LastModified = DateTime.UtcNow },
            new CompanyMaterialType { CompanyId = companyId, TypeName = "Purlin", Description = "Roof and wall purlins", HourlyRate = 65.00m, DefaultColor = "#28a745", DisplayOrder = 3, IsActive = true, CreatedDate = DateTime.UtcNow, LastModified = DateTime.UtcNow },
            new CompanyMaterialType { CompanyId = companyId, TypeName = "Misc", Description = "Miscellaneous steel items", HourlyRate = 65.00m, DefaultColor = "#6c757d", DisplayOrder = 4, IsActive = true, CreatedDate = DateTime.UtcNow, LastModified = DateTime.UtcNow }
        };
        
        context.CompanyMaterialTypes.AddRange(materialTypes);
        await context.SaveChangesAsync();
    }

    private async Task CleanupFailedProvisioningAsync(string tenantId)
    {
        try
        {
            // Remove Key Vault secret
            await _keyVault.DeleteSecretAsync($"tenant-{tenantId}-connectionstring");
            
            // Remove from registry if exists
            var registry = await _masterContext.TenantRegistries
                .FirstOrDefaultAsync(t => t.TenantId == tenantId);
            if (registry != null)
            {
                _masterContext.TenantRegistries.Remove(registry);
                await _masterContext.SaveChangesAsync();
            }
            
            // Note: Database cleanup would require additional permissions
            // and should be handled by a separate maintenance process
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup after failed provisioning for tenant {TenantId}", tenantId);
        }
    }

    public Task<bool> DeprovisionTenantAsync(string tenantId)
    {
        // Implementation for deprovisioning
        throw new NotImplementedException("Tenant deprovisioning is not yet implemented");
    }

    public Task<bool> UpdateTenantSubscriptionAsync(string tenantId, string newTier, int maxUsers)
    {
        // Implementation for subscription updates
        throw new NotImplementedException("Tenant subscription update is not yet implemented");
    }

    public Task<bool> SuspendTenantAsync(string tenantId)
    {
        // Implementation for tenant suspension
        throw new NotImplementedException("Tenant suspension is not yet implemented");
    }

    public Task<bool> ReactivateTenantAsync(string tenantId)
    {
        // Implementation for tenant reactivation
        throw new NotImplementedException("Tenant reactivation is not yet implemented");
    }

    public Task<bool> BackupTenantDatabaseAsync(string tenantId)
    {
        // Implementation for tenant backup
        throw new NotImplementedException("Tenant backup is not yet implemented");
    }

    public Task<bool> RestoreTenantDatabaseAsync(string tenantId, string backupPath)
    {
        // Implementation for tenant restore
        throw new NotImplementedException("Tenant restore is not yet implemented");
    }

    private string GenerateToken()
    {
        return Guid.NewGuid().ToString("N");
    }

    private string GenerateTemporaryPassword()
    {
        return $"Temp{Guid.NewGuid().ToString("N").Substring(0, 8)}!";
    }

    private string HashPassword(string password)
    {
        // This should use the same password hashing as the main authentication service
        // For now, returning a placeholder
        return $"HASH:{password}";
    }
}