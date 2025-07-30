using System.Security.Claims;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface ITokenService
{
    Task<string> GenerateTokenAsync(User user);
    Task<ClaimsPrincipal?> ValidateTokenAsync(string token);
    Task<bool> RevokeTokenAsync(string token);
}