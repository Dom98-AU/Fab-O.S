using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Infrastructure.Data;

public static class DataSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        // Check if data already exists
        if (await context.Users.AnyAsync())
            return;

        // Ensure default company exists
        var defaultCompany = await context.Companies.FirstOrDefaultAsync(c => c.Code == "DEFAULT");
        if (defaultCompany == null)
        {
            defaultCompany = new Company
            {
                Name = "Default Company",
                Code = "DEFAULT",
                IsActive = true,
                CreatedDate = DateTime.UtcNow
            };
            context.Companies.Add(defaultCompany);
            await context.SaveChangesAsync();
        }

        // Create password hasher
        var passwordHasher = new PasswordHasher<User>();

        // Create admin user
        var adminUser = new User
        {
            Username = "admin",
            Email = "admin@steelestimation.com",
            FirstName = "System",
            LastName = "Administrator",
            CompanyName = "Steel Estimation Platform",
            CompanyId = defaultCompany.Id,
            JobTitle = "System Administrator",
            IsActive = true,
            IsEmailConfirmed = true,
            SecurityStamp = Guid.NewGuid().ToString()
        };
        adminUser.PasswordHash = passwordHasher.HashPassword(adminUser, "Admin@123");

        // Create test users
        var projectManager = new User
        {
            Username = "pmuser",
            Email = "pm@steelestimation.com",
            FirstName = "John",
            LastName = "Smith",
            CompanyName = "ABC Construction",
            CompanyId = defaultCompany.Id,
            JobTitle = "Project Manager",
            IsActive = true,
            IsEmailConfirmed = true,
            SecurityStamp = Guid.NewGuid().ToString()
        };
        projectManager.PasswordHash = passwordHasher.HashPassword(projectManager, "Password@123");

        var estimator = new User
        {
            Username = "estimator1",
            Email = "estimator@steelestimation.com",
            FirstName = "Jane",
            LastName = "Doe",
            CompanyName = "ABC Construction",
            CompanyId = defaultCompany.Id,
            JobTitle = "Senior Estimator",
            IsActive = true,
            IsEmailConfirmed = true,
            SecurityStamp = Guid.NewGuid().ToString()
        };
        estimator.PasswordHash = passwordHasher.HashPassword(estimator, "Password@123");

        // Add users
        context.Users.AddRange(adminUser, projectManager, estimator);
        await context.SaveChangesAsync();

        // Assign roles
        var adminRole = await context.Roles.FirstAsync(r => r.RoleName == "Administrator");
        var pmRole = await context.Roles.FirstAsync(r => r.RoleName == "Project Manager");
        var estimatorRole = await context.Roles.FirstAsync(r => r.RoleName == "Senior Estimator");

        context.UserRoles.AddRange(
            new UserRole { UserId = adminUser.Id, RoleId = adminRole.Id },
            new UserRole { UserId = projectManager.Id, RoleId = pmRole.Id },
            new UserRole { UserId = estimator.Id, RoleId = estimatorRole.Id }
        );

        // Create sample project
        var sampleProject = new Project
        {
            ProjectName = "Sample Steel Building Project",
            JobNumber = "JOB-2024-001",
            EstimationStage = "Preliminary",
            LaborRate = 75.00m,
            OwnerId = projectManager.Id,
            CreatedDate = DateTime.UtcNow
        };

        context.Projects.Add(sampleProject);
        await context.SaveChangesAsync();

        // Add project access
        context.ProjectUsers.AddRange(
            new ProjectUser { ProjectId = sampleProject.Id, UserId = projectManager.Id, AccessLevel = "Owner" },
            new ProjectUser { ProjectId = sampleProject.Id, UserId = estimator.Id, AccessLevel = "ReadWrite" }
        );

        // Add sample processing items
        var processingItems = new List<ProcessingItem>
        {
            new ProcessingItem
            {
                ProjectId = sampleProject.Id,
                DrawingNumber = "A-101",
                Description = "W12x26 Beam",
                MaterialId = "BEAM-W12X26",
                Quantity = 10,
                Length = 20.5m,
                Weight = 26.0m,
                BundleGroup = "Bundle-1",
                PackGroup = "Pack-A"
            },
            new ProcessingItem
            {
                ProjectId = sampleProject.Id,
                DrawingNumber = "A-102",
                Description = "W8x18 Column",
                MaterialId = "COL-W8X18",
                Quantity = 8,
                Length = 12.0m,
                Weight = 18.0m,
                BundleGroup = "Bundle-2",
                PackGroup = "Pack-A"
            },
            new ProcessingItem
            {
                ProjectId = sampleProject.Id,
                DrawingNumber = "A-103",
                Description = "C8x11.5 Channel",
                MaterialId = "CHAN-C8X11.5",
                Quantity = 20,
                Length = 10.0m,
                Weight = 11.5m,
                BundleGroup = "Bundle-3",
                PackGroup = "Pack-B"
            }
        };

        context.ProcessingItems.AddRange(processingItems);

        // Add sample welding items
        var weldingItems = new List<WeldingItem>
        {
            new WeldingItem
            {
                ProjectId = sampleProject.Id,
                DrawingNumber = "W-001",
                LocationComments = "Beam to column connection at grid A-1",
                ConnectionQty = 4,
                AssembleFitTack = 10,
                Weld = 15,
                WeldCheck = 5
            },
            new WeldingItem
            {
                ProjectId = sampleProject.Id,
                DrawingNumber = "W-002",
                LocationComments = "Bracing connections",
                ConnectionQty = 8,
                AssembleFitTack = 5,
                Weld = 8,
                WeldCheck = 3
            }
        };

        context.WeldingItems.AddRange(weldingItems);
        await context.SaveChangesAsync();
    }
}