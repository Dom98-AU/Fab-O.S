using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Infrastructure.Data;

/// <summary>
/// Master database context for managing tenant registry in multi-tenant architecture
/// This context manages the central tenant directory when database-per-tenant is enabled
/// </summary>
public class MasterDbContext : DbContext
{
    public MasterDbContext(DbContextOptions<MasterDbContext> options)
        : base(options)
    {
    }

    public DbSet<TenantRegistry> TenantRegistries { get; set; }
    public DbSet<TenantUsageLog> TenantUsageLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // TenantRegistry configuration
        modelBuilder.Entity<TenantRegistry>(entity =>
        {
            entity.HasIndex(e => e.TenantId).IsUnique();
            entity.HasIndex(e => e.CompanyCode).IsUnique();
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.CreatedAt);
            
            // Configure JSON column for settings (SQL Server 2016+)
            entity.Property(e => e.Settings)
                .HasConversion(
                    v => System.Text.Json.JsonSerializer.Serialize(v, (System.Text.Json.JsonSerializerOptions?)null),
                    v => System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(v, (System.Text.Json.JsonSerializerOptions?)null) ?? new Dictionary<string, string>()
                );
        });

        // TenantUsageLog configuration
        modelBuilder.Entity<TenantUsageLog>(entity =>
        {
            entity.HasIndex(e => e.TenantId);
            entity.HasIndex(e => e.LogDate);
            entity.HasIndex(e => new { e.TenantId, e.LogDate });
            
            entity.HasOne(e => e.TenantRegistry)
                .WithMany(t => t.UsageLogs)
                .HasForeignKey(e => e.TenantRegistryId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.Property(e => e.DatabaseSizeGB).HasPrecision(10, 3);
        });
    }
}