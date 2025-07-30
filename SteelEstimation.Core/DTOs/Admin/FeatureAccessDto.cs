using System;
using System.Collections.Generic;

namespace SteelEstimation.Core.DTOs.Admin
{
    public class FeatureAccessDto
    {
        public int CompanyId { get; set; }
        public string CompanyCode { get; set; } = string.Empty;
        public List<FeatureDto> EnabledFeatures { get; set; } = new();
        public DateTime SyncedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
    }

    public class FeatureDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string GroupCode { get; set; } = string.Empty;
        public bool IsEnabled { get; set; }
        public DateTime? EnabledUntil { get; set; }
        public Dictionary<string, object> Metadata { get; set; } = new();
    }

    public class FeatureGroupDto
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DisplayOrder { get; set; }
        public List<FeatureDto> Features { get; set; } = new();
    }
}