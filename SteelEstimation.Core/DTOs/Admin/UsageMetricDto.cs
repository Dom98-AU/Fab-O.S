using System;
using System.Collections.Generic;

namespace SteelEstimation.Core.DTOs.Admin
{
    public class UsageMetricDto
    {
        public int CompanyId { get; set; }
        public string CompanyCode { get; set; } = string.Empty;
        public DateTime MetricDate { get; set; }
        public string MetricType { get; set; } = string.Empty; // Users, Projects, Storage, etc.
        public decimal Value { get; set; }
        public Dictionary<string, object> Details { get; set; } = new();
    }

    public class CompanyUsageSummaryDto
    {
        public int CompanyId { get; set; }
        public string CompanyCode { get; set; } = string.Empty;
        public DateTime PeriodStart { get; set; }
        public DateTime PeriodEnd { get; set; }
        
        // User metrics
        public int ActiveUsers { get; set; }
        public int TotalUsers { get; set; }
        
        // Project metrics
        public int ActiveProjects { get; set; }
        public int TotalProjects { get; set; }
        public int ProjectsCreatedInPeriod { get; set; }
        
        // Feature usage
        public Dictionary<string, int> FeatureUsageCount { get; set; } = new();
        
        // Storage
        public decimal StorageUsedGB { get; set; }
        
        // API usage
        public int ApiCallsCount { get; set; }
    }

    public class FeatureUsageMetricDto
    {
        public string FeatureCode { get; set; } = string.Empty;
        public int CompanyId { get; set; }
        public int UserId { get; set; }
        public DateTime UsedAt { get; set; }
        public string? Context { get; set; } // Additional context about usage
    }
}