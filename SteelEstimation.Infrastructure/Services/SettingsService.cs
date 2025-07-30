using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class SettingsService : ISettingsService
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbContextFactory;
    private readonly IAuthenticationService _authService;

    public SettingsService(
        IDbContextFactory<ApplicationDbContext> dbContextFactory,
        IAuthenticationService authService)
    {
        _dbContextFactory = dbContextFactory;
        _authService = authService;
    }

    public async Task<T?> GetSetting<T>(string key, T? defaultValue = default)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();
        
        var setting = await context.Settings
            .FirstOrDefaultAsync(s => s.Key == key);
        
        if (setting == null) return defaultValue;
        
        try
        {
            return setting.ValueType switch
            {
                "bool" => (T)(object)bool.Parse(setting.Value),
                "int" => (T)(object)int.Parse(setting.Value),
                "decimal" => (T)(object)decimal.Parse(setting.Value),
                "json" => JsonSerializer.Deserialize<T>(setting.Value),
                _ => (T)(object)setting.Value
            };
        }
        catch
        {
            return defaultValue;
        }
    }

    public async Task<bool> GetBooleanSetting(string key, bool defaultValue = false)
    {
        return await GetSetting<bool>(key, defaultValue);
    }

    public async Task<string?> GetStringSetting(string key, string? defaultValue = null)
    {
        return await GetSetting<string>(key, defaultValue);
    }

    public async Task<int> GetIntegerSetting(string key, int defaultValue = 0)
    {
        return await GetSetting<int>(key, defaultValue);
    }

    public async Task<decimal> GetDecimalSetting(string key, decimal defaultValue = 0)
    {
        return await GetSetting<decimal>(key, defaultValue);
    }

    public async Task SaveSetting<T>(string key, T value)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();
        
        var setting = await context.Settings.FirstOrDefaultAsync(s => s.Key == key);
        var currentUser = await _authService.GetCurrentUserAsync();
        
        if (setting == null)
        {
            setting = new Setting
            {
                Key = key,
                CreatedDate = DateTime.UtcNow
            };
            context.Settings.Add(setting);
        }
        
        // Determine value type
        setting.ValueType = value switch
        {
            bool => "bool",
            int => "int",
            decimal => "decimal",
            string => "string",
            _ => "json"
        };
        
        // Set value
        setting.Value = setting.ValueType == "json" 
            ? JsonSerializer.Serialize(value) 
            : value?.ToString() ?? "";
        
        setting.LastModified = DateTime.UtcNow;
        setting.LastModifiedBy = currentUser?.Id;
        
        await context.SaveChangesAsync();
    }

    public async Task<Dictionary<string, object>> GetAllSettings()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();
        
        var settings = await context.Settings.ToListAsync();
        var result = new Dictionary<string, object>();
        
        foreach (var setting in settings)
        {
            try
            {
                result[setting.Key] = setting.ValueType switch
                {
                    "bool" => bool.Parse(setting.Value),
                    "int" => int.Parse(setting.Value),
                    "decimal" => decimal.Parse(setting.Value),
                    "json" => JsonDocument.Parse(setting.Value),
                    _ => setting.Value
                };
            }
            catch
            {
                result[setting.Key] = setting.Value;
            }
        }
        
        return result;
    }
}