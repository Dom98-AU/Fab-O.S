using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IRoutingTemplateService
{
    // Template CRUD operations
    Task<RoutingTemplate?> GetByIdAsync(int id);
    Task<RoutingTemplate?> GetByCodeAsync(string code, int companyId);
    Task<IEnumerable<RoutingTemplate>> GetAllAsync(int companyId, bool includeInactive = false);
    Task<IEnumerable<RoutingTemplate>> GetActiveTemplatesAsync(int companyId);
    Task<IEnumerable<RoutingTemplate>> GetTemplatesByTypeAsync(int companyId, string templateType);
    Task<IEnumerable<RoutingTemplate>> GetTemplatesByCategoryAsync(int companyId, string productCategory);
    Task<RoutingTemplate> CreateAsync(RoutingTemplate template);
    Task<RoutingTemplate> UpdateAsync(RoutingTemplate template);
    Task<bool> DeleteAsync(int id);
    Task<bool> ActivateAsync(int id);
    Task<bool> DeactivateAsync(int id);
    
    // Operation management
    Task<RoutingOperation?> GetOperationByIdAsync(int operationId);
    Task<IEnumerable<RoutingOperation>> GetOperationsByTemplateAsync(int templateId);
    Task<RoutingOperation> AddOperationAsync(int templateId, RoutingOperation operation);
    Task<RoutingOperation> UpdateOperationAsync(RoutingOperation operation);
    Task<bool> DeleteOperationAsync(int operationId);
    Task<bool> ReorderOperationsAsync(int templateId, List<int> operationIds);
    
    // Template application
    Task<bool> ApplyTemplateToPackageAsync(int packageId, int templateId);
    Task<bool> ApplyTemplateToProcessingItemsAsync(int packageId, int templateId);
    Task<List<ProcessingItem>> GenerateProcessingItemsFromTemplateAsync(int templateId, int quantity);
    
    // Calculation methods
    Task<decimal> CalculateTotalHoursAsync(int templateId, int quantity, decimal? weight = null);
    Task<decimal> CalculateTotalCostAsync(int templateId, int quantity, decimal? weight = null);
    Task<Dictionary<int, decimal>> CalculateWorkCenterLoadAsync(int templateId, int quantity);
    Task<TimeSpan> CalculateLeadTimeAsync(int templateId, int quantity);
    
    // Validation
    Task<bool> ValidateTemplateAsync(int templateId);
    Task<List<string>> GetValidationErrorsAsync(int templateId);
    Task<bool> CanDeleteTemplateAsync(int templateId);
    
    // Template copying and versioning
    Task<RoutingTemplate> CopyTemplateAsync(int sourceTemplateId, string newCode, string newName);
    Task<RoutingTemplate> CreateNewVersionAsync(int templateId, string newVersion);
    Task<IEnumerable<RoutingTemplate>> GetTemplateVersionsAsync(string baseCode, int companyId);
    
    // Approval workflow
    Task<bool> SubmitForApprovalAsync(int templateId, int userId);
    Task<bool> ApproveTemplateAsync(int templateId, int approverId);
    Task<bool> RejectTemplateAsync(int templateId, int approverId, string reason);
    
    // Analytics and reporting
    Task<int> GetUsageCountAsync(int templateId);
    Task<DateTime?> GetLastUsedDateAsync(int templateId);
    Task<IEnumerable<RoutingTemplate>> GetMostUsedTemplatesAsync(int companyId, int topCount = 10);
    Task<Dictionary<string, int>> GetTemplateUsageByTypeAsync(int companyId);
    
    // Work center integration
    Task<IEnumerable<WorkCenter>> GetRequiredWorkCentersAsync(int templateId);
    Task<bool> CheckWorkCenterAvailabilityAsync(int templateId, DateTime startDate);
    Task<Dictionary<int, decimal>> GetWorkCenterUtilizationAsync(int templateId);
    
    // Bulk operations
    Task<bool> BulkActivateAsync(List<int> templateIds);
    Task<bool> BulkDeactivateAsync(List<int> templateIds);
    Task<int> BulkDeleteAsync(List<int> templateIds);
    
    // Search and filtering
    Task<IEnumerable<RoutingTemplate>> SearchTemplatesAsync(int companyId, string searchTerm);
    Task<IEnumerable<RoutingTemplate>> GetTemplatesWithFiltersAsync(
        int companyId,
        string? templateType = null,
        string? productCategory = null,
        string? complexityLevel = null,
        bool? includesWelding = null,
        bool? isActive = null
    );
}