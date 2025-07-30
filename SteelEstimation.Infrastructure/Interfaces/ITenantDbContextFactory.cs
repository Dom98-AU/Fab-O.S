using Microsoft.EntityFrameworkCore;

namespace SteelEstimation.Infrastructure.Interfaces;

public interface ITenantDbContextFactory<TContext> where TContext : DbContext
{
    Task<TContext> CreateDbContextAsync(string tenantId);
    TContext CreateDbContext(string tenantId);
}