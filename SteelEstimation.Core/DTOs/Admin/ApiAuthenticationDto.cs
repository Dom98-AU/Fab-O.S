using System;

namespace SteelEstimation.Core.DTOs.Admin
{
    public class ApiAuthenticationDto
    {
        public string ApiKey { get; set; } = string.Empty;
        public string ApiSecret { get; set; } = string.Empty;
        public DateTime IssuedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
    }

    public class ApiKeyValidationRequest
    {
        public string ApiKey { get; set; } = string.Empty;
        public string Signature { get; set; } = string.Empty;
        public long Timestamp { get; set; }
        public string Nonce { get; set; } = string.Empty;
    }

    public class ApiKeyValidationResponse
    {
        public bool IsValid { get; set; }
        public string? CompanyCode { get; set; }
        public int? CompanyId { get; set; }
        public string? ErrorMessage { get; set; }
        public DateTime? ValidUntil { get; set; }
    }
}