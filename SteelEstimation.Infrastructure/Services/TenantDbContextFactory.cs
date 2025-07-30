using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

/// <summary>
/// Factory for creating tenant-specific database contexts
/// </summary>
public class TenantDbContextFactory : ITenantDbContextFactory<TenantDbContext>
{
    private readonly ITenantService _tenantService;
    private readonly IConfiguration _configuration;

    public TenantDbContextFactory(ITenantService tenantService, IConfiguration configuration)
    {
        _tenantService = tenantService;
        _configuration = configuration;
    }

    public async Task<TenantDbContext> CreateDbContextAsync(string tenantId)
    {
        var connectionString = await _tenantService.GetTenantConnectionStringAsync(tenantId);
        
        var optionsBuilder = new DbContextOptionsBuilder<TenantDbContext>();
        optionsBuilder.UseSqlServer(connectionString, sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        });
        
        return new TenantDbContext(optionsBuilder.Options);
    }

    public TenantDbContext CreateDbContext(string tenantId)
    {
        return CreateDbContextAsync(tenantId).GetAwaiter().GetResult();
    }
}