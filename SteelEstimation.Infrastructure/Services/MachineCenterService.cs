using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class MachineCenterService : IMachineCenterService
{
    private readonly ApplicationDbContext _context;

    public MachineCenterService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<MachineCenter>> GetAllMachineCentersAsync(int companyId)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Include(m => m.Capabilities)
            .Include(m => m.Operators)
                .ThenInclude(o => o.User)
            .Where(m => m.CompanyId == companyId && !m.IsDeleted)
            .OrderBy(m => m.MachineCode)
            .ToListAsync();
    }

    public async Task<IEnumerable<MachineCenter>> GetMachineCentersByWorkCenterAsync(int workCenterId)
    {
        return await _context.MachineCenters
            .Include(m => m.Capabilities)
            .Include(m => m.Operators)
            .Where(m => m.WorkCenterId == workCenterId && !m.IsDeleted)
            .OrderBy(m => m.MachineCode)
            .ToListAsync();
    }

    public async Task<MachineCenter?> GetMachineCenterByIdAsync(int id)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Include(m => m.Capabilities)
            .Include(m => m.Operators)
                .ThenInclude(o => o.User)
            .FirstOrDefaultAsync(m => m.Id == id && !m.IsDeleted);
    }

    public async Task<MachineCenter?> GetMachineCenterByCodeAsync(string machineCode, int companyId)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Include(m => m.Capabilities)
            .Include(m => m.Operators)
            .FirstOrDefaultAsync(m => m.MachineCode == machineCode && m.CompanyId == companyId && !m.IsDeleted);
    }

    public async Task<MachineCenter> CreateMachineCenterAsync(MachineCenter machineCenter)
    {
        machineCenter.CreatedDate = DateTime.UtcNow;
        machineCenter.LastModified = DateTime.UtcNow;
        
        _context.MachineCenters.Add(machineCenter);
        await _context.SaveChangesAsync();
        return machineCenter;
    }

    public async Task<MachineCenter> UpdateMachineCenterAsync(MachineCenter machineCenter)
    {
        var existing = await _context.MachineCenters.FindAsync(machineCenter.Id);
        if (existing == null)
            throw new InvalidOperationException($"Machine center with ID {machineCenter.Id} not found");

        existing.MachineCode = machineCenter.MachineCode;
        existing.MachineName = machineCenter.MachineName;
        existing.Description = machineCenter.Description;
        existing.WorkCenterId = machineCenter.WorkCenterId;
        existing.Manufacturer = machineCenter.Manufacturer;
        existing.Model = machineCenter.Model;
        existing.SerialNumber = machineCenter.SerialNumber;
        existing.PurchaseDate = machineCenter.PurchaseDate;
        existing.PurchasePrice = machineCenter.PurchasePrice;
        existing.MachineType = machineCenter.MachineType;
        existing.MachineSubType = machineCenter.MachineSubType;
        existing.MaxCapacity = machineCenter.MaxCapacity;
        existing.CapacityUnit = machineCenter.CapacityUnit;
        existing.SetupTimeMinutes = machineCenter.SetupTimeMinutes;
        existing.WarmupTimeMinutes = machineCenter.WarmupTimeMinutes;
        existing.CooldownTimeMinutes = machineCenter.CooldownTimeMinutes;
        existing.HourlyRate = machineCenter.HourlyRate;
        existing.PowerConsumptionKwh = machineCenter.PowerConsumptionKwh;
        existing.PowerCostPerKwh = machineCenter.PowerCostPerKwh;
        existing.EfficiencyPercentage = machineCenter.EfficiencyPercentage;
        existing.QualityRate = machineCenter.QualityRate;
        existing.AvailabilityRate = machineCenter.AvailabilityRate;
        existing.IsActive = machineCenter.IsActive;
        existing.CurrentStatus = machineCenter.CurrentStatus;
        existing.LastMaintenanceDate = machineCenter.LastMaintenanceDate;
        existing.NextMaintenanceDate = machineCenter.NextMaintenanceDate;
        existing.MaintenanceIntervalHours = machineCenter.MaintenanceIntervalHours;
        existing.CurrentOperatingHours = machineCenter.CurrentOperatingHours;
        existing.RequiresTooling = machineCenter.RequiresTooling;
        existing.ToolingRequirements = machineCenter.ToolingRequirements;
        existing.LastModified = DateTime.UtcNow;
        existing.LastModifiedByUserId = machineCenter.LastModifiedByUserId;

        await _context.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteMachineCenterAsync(int id)
    {
        var machineCenter = await _context.MachineCenters.FindAsync(id);
        if (machineCenter == null)
            return false;

        machineCenter.IsDeleted = true;
        machineCenter.LastModified = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> MachineCenterExistsAsync(string machineCode, int companyId, int? excludeId = null)
    {
        var query = _context.MachineCenters
            .Where(m => m.MachineCode == machineCode && m.CompanyId == companyId && !m.IsDeleted);

        if (excludeId.HasValue)
            query = query.Where(m => m.Id != excludeId.Value);

        return await query.AnyAsync();
    }

    public async Task<bool> UpdateMachineStatusAsync(int machineCenterId, string status)
    {
        var machine = await _context.MachineCenters.FindAsync(machineCenterId);
        if (machine == null)
            return false;

        var validStatuses = new[] { "Available", "InUse", "Maintenance", "Breakdown" };
        if (!validStatuses.Contains(status))
            throw new ArgumentException($"Invalid status: {status}");

        machine.CurrentStatus = status;
        machine.LastModified = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<MachineCenter>> GetAvailableMachinesAsync(int companyId)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Where(m => m.CompanyId == companyId && 
                       m.CurrentStatus == "Available" && 
                       m.IsActive && 
                       !m.IsDeleted)
            .OrderBy(m => m.MachineCode)
            .ToListAsync();
    }

    public async Task<IEnumerable<MachineCenter>> GetMachinesInMaintenanceAsync(int companyId)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Where(m => m.CompanyId == companyId && 
                       m.CurrentStatus == "Maintenance" && 
                       !m.IsDeleted)
            .OrderBy(m => m.NextMaintenanceDate)
            .ToListAsync();
    }

    public async Task<IEnumerable<MachineCapability>> GetMachineCapabilitiesAsync(int machineCenterId)
    {
        return await _context.MachineCapabilities
            .Where(c => c.MachineCenterId == machineCenterId && c.IsActive)
            .OrderBy(c => c.CapabilityName)
            .ToListAsync();
    }

    public async Task<MachineCapability> AddMachineCapabilityAsync(MachineCapability capability)
    {
        _context.MachineCapabilities.Add(capability);
        await _context.SaveChangesAsync();
        return capability;
    }

    public async Task<MachineCapability> UpdateMachineCapabilityAsync(MachineCapability capability)
    {
        var existing = await _context.MachineCapabilities.FindAsync(capability.Id);
        if (existing == null)
            throw new InvalidOperationException($"Machine capability with ID {capability.Id} not found");

        existing.CapabilityName = capability.CapabilityName;
        existing.Description = capability.Description;
        existing.MinValue = capability.MinValue;
        existing.MaxValue = capability.MaxValue;
        existing.Unit = capability.Unit;
        existing.CompatibleMaterials = capability.CompatibleMaterials;
        existing.IsActive = capability.IsActive;

        await _context.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> RemoveMachineCapabilityAsync(int capabilityId)
    {
        var capability = await _context.MachineCapabilities.FindAsync(capabilityId);
        if (capability == null)
            return false;

        _context.MachineCapabilities.Remove(capability);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<MachineOperator>> GetMachineOperatorsAsync(int machineCenterId)
    {
        return await _context.MachineOperators
            .Include(o => o.User)
            .Where(o => o.MachineCenterId == machineCenterId && o.IsActive)
            .OrderBy(o => o.IsPrimary ? 0 : 1)
            .ThenBy(o => o.User.Email)
            .ToListAsync();
    }

    public async Task<MachineOperator> AssignOperatorAsync(MachineOperator machineOperator)
    {
        // Check if operator already assigned
        var existing = await _context.MachineOperators
            .FirstOrDefaultAsync(o => o.MachineCenterId == machineOperator.MachineCenterId && 
                                     o.UserId == machineOperator.UserId);
        
        if (existing != null)
        {
            // Update existing assignment
            existing.CertificationLevel = machineOperator.CertificationLevel;
            existing.CertificationDate = machineOperator.CertificationDate;
            existing.CertificationExpiry = machineOperator.CertificationExpiry;
            existing.IsActive = machineOperator.IsActive;
            existing.IsPrimary = machineOperator.IsPrimary;
        }
        else
        {
            // Create new assignment
            _context.MachineOperators.Add(machineOperator);
        }

        // If setting as primary, remove primary flag from others
        if (machineOperator.IsPrimary)
        {
            var otherOperators = await _context.MachineOperators
                .Where(o => o.MachineCenterId == machineOperator.MachineCenterId && 
                           o.UserId != machineOperator.UserId)
                .ToListAsync();
            
            foreach (var op in otherOperators)
            {
                op.IsPrimary = false;
            }
        }

        await _context.SaveChangesAsync();
        return machineOperator;
    }

    public async Task<bool> RemoveOperatorAsync(int operatorId)
    {
        var machineOperator = await _context.MachineOperators.FindAsync(operatorId);
        if (machineOperator == null)
            return false;

        _context.MachineOperators.Remove(machineOperator);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<MachineCenter>> GetMachinesByOperatorAsync(int userId)
    {
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Where(m => m.Operators.Any(o => o.UserId == userId && o.IsActive) && 
                       !m.IsDeleted)
            .OrderBy(m => m.MachineCode)
            .ToListAsync();
    }

    public async Task<bool> RecordMaintenanceAsync(int machineCenterId, DateTime maintenanceDate)
    {
        var machine = await _context.MachineCenters.FindAsync(machineCenterId);
        if (machine == null)
            return false;

        machine.LastMaintenanceDate = maintenanceDate;
        machine.CurrentOperatingHours = 0; // Reset operating hours after maintenance
        
        // Calculate next maintenance date based on interval
        if (machine.MaintenanceIntervalHours > 0)
        {
            // Assuming 8 hours per day operation
            var daysToNextMaintenance = machine.MaintenanceIntervalHours / 8.0;
            machine.NextMaintenanceDate = maintenanceDate.AddDays(daysToNextMaintenance);
        }
        
        machine.CurrentStatus = "Available"; // Set to available after maintenance
        machine.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<MachineCenter>> GetMachinesDueForMaintenanceAsync(int companyId)
    {
        var currentDate = DateTime.UtcNow;
        
        return await _context.MachineCenters
            .Include(m => m.WorkCenter)
            .Where(m => m.CompanyId == companyId && 
                       !m.IsDeleted &&
                       (m.NextMaintenanceDate <= currentDate || 
                        (m.MaintenanceIntervalHours > 0 && 
                         m.CurrentOperatingHours >= m.MaintenanceIntervalHours)))
            .OrderBy(m => m.NextMaintenanceDate)
            .ToListAsync();
    }

    public async Task<bool> UpdateOperatingHoursAsync(int machineCenterId, int hours)
    {
        var machine = await _context.MachineCenters.FindAsync(machineCenterId);
        if (machine == null)
            return false;

        machine.CurrentOperatingHours += hours;
        
        // Check if maintenance is due
        if (machine.MaintenanceIntervalHours > 0 && 
            machine.CurrentOperatingHours >= machine.MaintenanceIntervalHours)
        {
            // Could trigger a notification here
            machine.CurrentStatus = "Maintenance";
        }
        
        machine.LastModified = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<decimal> CalculateOEEAsync(int machineCenterId, DateTime startDate, DateTime endDate)
    {
        var machine = await GetMachineCenterByIdAsync(machineCenterId);
        if (machine == null)
            return 0;

        // OEE = Availability × Performance × Quality
        // This is a simplified calculation - in production, you'd use actual production data
        var availability = machine.AvailabilityRate / 100m;
        var performance = machine.EfficiencyPercentage / 100m;
        var quality = machine.QualityRate / 100m;
        
        var oee = availability * performance * quality * 100;
        
        return Math.Round(oee, 2);
    }

    public async Task<decimal> CalculateMachineUtilizationAsync(int machineCenterId, DateTime startDate, DateTime endDate)
    {
        var machine = await GetMachineCenterByIdAsync(machineCenterId);
        if (machine == null)
            return 0;

        var totalHours = (decimal)(endDate - startDate).TotalHours;
        if (totalHours <= 0)
            return 0;

        // This would typically query actual production logs
        // For now, using a simplified calculation based on status and efficiency
        var utilizationRate = machine.CurrentStatus switch
        {
            "InUse" => machine.EfficiencyPercentage,
            "Available" => 0,
            "Maintenance" => 0,
            "Breakdown" => 0,
            _ => 0
        };
        
        return Math.Min(utilizationRate, 100);
    }
}