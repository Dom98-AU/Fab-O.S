using System;
using System.Collections.Generic;

namespace SteelEstimation.Core.DTOs.Admin
{
    public class TenantFeatureUpdateDto
    {
        public int CompanyId { get; set; }
        public string CompanyCode { get; set; } = string.Empty;
        public List<FeatureUpdateDto> Features { get; set; } = new();
        public string UpdateReason { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; }
    }

    public class FeatureUpdateDto
    {
        public string FeatureCode { get; set; } = string.Empty;
        public bool IsEnabled { get; set; }
        public DateTime? EnabledUntil { get; set; }
        public string? Notes { get; set; }
    }

    public class BulkFeatureUpdateDto
    {
        public List<int> CompanyIds { get; set; } = new();
        public List<FeatureUpdateDto> Features { get; set; } = new();
        public string UpdateReason { get; set; } = string.Empty;
    }
}