namespace SteelEstimation.Core.Services;

public interface ISettingsService
{
    Task<T?> GetSetting<T>(string key, T? defaultValue = default);
    Task<bool> GetBooleanSetting(string key, bool defaultValue = false);
    Task<string?> GetStringSetting(string key, string? defaultValue = null);
    Task<int> GetIntegerSetting(string key, int defaultValue = 0);
    Task<decimal> GetDecimalSetting(string key, decimal defaultValue = 0);
    Task SaveSetting<T>(string key, T value);
    Task<Dictionary<string, object>> GetAllSettings();
}