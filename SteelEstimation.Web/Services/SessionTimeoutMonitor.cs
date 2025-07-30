using Microsoft.AspNetCore.Components.Authorization;
using System.Timers;

namespace SteelEstimation.Web.Services;

public class SessionTimeoutMonitor : IDisposable
{
    private readonly AuthenticationStateProvider _authStateProvider;
    private readonly ILogger<SessionTimeoutMonitor> _logger;
    private System.Timers.Timer? _checkTimer;
    private bool _isMonitoring;
    
    public event Action? OnSessionExpired;
    
    public SessionTimeoutMonitor(
        AuthenticationStateProvider authStateProvider,
        ILogger<SessionTimeoutMonitor> logger)
    {
        _authStateProvider = authStateProvider;
        _logger = logger;
    }
    
    public void StartMonitoring()
    {
        if (_isMonitoring) return;
        
        _isMonitoring = true;
        
        // Check authentication state every minute
        _checkTimer = new System.Timers.Timer(60000); // 1 minute
        _checkTimer.Elapsed += CheckAuthenticationState;
        _checkTimer.Start();
        
        _logger.LogInformation("Session timeout monitoring started");
    }
    
    public void StopMonitoring()
    {
        if (!_isMonitoring) return;
        
        _isMonitoring = false;
        _checkTimer?.Stop();
        _checkTimer?.Dispose();
        
        _logger.LogInformation("Session timeout monitoring stopped");
    }
    
    private async void CheckAuthenticationState(object? sender, ElapsedEventArgs e)
    {
        try
        {
            var authState = await _authStateProvider.GetAuthenticationStateAsync();
            
            if (!authState.User.Identity?.IsAuthenticated ?? true)
            {
                _logger.LogWarning("Session expired - user is no longer authenticated");
                OnSessionExpired?.Invoke();
                StopMonitoring(); // Stop checking once expired
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking authentication state");
        }
    }
    
    public void Dispose()
    {
        StopMonitoring();
        _checkTimer?.Dispose();
    }
}