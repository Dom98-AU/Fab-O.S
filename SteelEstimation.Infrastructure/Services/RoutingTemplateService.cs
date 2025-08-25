using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class RoutingTemplateService : IRoutingTemplateService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<RoutingTemplateService> _logger;

    public RoutingTemplateService(ApplicationDbContext context, ILogger<RoutingTemplateService> logger)
    {
        _context = context;
        _logger = logger;
    }

    // Template CRUD operations
    public async Task<RoutingTemplate?> GetByIdAsync(int id)
    {
        return await _context.RoutingTemplates
            .Include(t => t.Operations)
                .ThenInclude(o => o.WorkCenter)
            .Include(t => t.Operations)
                .ThenInclude(o => o.MachineCenter)
            .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);
    }

    public async Task<RoutingTemplate?> GetByCodeAsync(string code, int companyId)
    {
        return await _context.RoutingTemplates
            .Include(t => t.Operations)
            .FirstOrDefaultAsync(t => t.Code == code && t.CompanyId == companyId && !t.IsDeleted);
    }

    public async Task<IEnumerable<RoutingTemplate>> GetAllAsync(int companyId, bool includeInactive = false)
    {
        var query = _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && !t.IsDeleted);

        if (!includeInactive)
            query = query.Where(t => t.IsActive);

        return await query.OrderBy(t => t.Code).ToListAsync();
    }

    public async Task<IEnumerable<RoutingTemplate>> GetActiveTemplatesAsync(int companyId)
    {
        return await _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && t.IsActive && !t.IsDeleted)
            .OrderBy(t => t.Name)
            .ToListAsync();
    }

    public async Task<IEnumerable<RoutingTemplate>> GetTemplatesByTypeAsync(int companyId, string templateType)
    {
        return await _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && t.TemplateType == templateType && !t.IsDeleted)
            .OrderBy(t => t.Name)
            .ToListAsync();
    }

    public async Task<IEnumerable<RoutingTemplate>> GetTemplatesByCategoryAsync(int companyId, string productCategory)
    {
        return await _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && t.ProductCategory == productCategory && !t.IsDeleted)
            .OrderBy(t => t.Name)
            .ToListAsync();
    }

    public async Task<RoutingTemplate> CreateAsync(RoutingTemplate template)
    {
        template.CreatedDate = DateTime.UtcNow;
        template.LastModified = DateTime.UtcNow;
        
        _context.RoutingTemplates.Add(template);
        await _context.SaveChangesAsync();
        
        _logger.LogInformation("Created routing template {Code} with ID {Id}", template.Code, template.Id);
        return template;
    }

    public async Task<RoutingTemplate> UpdateAsync(RoutingTemplate template)
    {
        template.LastModified = DateTime.UtcNow;
        
        _context.RoutingTemplates.Update(template);
        await _context.SaveChangesAsync();
        
        _logger.LogInformation("Updated routing template {Code} with ID {Id}", template.Code, template.Id);
        return template;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var template = await _context.RoutingTemplates.FindAsync(id);
        if (template == null)
            return false;

        template.IsDeleted = true;
        template.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        _logger.LogInformation("Soft deleted routing template with ID {Id}", id);
        return true;
    }

    public async Task<bool> ActivateAsync(int id)
    {
        var template = await _context.RoutingTemplates.FindAsync(id);
        if (template == null)
            return false;

        template.IsActive = true;
        template.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeactivateAsync(int id)
    {
        var template = await _context.RoutingTemplates.FindAsync(id);
        if (template == null)
            return false;

        template.IsActive = false;
        template.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }

    // Operation management
    public async Task<RoutingOperation?> GetOperationByIdAsync(int operationId)
    {
        return await _context.RoutingOperations
            .Include(o => o.WorkCenter)
            .Include(o => o.MachineCenter)
            .FirstOrDefaultAsync(o => o.Id == operationId);
    }

    public async Task<IEnumerable<RoutingOperation>> GetOperationsByTemplateAsync(int templateId)
    {
        return await _context.RoutingOperations
            .Include(o => o.WorkCenter)
            .Include(o => o.MachineCenter)
            .Where(o => o.RoutingTemplateId == templateId && o.IsActive)
            .OrderBy(o => o.SequenceNumber)
            .ToListAsync();
    }

    public async Task<RoutingOperation> AddOperationAsync(int templateId, RoutingOperation operation)
    {
        operation.RoutingTemplateId = templateId;
        operation.CreatedDate = DateTime.UtcNow;
        operation.LastModified = DateTime.UtcNow;
        
        _context.RoutingOperations.Add(operation);
        
        // Update template total hours
        await UpdateTemplateEstimatedHours(templateId);
        
        await _context.SaveChangesAsync();
        return operation;
    }

    public async Task<RoutingOperation> UpdateOperationAsync(RoutingOperation operation)
    {
        operation.LastModified = DateTime.UtcNow;
        
        _context.RoutingOperations.Update(operation);
        
        // Update template total hours
        await UpdateTemplateEstimatedHours(operation.RoutingTemplateId);
        
        await _context.SaveChangesAsync();
        return operation;
    }

    public async Task<bool> DeleteOperationAsync(int operationId)
    {
        var operation = await _context.RoutingOperations.FindAsync(operationId);
        if (operation == null)
            return false;

        _context.RoutingOperations.Remove(operation);
        
        // Update template total hours
        await UpdateTemplateEstimatedHours(operation.RoutingTemplateId);
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ReorderOperationsAsync(int templateId, List<int> operationIds)
    {
        var operations = await _context.RoutingOperations
            .Where(o => o.RoutingTemplateId == templateId)
            .ToListAsync();

        for (int i = 0; i < operationIds.Count; i++)
        {
            var operation = operations.FirstOrDefault(o => o.Id == operationIds[i]);
            if (operation != null)
            {
                operation.SequenceNumber = i + 1;
                operation.LastModified = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    // Template application
    public async Task<bool> ApplyTemplateToPackageAsync(int packageId, int templateId)
    {
        var package = await _context.Packages.FindAsync(packageId);
        var template = await GetByIdAsync(templateId);
        
        if (package == null || template == null)
            return false;

        package.RoutingId = templateId;
        package.LastModified = DateTime.UtcNow;
        
        // Optionally create processing items based on template operations
        await ApplyTemplateToProcessingItemsAsync(packageId, templateId);
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ApplyTemplateToProcessingItemsAsync(int packageId, int templateId)
    {
        var template = await GetByIdAsync(templateId);
        if (template == null)
            return false;

        var processingItems = await _context.ProcessingItems
            .Where(p => p.PackageWorksheet != null && p.PackageWorksheet.PackageId == packageId)
            .ToListAsync();

        foreach (var item in processingItems)
        {
            // Find the most appropriate operation for this item
            var operation = template.Operations
                .OrderBy(o => o.SequenceNumber)
                .FirstOrDefault(); // This is simplified - you might want more complex matching logic
            
            if (operation != null)
            {
                item.RoutingOperationId = operation.Id;
                item.LastModified = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<ProcessingItem>> GenerateProcessingItemsFromTemplateAsync(int templateId, int quantity)
    {
        var template = await GetByIdAsync(templateId);
        if (template == null)
            return new List<ProcessingItem>();

        var items = new List<ProcessingItem>();
        
        foreach (var operation in template.Operations.OrderBy(o => o.SequenceNumber))
        {
            var item = new ProcessingItem
            {
                Description = operation.OperationName,
                Quantity = quantity,
                RoutingOperationId = operation.Id,
                MarkMeasureCut = (int)(operation.ProcessingTimePerUnit * 60), // Convert hours to minutes
                CreatedDate = DateTime.UtcNow,
                LastModified = DateTime.UtcNow
            };
            
            items.Add(item);
        }
        
        return items;
    }

    // Calculation methods
    public async Task<decimal> CalculateTotalHoursAsync(int templateId, int quantity, decimal? weight = null)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        decimal totalHours = 0;

        foreach (var operation in operations)
        {
            decimal operationHours = 0;
            
            // Add setup time (amortized over quantity)
            if (quantity > 0)
                operationHours += operation.SetupTimeMinutes / 60m;
            
            // Add processing time based on calculation method
            if (operation.CalculationMethod == "PerUnit")
            {
                operationHours += (operation.ProcessingTimePerUnit * quantity) / 60m;
            }
            else if (operation.CalculationMethod == "PerWeight" && weight.HasValue)
            {
                operationHours += (operation.ProcessingTimePerKg * weight.Value) / 60m;
            }
            else if (operation.CalculationMethod == "Fixed")
            {
                operationHours += (operation.SetupTimeMinutes + operation.MovementTimeMinutes + operation.WaitingTimeMinutes) / 60m;
            }
            
            // Apply efficiency factor
            if (operation.EfficiencyFactor != 0)
                operationHours = operationHours * (100m / operation.EfficiencyFactor);
            
            totalHours += operationHours;
        }

        return totalHours;
    }

    public async Task<decimal> CalculateTotalCostAsync(int templateId, int quantity, decimal? weight = null)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        decimal totalCost = 0;

        foreach (var operation in operations)
        {
            var hours = await CalculateTotalHoursAsync(templateId, quantity, weight);
            var hourlyRate = operation.HourlyRate;
            
            totalCost += hours * hourlyRate;
            totalCost += operation.MaterialCostPerUnit * quantity;
            totalCost += operation.ToolingCost;
        }

        return totalCost;
    }

    public async Task<Dictionary<int, decimal>> CalculateWorkCenterLoadAsync(int templateId, int quantity)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        var workCenterLoad = new Dictionary<int, decimal>();

        foreach (var operation in operations)
        {
            var hours = operation.ProcessingTimePerUnit * quantity / 60m;
            
            if (workCenterLoad.ContainsKey(operation.WorkCenterId))
                workCenterLoad[operation.WorkCenterId] += hours;
            else
                workCenterLoad[operation.WorkCenterId] = hours;
        }

        return workCenterLoad;
    }

    public async Task<TimeSpan> CalculateLeadTimeAsync(int templateId, int quantity)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        decimal totalMinutes = 0;

        foreach (var operation in operations)
        {
            totalMinutes += operation.SetupTimeMinutes;
            totalMinutes += operation.ProcessingTimePerUnit * quantity;
            totalMinutes += operation.MovementTimeMinutes;
            totalMinutes += operation.WaitingTimeMinutes;
            
            // Account for parallel operations
            if (!operation.CanRunInParallel && operation.PreviousOperationId.HasValue)
            {
                // Sequential operation - add to total time
            }
            else if (operation.CanRunInParallel)
            {
                // Parallel operation - doesn't add to lead time
                continue;
            }
        }

        return TimeSpan.FromMinutes((double)totalMinutes);
    }

    // Validation
    public async Task<bool> ValidateTemplateAsync(int templateId)
    {
        var errors = await GetValidationErrorsAsync(templateId);
        return !errors.Any();
    }

    public async Task<List<string>> GetValidationErrorsAsync(int templateId)
    {
        var errors = new List<string>();
        var template = await GetByIdAsync(templateId);
        
        if (template == null)
        {
            errors.Add("Template not found");
            return errors;
        }

        if (string.IsNullOrWhiteSpace(template.Code))
            errors.Add("Template code is required");
        
        if (string.IsNullOrWhiteSpace(template.Name))
            errors.Add("Template name is required");
        
        if (!template.Operations.Any())
            errors.Add("Template must have at least one operation");
        
        // Check for work center availability
        foreach (var operation in template.Operations)
        {
            var workCenter = await _context.WorkCenters.FindAsync(operation.WorkCenterId);
            if (workCenter == null || !workCenter.IsActive)
                errors.Add($"Work center for operation {operation.OperationCode} is not available");
        }
        
        // Check for circular dependencies in operations
        var visitedOps = new HashSet<int>();
        foreach (var operation in template.Operations)
        {
            if (HasCircularDependency(operation, template.Operations.ToList(), visitedOps))
                errors.Add($"Circular dependency detected in operation {operation.OperationCode}");
        }
        
        return errors;
    }

    public async Task<bool> CanDeleteTemplateAsync(int templateId)
    {
        // Check if template is in use by any packages
        var inUse = await _context.Packages
            .AnyAsync(p => p.RoutingId == templateId && !p.IsDeleted);
        
        return !inUse;
    }

    // Template copying and versioning
    public async Task<RoutingTemplate> CopyTemplateAsync(int sourceTemplateId, string newCode, string newName)
    {
        var sourceTemplate = await GetByIdAsync(sourceTemplateId);
        if (sourceTemplate == null)
            throw new ArgumentException("Source template not found");

        var newTemplate = new RoutingTemplate
        {
            Code = newCode,
            Name = newName,
            Description = sourceTemplate.Description,
            CompanyId = sourceTemplate.CompanyId,
            TemplateType = sourceTemplate.TemplateType,
            ProductCategory = sourceTemplate.ProductCategory,
            MaterialType = sourceTemplate.MaterialType,
            ComplexityLevel = sourceTemplate.ComplexityLevel,
            DefaultEfficiencyPercentage = sourceTemplate.DefaultEfficiencyPercentage,
            IncludesWelding = sourceTemplate.IncludesWelding,
            IncludesQualityControl = sourceTemplate.IncludesQualityControl,
            Version = "1.0",
            IsActive = false, // Start as inactive
            ApprovalStatus = "Draft",
            Notes = sourceTemplate.Notes,
            CreatedDate = DateTime.UtcNow,
            LastModified = DateTime.UtcNow
        };

        _context.RoutingTemplates.Add(newTemplate);
        await _context.SaveChangesAsync();

        // Copy operations
        foreach (var sourceOp in sourceTemplate.Operations)
        {
            var newOp = new RoutingOperation
            {
                RoutingTemplateId = newTemplate.Id,
                WorkCenterId = sourceOp.WorkCenterId,
                MachineCenterId = sourceOp.MachineCenterId,
                OperationCode = sourceOp.OperationCode,
                OperationName = sourceOp.OperationName,
                Description = sourceOp.Description,
                SequenceNumber = sourceOp.SequenceNumber,
                OperationType = sourceOp.OperationType,
                SetupTimeMinutes = sourceOp.SetupTimeMinutes,
                ProcessingTimePerUnit = sourceOp.ProcessingTimePerUnit,
                ProcessingTimePerKg = sourceOp.ProcessingTimePerKg,
                MovementTimeMinutes = sourceOp.MovementTimeMinutes,
                WaitingTimeMinutes = sourceOp.WaitingTimeMinutes,
                CalculationMethod = sourceOp.CalculationMethod,
                RequiredOperators = sourceOp.RequiredOperators,
                RequiredSkillLevel = sourceOp.RequiredSkillLevel,
                RequiresInspection = sourceOp.RequiresInspection,
                InspectionPercentage = sourceOp.InspectionPercentage,
                CanRunInParallel = sourceOp.CanRunInParallel,
                OverrideHourlyRate = sourceOp.OverrideHourlyRate,
                MaterialCostPerUnit = sourceOp.MaterialCostPerUnit,
                ToolingCost = sourceOp.ToolingCost,
                EfficiencyFactor = sourceOp.EfficiencyFactor,
                ScrapPercentage = sourceOp.ScrapPercentage,
                WorkInstructions = sourceOp.WorkInstructions,
                SafetyNotes = sourceOp.SafetyNotes,
                QualityNotes = sourceOp.QualityNotes,
                IsActive = sourceOp.IsActive,
                IsOptional = sourceOp.IsOptional,
                IsCriticalPath = sourceOp.IsCriticalPath,
                CreatedDate = DateTime.UtcNow,
                LastModified = DateTime.UtcNow
            };
            
            _context.RoutingOperations.Add(newOp);
        }

        await _context.SaveChangesAsync();
        return newTemplate;
    }

    public async Task<RoutingTemplate> CreateNewVersionAsync(int templateId, string newVersion)
    {
        var sourceTemplate = await GetByIdAsync(templateId);
        if (sourceTemplate == null)
            throw new ArgumentException("Source template not found");

        var newCode = $"{sourceTemplate.Code}_v{newVersion}";
        var newName = $"{sourceTemplate.Name} (Version {newVersion})";
        
        return await CopyTemplateAsync(templateId, newCode, newName);
    }

    public async Task<IEnumerable<RoutingTemplate>> GetTemplateVersionsAsync(string baseCode, int companyId)
    {
        return await _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && 
                       (t.Code == baseCode || t.Code.StartsWith($"{baseCode}_v")) && 
                       !t.IsDeleted)
            .OrderBy(t => t.Version)
            .ToListAsync();
    }

    // Approval workflow
    public async Task<bool> SubmitForApprovalAsync(int templateId, int userId)
    {
        var template = await _context.RoutingTemplates.FindAsync(templateId);
        if (template == null)
            return false;

        template.ApprovalStatus = "Pending";
        template.LastModified = DateTime.UtcNow;
        template.LastModifiedByUserId = userId;
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ApproveTemplateAsync(int templateId, int approverId)
    {
        var template = await _context.RoutingTemplates.FindAsync(templateId);
        if (template == null)
            return false;

        template.ApprovalStatus = "Approved";
        template.ApprovedByUserId = approverId;
        template.ApprovalDate = DateTime.UtcNow;
        template.IsActive = true;
        template.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> RejectTemplateAsync(int templateId, int approverId, string reason)
    {
        var template = await _context.RoutingTemplates.FindAsync(templateId);
        if (template == null)
            return false;

        template.ApprovalStatus = "Rejected";
        template.Notes = $"{template.Notes}\n\nRejection reason: {reason}";
        template.LastModified = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return true;
    }

    // Analytics and reporting
    public async Task<int> GetUsageCountAsync(int templateId)
    {
        return await _context.Packages
            .CountAsync(p => p.RoutingId == templateId && !p.IsDeleted);
    }

    public async Task<DateTime?> GetLastUsedDateAsync(int templateId)
    {
        var lastPackage = await _context.Packages
            .Where(p => p.RoutingId == templateId && !p.IsDeleted)
            .OrderByDescending(p => p.CreatedDate)
            .FirstOrDefaultAsync();
        
        return lastPackage?.CreatedDate;
    }

    public async Task<IEnumerable<RoutingTemplate>> GetMostUsedTemplatesAsync(int companyId, int topCount = 10)
    {
        var templateUsage = await _context.Packages
            .Where(p => p.Routing != null && 
                       p.Routing.CompanyId == companyId && 
                       !p.IsDeleted)
            .GroupBy(p => p.RoutingId)
            .Select(g => new { TemplateId = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(topCount)
            .ToListAsync();

        var templateIds = templateUsage.Select(x => x.TemplateId).ToList();
        
        return await _context.RoutingTemplates
            .Where(t => templateIds.Contains(t.Id))
            .ToListAsync();
    }

    public async Task<Dictionary<string, int>> GetTemplateUsageByTypeAsync(int companyId)
    {
        return await _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && !t.IsDeleted)
            .GroupBy(t => t.TemplateType)
            .Select(g => new { Type = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Type, x => x.Count);
    }

    // Work center integration
    public async Task<IEnumerable<WorkCenter>> GetRequiredWorkCentersAsync(int templateId)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        var workCenterIds = operations.Select(o => o.WorkCenterId).Distinct();
        
        return await _context.WorkCenters
            .Where(w => workCenterIds.Contains(w.Id))
            .ToListAsync();
    }

    public async Task<bool> CheckWorkCenterAvailabilityAsync(int templateId, DateTime startDate)
    {
        var workCenters = await GetRequiredWorkCentersAsync(templateId);
        
        foreach (var workCenter in workCenters)
        {
            if (!workCenter.IsActive)
                return false;
            
            // Check if work center is in maintenance period
            if (workCenter.NextMaintenanceDate.HasValue && 
                workCenter.NextMaintenanceDate.Value <= startDate.AddDays(7))
                return false;
        }
        
        return true;
    }

    public async Task<Dictionary<int, decimal>> GetWorkCenterUtilizationAsync(int templateId)
    {
        var operations = await GetOperationsByTemplateAsync(templateId);
        var utilization = new Dictionary<int, decimal>();

        foreach (var operation in operations)
        {
            var workCenter = await _context.WorkCenters.FindAsync(operation.WorkCenterId);
            if (workCenter != null)
            {
                var hoursRequired = (operation.SetupTimeMinutes + operation.ProcessingTimePerUnit) / 60m;
                var utilizationPercent = (hoursRequired / workCenter.DailyCapacityHours) * 100;
                
                if (utilization.ContainsKey(operation.WorkCenterId))
                    utilization[operation.WorkCenterId] += utilizationPercent;
                else
                    utilization[operation.WorkCenterId] = utilizationPercent;
            }
        }

        return utilization;
    }

    // Bulk operations
    public async Task<bool> BulkActivateAsync(List<int> templateIds)
    {
        var templates = await _context.RoutingTemplates
            .Where(t => templateIds.Contains(t.Id))
            .ToListAsync();

        foreach (var template in templates)
        {
            template.IsActive = true;
            template.LastModified = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> BulkDeactivateAsync(List<int> templateIds)
    {
        var templates = await _context.RoutingTemplates
            .Where(t => templateIds.Contains(t.Id))
            .ToListAsync();

        foreach (var template in templates)
        {
            template.IsActive = false;
            template.LastModified = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<int> BulkDeleteAsync(List<int> templateIds)
    {
        var templates = await _context.RoutingTemplates
            .Where(t => templateIds.Contains(t.Id))
            .ToListAsync();

        foreach (var template in templates)
        {
            template.IsDeleted = true;
            template.LastModified = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return templates.Count;
    }

    // Search and filtering
    public async Task<IEnumerable<RoutingTemplate>> SearchTemplatesAsync(int companyId, string searchTerm)
    {
        var query = _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && !t.IsDeleted);

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            searchTerm = searchTerm.ToLower();
            query = query.Where(t => 
                t.Code.ToLower().Contains(searchTerm) ||
                t.Name.ToLower().Contains(searchTerm) ||
                (t.Description != null && t.Description.ToLower().Contains(searchTerm)) ||
                (t.ProductCategory != null && t.ProductCategory.ToLower().Contains(searchTerm)) ||
                (t.MaterialType != null && t.MaterialType.ToLower().Contains(searchTerm)));
        }

        return await query.OrderBy(t => t.Name).ToListAsync();
    }

    public async Task<IEnumerable<RoutingTemplate>> GetTemplatesWithFiltersAsync(
        int companyId,
        string? templateType = null,
        string? productCategory = null,
        string? complexityLevel = null,
        bool? includesWelding = null,
        bool? isActive = null)
    {
        var query = _context.RoutingTemplates
            .Where(t => t.CompanyId == companyId && !t.IsDeleted);

        if (!string.IsNullOrWhiteSpace(templateType))
            query = query.Where(t => t.TemplateType == templateType);
        
        if (!string.IsNullOrWhiteSpace(productCategory))
            query = query.Where(t => t.ProductCategory == productCategory);
        
        if (!string.IsNullOrWhiteSpace(complexityLevel))
            query = query.Where(t => t.ComplexityLevel == complexityLevel);
        
        if (includesWelding.HasValue)
            query = query.Where(t => t.IncludesWelding == includesWelding.Value);
        
        if (isActive.HasValue)
            query = query.Where(t => t.IsActive == isActive.Value);

        return await query.OrderBy(t => t.Name).ToListAsync();
    }

    // Helper methods
    private async Task UpdateTemplateEstimatedHours(int templateId)
    {
        var template = await _context.RoutingTemplates
            .Include(t => t.Operations)
            .FirstOrDefaultAsync(t => t.Id == templateId);
        
        if (template != null)
        {
            decimal totalHours = 0;
            foreach (var op in template.Operations.Where(o => o.IsActive))
            {
                totalHours += (op.SetupTimeMinutes + op.ProcessingTimePerUnit + 
                              op.MovementTimeMinutes + op.WaitingTimeMinutes) / 60m;
            }
            
            template.EstimatedTotalHours = totalHours;
            template.LastModified = DateTime.UtcNow;
        }
    }

    private bool HasCircularDependency(RoutingOperation operation, List<RoutingOperation> allOperations, HashSet<int> visited)
    {
        if (visited.Contains(operation.Id))
            return true;
        
        visited.Add(operation.Id);
        
        if (operation.PreviousOperationId.HasValue)
        {
            var previousOp = allOperations.FirstOrDefault(o => o.Id == operation.PreviousOperationId.Value);
            if (previousOp != null)
            {
                return HasCircularDependency(previousOp, allOperations, visited);
            }
        }
        
        return false;
    }
}