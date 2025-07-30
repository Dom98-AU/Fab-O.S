using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.DTOs
{
    public class AuthResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? AccessToken { get; set; }
        public string? RefreshToken { get; set; }
        public User? User { get; set; }
    }
}