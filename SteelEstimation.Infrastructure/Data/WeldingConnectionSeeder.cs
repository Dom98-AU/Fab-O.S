using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Infrastructure.Data;

public static class WeldingConnectionSeeder
{
    public static async Task SeedDefaultConnections(ApplicationDbContext context)
    {
        // Check if we already have connections
        if (await context.WeldingConnections.AnyAsync())
            return;
            
        var connections = new List<WeldingConnection>
        {
            // Baseplate Connections
            new() { Name = "Small Baseplate Connection", Category = "Baseplate", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 1 },
            new() { Name = "Large Baseplate Connection", Category = "Baseplate", Size = "Large", 
                    DefaultAssembleFitTack = 5.0m, DefaultWeld = 5.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 2 },
                    
            // Stiffener Connections
            new() { Name = "Small Stiffener Connection", Category = "Stiffener", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 3 },
            new() { Name = "Large Stiffener Connection", Category = "Stiffener", Size = "Large", 
                    DefaultAssembleFitTack = 4.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 4 },
                    
            // Gusset Connections
            new() { Name = "Small Gusset Connection", Category = "Gusset", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 5 },
            new() { Name = "Large Gusset Connection", Category = "Gusset", Size = "Large", 
                    DefaultAssembleFitTack = 4.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 6 },
                    
            // Purlin Connections
            new() { Name = "Small Purlin Connection", Category = "Purlin", Size = "Small", 
                    DefaultAssembleFitTack = 1.5m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 7 },
            new() { Name = "Large Purlin Connection", Category = "Purlin", Size = "Large", 
                    DefaultAssembleFitTack = 3.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 8 },
                    
            // Cleat Connections
            new() { Name = "Small Cleat Connection", Category = "Cleat", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 9 },
            new() { Name = "Large Cleat Connection", Category = "Cleat", Size = "Large", 
                    DefaultAssembleFitTack = 5.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 10 },
                    
            // End Plate Connections
            new() { Name = "Small End Plate Connection", Category = "End Plate", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 11 },
            new() { Name = "Large End Plate Connection", Category = "End Plate", Size = "Large", 
                    DefaultAssembleFitTack = 5.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 12 },
                    
            // Wall Plate Connections
            new() { Name = "Small Wall Plate Connection", Category = "Wall Plate", Size = "Small", 
                    DefaultAssembleFitTack = 1.5m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 13 },
            new() { Name = "Large Wall Plate Connection", Category = "Wall Plate", Size = "Large", 
                    DefaultAssembleFitTack = 3.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 14 },
                    
            // Fin Plate Connections
            new() { Name = "Small Fin Plate Connection", Category = "Fin Plate", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 15 },
            new() { Name = "Large Fin Plate Connection", Category = "Fin Plate", Size = "Large", 
                    DefaultAssembleFitTack = 4.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 16 },
                    
            // Cap Plate Connections
            new() { Name = "Small Cap Plate Connection", Category = "Cap Plate", Size = "Small", 
                    DefaultAssembleFitTack = 2.0m, DefaultWeld = 1.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 17 },
            new() { Name = "Large Cap Plate Connection", Category = "Cap Plate", Size = "Large", 
                    DefaultAssembleFitTack = 4.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 18 },
                    
            // Bearing Plate Connections
            new() { Name = "Small Bearing Plate Connection", Category = "Bearing Plate", Size = "Small", 
                    DefaultAssembleFitTack = 3.0m, DefaultWeld = 2.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 19 },
            new() { Name = "Large Bearing Plate Connection", Category = "Bearing Plate", Size = "Large", 
                    DefaultAssembleFitTack = 5.0m, DefaultWeld = 2.5m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 20 },
                    
            // Mitre Joint Welding
            new() { Name = "Small Mitre Joint Welding", Category = "Mitre Joint", Size = "Small", 
                    DefaultAssembleFitTack = 4.5m, DefaultWeld = 4.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 21 },
            new() { Name = "Large Mitre Joint Welding", Category = "Mitre Joint", Size = "Large", 
                    DefaultAssembleFitTack = 6.0m, DefaultWeld = 6.0m, DefaultWeldCheck = 1.0m, DefaultWeldTest = 0m, DisplayOrder = 22 }
        };
        
        context.WeldingConnections.AddRange(connections);
        await context.SaveChangesAsync();
    }
}