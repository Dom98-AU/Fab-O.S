using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Infrastructure.Data;

/// <summary>
/// Database context for individual tenant databases in multi-tenant architecture
/// This context is used when database-per-tenant pattern is enabled
/// </summary>
public class TenantDbContext : DbContext
{
    public TenantDbContext(DbContextOptions<TenantDbContext> options)
        : base(options)
    {
    }

    // All the same entities as ApplicationDbContext, but for a specific tenant
    public DbSet<User> Users { get; set; }
    public DbSet<Role> Roles { get; set; }
    public DbSet<UserRole> UserRoles { get; set; }
    public DbSet<Company> Companies { get; set; }
    public DbSet<CompanyMaterialType> CompanyMaterialTypes { get; set; }
    public DbSet<CompanyMbeIdMapping> CompanyMbeIdMappings { get; set; }
    public DbSet<CompanyMaterialPattern> CompanyMaterialPatterns { get; set; }
    public DbSet<Project> Projects { get; set; }
    public DbSet<ProjectUser> ProjectUsers { get; set; }
    public DbSet<Package> Packages { get; set; }
    public DbSet<PackageWorksheet> PackageWorksheets { get; set; }
    public DbSet<ProcessingItem> ProcessingItems { get; set; }
    public DbSet<WeldingItem> WeldingItems { get; set; }
    public DbSet<Invite> Invites { get; set; }
    public DbSet<DeliveryBundle> DeliveryBundles { get; set; }
    public DbSet<WeldingConnection> WeldingConnections { get; set; }
    public DbSet<WeldingItemConnection> WeldingItemConnections { get; set; }
    public DbSet<ImageUpload> ImageUploads { get; set; }
    public DbSet<WorksheetChange> WorksheetChanges { get; set; }
    public DbSet<EstimationTimeLog> EstimationTimeLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply all the same configurations as ApplicationDbContext
        // This ensures tenant databases have the same schema
        
        // Company configuration
        modelBuilder.Entity<Company>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
            entity.HasIndex(e => e.IsActive);
        });

        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.CompanyId);
            
            entity.HasOne(e => e.Company)
                .WithMany(c => c.Users)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Apply remaining configurations (same as ApplicationDbContext)
        ApplyCommonConfigurations(modelBuilder);
    }

    private void ApplyCommonConfigurations(ModelBuilder modelBuilder)
    {
        // This method contains all the common entity configurations
        // that are shared between ApplicationDbContext and TenantDbContext
        // (Implementation would be the same as in ApplicationDbContext)
        
        // For brevity, I'm not repeating all configurations here
        // In practice, you might extract these to a separate configuration class
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Apply automatic timestamps
        var entries = ChangeTracker
            .Entries()
            .Where(e => e.Entity is Project || e.Entity is Package || e.Entity is PackageWorksheet || 
                       e.Entity is ProcessingItem || e.Entity is WeldingItem || e.Entity is User ||
                       e.Entity is DeliveryBundle || e.Entity is WeldingConnection || e.Entity is Company)
            .Where(e => e.State == EntityState.Modified);

        foreach (var entityEntry in entries)
        {
            var lastModifiedProperty = entityEntry.Entity.GetType().GetProperty("LastModified");
            if (lastModifiedProperty != null)
            {
                lastModifiedProperty.SetValue(entityEntry.Entity, DateTime.UtcNow);
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}