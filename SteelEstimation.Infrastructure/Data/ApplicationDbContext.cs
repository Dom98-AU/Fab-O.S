using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);
        
        // Query splitting is configured in Program.cs
    }

    // Authentication
    public DbSet<User> Users { get; set; }
    public DbSet<Role> Roles { get; set; }
    public DbSet<UserRole> UserRoles { get; set; }
    public DbSet<UserAuthMethod> UserAuthMethods { get; set; }
    public DbSet<SocialLoginAudit> SocialLoginAudits { get; set; }
    public DbSet<OAuthProviderSettings> OAuthProviderSettings { get; set; }
    
    // Settings
    public DbSet<Setting> Settings { get; set; }
    
    // Multi-Company (used in both single-tenant and multi-tenant modes)
    public DbSet<Company> Companies { get; set; }
    public DbSet<CompanyMaterialType> CompanyMaterialTypes { get; set; }
    public DbSet<CompanyMbeIdMapping> CompanyMbeIdMappings { get; set; }
    public DbSet<CompanyMaterialPattern> CompanyMaterialPatterns { get; set; }
    public DbSet<EfficiencyRate> EfficiencyRates { get; set; }
    
    // Customer Management
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Contact> Contacts { get; set; }
    public DbSet<Address> Addresses { get; set; }
    
    // Reference Data
    public DbSet<Postcode> Postcodes { get; set; }
    
    // Multi-Tenant Registry (only used when EnableDatabasePerTenant is true)
    public DbSet<TenantRegistry>? TenantRegistries { get; set; }
    public DbSet<TenantUsageLog>? TenantUsageLogs { get; set; }
    
    // Projects
    public DbSet<Project> Projects { get; set; }
    public DbSet<ProjectUser> ProjectUsers { get; set; }
    public DbSet<Package> Packages { get; set; }
    public DbSet<PackageWorksheet> PackageWorksheets { get; set; }
    public DbSet<ProcessingItem> ProcessingItems { get; set; }
    public DbSet<WeldingItem> WeldingItems { get; set; }
    public DbSet<Invite> Invites { get; set; }
    public DbSet<DeliveryBundle> DeliveryBundles { get; set; }
    public DbSet<PackBundle> PackBundles { get; set; }
    public DbSet<WeldingConnection> WeldingConnections { get; set; }
    public DbSet<WeldingItemConnection> WeldingItemConnections { get; set; }
    public DbSet<ImageUpload> ImageUploads { get; set; }
    public DbSet<WorksheetChange> WorksheetChanges { get; set; }
    public DbSet<EstimationTimeLog> EstimationTimeLogs { get; set; }
    
    // Worksheet Templates
    public DbSet<WorksheetTemplate> WorksheetTemplates { get; set; }
    public DbSet<WorksheetTemplateField> WorksheetTemplateFields { get; set; }
    public DbSet<FieldDependency> FieldDependencies { get; set; }
    public DbSet<UserWorksheetPreference> UserWorksheetPreferences { get; set; }
    public DbSet<WorksheetColumnView> WorksheetColumnViews { get; set; }
    public DbSet<WorksheetColumnOrder> WorksheetColumnOrders { get; set; }
    
    // Table Views
    public DbSet<TableView> TableViews { get; set; }
    
    // Feature Access
    public DbSet<FeatureCache> FeatureCache { get; set; }
    public DbSet<FeatureGroup> FeatureGroups { get; set; }
    public DbSet<ApiKey> ApiKeys { get; set; }
    
    // Product Licensing (Fab.OS)
    public DbSet<ProductLicense> ProductLicenses { get; set; }
    public DbSet<UserProductAccess> UserProductAccess { get; set; }
    public DbSet<ProductRole> ProductRoles { get; set; }
    public DbSet<UserProductRole> UserProductRoles { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Company configuration
        modelBuilder.Entity<Company>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
            entity.HasIndex(e => e.IsActive);
        });

        // Company Material Type configuration
        modelBuilder.Entity<CompanyMaterialType>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.TypeName }).IsUnique();
            entity.HasIndex(e => e.CompanyId);
            
            entity.Property(e => e.HourlyRate).HasPrecision(10, 2);
            entity.Property(e => e.DefaultWeightPerFoot).HasPrecision(10, 4);
            
            entity.HasOne(e => e.Company)
                .WithMany(c => c.MaterialTypes)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Company MBE ID Mapping configuration
        modelBuilder.Entity<CompanyMbeIdMapping>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.MbeId }).IsUnique();
            entity.HasIndex(e => e.CompanyId);
            
            entity.Property(e => e.WeightPerFoot).HasPrecision(10, 4);
            
            entity.HasOne(e => e.Company)
                .WithMany(c => c.MbeIdMappings)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Company Material Pattern configuration
        modelBuilder.Entity<CompanyMaterialPattern>(entity =>
        {
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => new { e.CompanyId, e.PatternType });
            
            entity.HasOne(e => e.Company)
                .WithMany(c => c.MaterialPatterns)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // EfficiencyRate configuration
        modelBuilder.Entity<EfficiencyRate>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.Name }).IsUnique();
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.IsDefault);
            
            entity.Property(e => e.EfficiencyPercentage).HasPrecision(5, 2);
            
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // TenantRegistry configuration (for multi-tenant mode)
        modelBuilder.Entity<TenantRegistry>(entity =>
        {
            entity.HasIndex(e => e.TenantId).IsUnique();
            entity.HasIndex(e => e.CompanyCode).IsUnique();
            entity.HasIndex(e => e.IsActive);
            
            // Ignore the Settings dictionary property as EF can't map it directly
            entity.Ignore(e => e.Settings);
        });

        // TenantUsageLog configuration (for multi-tenant mode)
        modelBuilder.Entity<TenantUsageLog>(entity =>
        {
            entity.HasIndex(e => e.TenantId);
            entity.HasIndex(e => e.LogDate);
            
            entity.Property(e => e.DatabaseSizeGB).HasPrecision(10, 4);
        });

        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).HasFilter("[IsActive] = 1").IsUnique();
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => new { e.AuthProvider, e.ExternalUserId });
            entity.HasIndex(e => e.CompanyId);
            
            entity.HasOne(e => e.Company)
                .WithMany(c => c.Users)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Role configuration
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasIndex(e => e.RoleName).IsUnique();
        });

        // UserRole configuration
        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.RoleId });

            entity.HasOne(e => e.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(e => e.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.AssignedByUser)
                .WithMany()
                .HasForeignKey(e => e.AssignedBy)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // UserAuthMethod configuration
        modelBuilder.Entity<UserAuthMethod>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => new { e.AuthProvider, e.ExternalUserId });
            entity.HasIndex(e => new { e.UserId, e.AuthProvider })
                .HasFilter("[IsActive] = 1")
                .IsUnique();
            
            entity.HasOne(e => e.User)
                .WithMany(u => u.AuthMethods)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // SocialLoginAudit configuration
        modelBuilder.Entity<SocialLoginAudit>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.EventDate);
            entity.HasIndex(e => new { e.AuthProvider, e.EventType });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // OAuthProviderSettings configuration
        modelBuilder.Entity<OAuthProviderSettings>(entity =>
        {
            entity.HasIndex(e => e.ProviderName).IsUnique();
            entity.HasIndex(e => e.SortOrder);
        });

        // Project configuration
        modelBuilder.Entity<Project>(entity =>
        {
            entity.HasIndex(e => e.JobNumber);
            entity.HasIndex(e => e.CreatedDate);
            entity.HasIndex(e => e.IsDeleted);

            entity.HasOne(e => e.Owner)
                .WithMany(u => u.OwnedProjects)
                .HasForeignKey(e => e.OwnerId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.LastModifiedByUser)
                .WithMany()
                .HasForeignKey(e => e.LastModifiedBy)
                .OnDelete(DeleteBehavior.NoAction);

            // Fix decimal precision warnings
            entity.Property(e => e.ContingencyPercentage).HasPrecision(5, 2);
            entity.Property(e => e.LaborRate).HasPrecision(10, 2);
            entity.Property(e => e.EstimatedHours).HasPrecision(10, 2);
        });

        // ProjectUser configuration
        modelBuilder.Entity<ProjectUser>(entity =>
        {
            entity.HasKey(e => new { e.ProjectId, e.UserId });

            entity.HasOne(e => e.Project)
                .WithMany(p => p.ProjectUsers)
                .HasForeignKey(e => e.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.User)
                .WithMany(u => u.ProjectAccess)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.GrantedByUser)
                .WithMany()
                .HasForeignKey(e => e.GrantedBy)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasIndex(e => e.UserId);
        });

        // Package configuration
        modelBuilder.Entity<Package>(entity =>
        {
            entity.HasIndex(e => e.ProjectId);
            entity.HasIndex(e => e.PackageNumber);
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.IsDeleted);
            
            // Configure LaborRatePerHour with default value
            entity.Property(e => e.LaborRatePerHour)
                .HasPrecision(10, 2)
                .HasDefaultValue(0m);

            entity.HasOne(e => e.Project)
                .WithMany(p => p.Packages)
                .HasForeignKey(e => e.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.LastModifiedByUser)
                .WithMany()
                .HasForeignKey(e => e.LastModifiedBy)
                .OnDelete(DeleteBehavior.NoAction);
                
            entity.HasOne(e => e.EfficiencyRate)
                .WithMany(e => e.Packages)
                .HasForeignKey(e => e.EfficiencyRateId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.Property(e => e.EstimatedHours).HasPrecision(10, 2);
            entity.Property(e => e.EstimatedCost).HasPrecision(18, 2);
            entity.Property(e => e.ActualHours).HasPrecision(10, 2);
            entity.Property(e => e.ActualCost).HasPrecision(18, 2);
            
            // Configure ProcessingEfficiency
            entity.Property(e => e.ProcessingEfficiency)
                .HasPrecision(18, 2)
                .HasDefaultValue(100m);
        });

        // PackageWorksheet configuration
        modelBuilder.Entity<PackageWorksheet>(entity =>
        {
            entity.HasIndex(e => e.PackageId);
            entity.HasIndex(e => e.WorksheetType);

            entity.HasOne(e => e.Package)
                .WithMany(p => p.Worksheets)
                .HasForeignKey(e => e.PackageId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.TotalHours).HasPrecision(10, 2);
            entity.Property(e => e.TotalCost).HasPrecision(18, 2);
        });

        // ProcessingItem configuration
        modelBuilder.Entity<ProcessingItem>(entity =>
        {
            entity.HasIndex(e => e.ProjectId);
            entity.HasIndex(e => e.PackageWorksheetId);
            entity.HasIndex(e => e.BundleGroup);
            entity.HasIndex(e => e.MaterialId);
            entity.HasIndex(e => e.DeliveryBundleId);
            entity.HasIndex(e => e.PackBundleId);

            entity.HasOne(e => e.Project)
                .WithMany(p => p.ProcessingItems)
                .HasForeignKey(e => e.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.PackageWorksheet)
                .WithMany(w => w.ProcessingItems)
                .HasForeignKey(e => e.PackageWorksheetId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.HasOne(e => e.DeliveryBundle)
                .WithMany(b => b.ProcessingItems)
                .HasForeignKey(e => e.DeliveryBundleId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(e => e.PackBundle)
                .WithMany(b => b.ProcessingItems)
                .HasForeignKey(e => e.PackBundleId)
                .OnDelete(DeleteBehavior.NoAction);

            entity.Property(e => e.Weight).HasPrecision(10, 3);
            entity.Property(e => e.Length).HasPrecision(10, 2);
        });

        // WeldingItem configuration
        modelBuilder.Entity<WeldingItem>(entity =>
        {
            entity.HasIndex(e => e.ProjectId);
            entity.HasIndex(e => e.PackageWorksheetId);

            entity.HasOne(e => e.Project)
                .WithMany(p => p.WeldingItems)
                .HasForeignKey(e => e.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.PackageWorksheet)
                .WithMany(w => w.WeldingItems)
                .HasForeignKey(e => e.PackageWorksheetId)
                .OnDelete(DeleteBehavior.NoAction);

            // Fix decimal precision warning
            entity.Property(e => e.WeldLength).HasPrecision(10, 2);
            entity.Property(e => e.AssembleFitTack).HasPrecision(10, 2);
            entity.Property(e => e.Weld).HasPrecision(10, 2);
            entity.Property(e => e.WeldCheck).HasPrecision(10, 2);
            entity.Property(e => e.WeldTest).HasPrecision(10, 2);
            
            entity.HasOne(e => e.WeldingConnection)
                .WithMany(w => w.WeldingItems)
                .HasForeignKey(e => e.WeldingConnectionId)
                .OnDelete(DeleteBehavior.SetNull);
        });
        
        // WeldingConnection configuration
        modelBuilder.Entity<WeldingConnection>(entity =>
        {
            entity.HasIndex(e => e.PackageId);
            entity.HasIndex(e => new { e.Category, e.Size });
            entity.HasIndex(e => e.DisplayOrder);
            
            entity.HasOne(e => e.Package)
                .WithMany(p => p.WeldingConnections)
                .HasForeignKey(e => e.PackageId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.Property(e => e.DefaultAssembleFitTack).HasPrecision(10, 2);
            entity.Property(e => e.DefaultWeld).HasPrecision(10, 2);
            entity.Property(e => e.DefaultWeldCheck).HasPrecision(10, 2);
            entity.Property(e => e.DefaultWeldTest).HasPrecision(10, 2);
        });
        
        // ImageUpload configuration
        modelBuilder.Entity<ImageUpload>(entity =>
        {
            entity.HasIndex(e => e.WeldingItemId);
            entity.HasIndex(e => e.UploadedDate);
            
            entity.HasOne(e => e.WeldingItem)
                .WithMany(w => w.Images)
                .HasForeignKey(e => e.WeldingItemId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.UploadedByUser)
                .WithMany()
                .HasForeignKey(e => e.UploadedBy)
                .OnDelete(DeleteBehavior.NoAction);
        });
        
        // WorksheetChange configuration
        modelBuilder.Entity<WorksheetChange>(entity =>
        {
            entity.HasIndex(e => e.PackageWorksheetId);
            entity.HasIndex(e => e.Timestamp);
            entity.HasIndex(e => new { e.EntityType, e.EntityId });
            
            entity.HasOne(e => e.PackageWorksheet)
                .WithMany(w => w.Changes)
                .HasForeignKey(e => e.PackageWorksheetId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // DeliveryBundle configuration
        modelBuilder.Entity<DeliveryBundle>(entity =>
        {
            entity.HasIndex(e => e.PackageId);
            entity.HasIndex(e => e.BundleNumber);

            entity.HasOne(e => e.Package)
                .WithMany(p => p.DeliveryBundles)
                .HasForeignKey(e => e.PackageId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.TotalWeight).HasPrecision(10, 3);
        });

        // PackBundle configuration
        modelBuilder.Entity<PackBundle>(entity =>
        {
            entity.HasIndex(e => e.PackageId);
            entity.HasIndex(e => e.BundleNumber);

            entity.HasOne(e => e.Package)
                .WithMany(p => p.PackBundles)
                .HasForeignKey(e => e.PackageId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.TotalWeight).HasPrecision(10, 3);
        });

        // Invite configuration
        modelBuilder.Entity<Invite>(entity =>
        {
            entity.HasIndex(e => e.Email);
            entity.HasIndex(e => e.Token).IsUnique();
            entity.HasIndex(e => e.IsUsed);
            entity.HasIndex(e => e.ExpiryDate);

            entity.HasOne(e => e.InvitedByUser)
                .WithMany()
                .HasForeignKey(e => e.InvitedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Role)
                .WithMany()
                .HasForeignKey(e => e.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // WeldingItemConnection configuration
        modelBuilder.Entity<WeldingItemConnection>(entity =>
        {
            entity.HasIndex(e => new { e.WeldingItemId, e.WeldingConnectionId }).IsUnique();
            
            entity.HasOne(e => e.WeldingItem)
                .WithMany(w => w.ItemConnections)
                .HasForeignKey(e => e.WeldingItemId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.WeldingConnection)
                .WithMany()
                .HasForeignKey(e => e.WeldingConnectionId)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.Property(e => e.AssembleFitTack).HasPrecision(10, 2);
            entity.Property(e => e.Weld).HasPrecision(10, 2);
            entity.Property(e => e.WeldCheck).HasPrecision(10, 2);
            entity.Property(e => e.WeldTest).HasPrecision(10, 2);
        });
        
        // EstimationTimeLog configuration
        modelBuilder.Entity<EstimationTimeLog>(entity =>
        {
            entity.HasIndex(e => e.EstimationId);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.SessionId);
            entity.HasIndex(e => e.StartTime);
            entity.HasIndex(e => e.IsActive);
            
            // Explicitly configure the foreign key to Project table
            entity.Property(e => e.EstimationId)
                .HasColumnName("EstimationId");
            
            entity.HasOne(e => e.Estimation)
                .WithMany()
                .HasForeignKey(e => e.EstimationId)
                .HasConstraintName("FK_EstimationTimeLogs_Projects_EstimationId")
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Customer configuration
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.ABN }).IsUnique();
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.CompanyName);
            
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.BillingAddress)
                .WithMany(a => a.BillingCustomers)
                .HasForeignKey(e => e.BillingAddressId)
                .OnDelete(DeleteBehavior.SetNull);
                
            entity.HasOne(e => e.ShippingAddress)
                .WithMany(a => a.ShippingCustomers)
                .HasForeignKey(e => e.ShippingAddressId)
                .OnDelete(DeleteBehavior.SetNull);
                
            entity.HasOne(e => e.CreatedBy)
                .WithMany()
                .HasForeignKey(e => e.CreatedById)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.ModifiedBy)
                .WithMany()
                .HasForeignKey(e => e.ModifiedById)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Contact configuration
        modelBuilder.Entity<Contact>(entity =>
        {
            entity.HasIndex(e => e.CustomerId);
            entity.HasIndex(e => e.Email);
            entity.HasIndex(e => e.IsActive);
            
            entity.HasOne(e => e.Customer)
                .WithMany(c => c.Contacts)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Address configuration
        modelBuilder.Entity<Address>(entity =>
        {
            entity.HasIndex(e => e.PostCode);
            entity.HasIndex(e => e.State);
        });

        // Update Project configuration for Customer relationship
        modelBuilder.Entity<Project>(entity =>
        {
            entity.HasOne(e => e.Customer)
                .WithMany(c => c.Projects)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Postcode configuration
        modelBuilder.Entity<Postcode>(entity =>
        {
            entity.HasIndex(e => e.Code);
            entity.HasIndex(e => e.Suburb);
            entity.HasIndex(e => new { e.Suburb, e.State });
            entity.HasIndex(e => e.IsActive);
            
            entity.Property(e => e.Latitude).HasPrecision(10, 6);
            entity.Property(e => e.Longitude).HasPrecision(10, 6);
        });

        // Worksheet Template configuration
        modelBuilder.Entity<WorksheetTemplate>(entity =>
        {
            entity.HasIndex(e => e.BaseType);
            entity.HasIndex(e => e.CreatedByUserId);
            entity.HasIndex(e => e.IsGlobal);
            
            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Worksheet Template Field configuration
        modelBuilder.Entity<WorksheetTemplateField>(entity =>
        {
            entity.HasIndex(e => e.WorksheetTemplateId);
            entity.HasIndex(e => new { e.WorksheetTemplateId, e.FieldName }).IsUnique();
            
            entity.HasOne(e => e.WorksheetTemplate)
                .WithMany(t => t.Fields)
                .HasForeignKey(e => e.WorksheetTemplateId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Field Dependency configuration
        modelBuilder.Entity<FieldDependency>(entity =>
        {
            entity.HasIndex(e => new { e.BaseType, e.FieldName });
        });

        // User Worksheet Preference configuration
        modelBuilder.Entity<UserWorksheetPreference>(entity =>
        {
            entity.HasIndex(e => new { e.UserId, e.BaseType }).IsUnique();
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Template)
                .WithMany()
                .HasForeignKey(e => e.TemplateId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Update PackageWorksheet configuration for Template relationship
        modelBuilder.Entity<PackageWorksheet>(entity =>
        {
            entity.HasOne(e => e.WorksheetTemplate)
                .WithMany(t => t.PackageWorksheets)
                .HasForeignKey(e => e.WorksheetTemplateId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // FeatureCache configuration
        modelBuilder.Entity<FeatureCache>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.FeatureCode }).IsUnique();
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => e.ExpiresAt);
            
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // FeatureGroup configuration
        modelBuilder.Entity<FeatureGroup>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
            entity.HasIndex(e => e.DisplayOrder);
            entity.HasIndex(e => e.IsActive);
        });

        // ApiKey configuration
        modelBuilder.Entity<ApiKey>(entity =>
        {
            entity.HasIndex(e => e.KeyPrefix);
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.ExpiresAt);
        });

        // WorksheetColumnView configuration
        modelBuilder.Entity<WorksheetColumnView>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => new { e.UserId, e.CompanyId, e.WorksheetType });
            entity.HasIndex(e => new { e.UserId, e.CompanyId, e.IsDefault });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // WorksheetColumnOrder configuration
        modelBuilder.Entity<WorksheetColumnOrder>(entity =>
        {
            entity.HasIndex(e => e.WorksheetColumnViewId);
            entity.HasIndex(e => new { e.WorksheetColumnViewId, e.ColumnName }).IsUnique();
            entity.HasIndex(e => new { e.WorksheetColumnViewId, e.DisplayOrder });
            
            entity.HasOne(e => e.WorksheetColumnView)
                .WithMany(v => v.ColumnOrders)
                .HasForeignKey(e => e.WorksheetColumnViewId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // TableView configuration
        modelBuilder.Entity<TableView>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.CompanyId);
            entity.HasIndex(e => new { e.UserId, e.CompanyId, e.TableType });
            entity.HasIndex(e => new { e.CompanyId, e.TableType, e.IsShared });
            entity.HasIndex(e => new { e.UserId, e.CompanyId, e.IsDefault });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Product Licensing configuration
        modelBuilder.Entity<ProductLicense>(entity =>
        {
            entity.HasIndex(e => new { e.CompanyId, e.ProductName });
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.ValidUntil);
            
            entity.Property(e => e.Features)
                .HasConversion(
                    v => v == null ? null : string.Join(',', v),
                    v => v == null ? new List<string>() : v.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList()
                );
            
            entity.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.ModifiedByUser)
                .WithMany()
                .HasForeignKey(e => e.ModifiedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // UserProductAccess configuration
        modelBuilder.Entity<UserProductAccess>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.ProductLicenseId);
            entity.HasIndex(e => new { e.ProductLicenseId, e.IsCurrentlyActive });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.ProductLicense)
                .WithMany(p => p.UserAccess)
                .HasForeignKey(e => e.ProductLicenseId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ProductRole configuration
        modelBuilder.Entity<ProductRole>(entity =>
        {
            entity.HasIndex(e => new { e.ProductName, e.RoleName }).IsUnique();
            
            entity.Property(e => e.Permissions)
                .HasConversion(
                    v => v == null ? null : System.Text.Json.JsonSerializer.Serialize(v, (System.Text.Json.JsonSerializerOptions)null),
                    v => v == null ? new Dictionary<string, object>() : System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(v, (System.Text.Json.JsonSerializerOptions)null)
                );
        });

        // UserProductRole configuration
        modelBuilder.Entity<UserProductRole>(entity =>
        {
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.ProductRoleId);
            entity.HasIndex(e => new { e.UserId, e.ProductRoleId }).IsUnique();
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.ProductRole)
                .WithMany(p => p.UserProductRoles)
                .HasForeignKey(e => e.ProductRoleId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.AssignedByUser)
                .WithMany()
                .HasForeignKey(e => e.AssignedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Seed default roles
        modelBuilder.Entity<Role>().HasData(
            new Role { Id = 1, RoleName = "Administrator", Description = "Full system access", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = true, CanViewAllProjects = true, CanManageUsers = true, CanExportData = true, CanImportData = true },
            new Role { Id = 2, RoleName = "Project Manager", Description = "Can manage all projects and users", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = true, CanViewAllProjects = true, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { Id = 3, RoleName = "Senior Estimator", Description = "Can create and edit projects", CanCreateProjects = true, CanEditProjects = true, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { Id = 4, RoleName = "Estimator", Description = "Can edit assigned projects", CanCreateProjects = false, CanEditProjects = true, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = true },
            new Role { Id = 5, RoleName = "Viewer", Description = "Read-only access to assigned projects", CanCreateProjects = false, CanEditProjects = false, CanDeleteProjects = false, CanViewAllProjects = false, CanManageUsers = false, CanExportData = true, CanImportData = false }
        );
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var entries = ChangeTracker
            .Entries()
            .Where(e => e.Entity is Project || e.Entity is Package || e.Entity is PackageWorksheet || 
                       e.Entity is ProcessingItem || e.Entity is WeldingItem || e.Entity is User ||
                       e.Entity is DeliveryBundle || e.Entity is PackBundle || e.Entity is WeldingConnection)
            .Where(e => e.State == EntityState.Modified);

        foreach (var entityEntry in entries)
        {
            if (entityEntry.Entity is Project project)
            {
                project.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is Package package)
            {
                package.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is PackageWorksheet worksheet)
            {
                worksheet.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is ProcessingItem processingItem)
            {
                processingItem.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is WeldingItem weldingItem)
            {
                weldingItem.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is User user)
            {
                user.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is DeliveryBundle bundle)
            {
                bundle.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is PackBundle packBundle)
            {
                packBundle.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is WeldingConnection connection)
            {
                connection.LastModified = DateTime.UtcNow;
            }
            else if (entityEntry.Entity is WorksheetTemplate template)
            {
                template.LastModified = DateTime.UtcNow;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}