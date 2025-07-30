using Microsoft.JSInterop;
using System.Timers;

namespace SteelEstimation.Web.Services;

public class InactivityMonitor : IDisposable
{
    private readonly IJSRuntime _jsRuntime;
    private readonly ILogger<InactivityMonitor> _logger;
    private System.Timers.Timer? _inactivityTimer;
    private DateTime _lastActivity;
    private bool _isMonitoring;
    private DotNetObjectReference<InactivityMonitor>? _dotNetRef;
    
    // 10 minutes in milliseconds
    private const int InactivityTimeout = 10 * 60 * 1000;
    
    public event Action? OnInactivityDetected;
    
    public InactivityMonitor(IJSRuntime jsRuntime, ILogger<InactivityMonitor> logger)
    {
        _jsRuntime = jsRuntime;
        _logger = logger;
        _lastActivity = DateTime.UtcNow;
    }
    
    public async Task StartMonitoringAsync()
    {
        if (_isMonitoring) return;
        
        _isMonitoring = true;
        _lastActivity = DateTime.UtcNow;
        
        // Create a reference to this instance for JS callbacks
        _dotNetRef = DotNetObjectReference.Create(this);
        
        // Set up activity listeners in JavaScript
        await _jsRuntime.InvokeVoidAsync("inactivityMonitor.initialize", _dotNetRef);
        
        // Start the timer
        _inactivityTimer = new System.Timers.Timer(30000); // Check every 30 seconds
        _inactivityTimer.Elapsed += CheckInactivity;
        _inactivityTimer.Start();
        
        _logger.LogInformation("Inactivity monitoring started");
    }
    
    public async Task StopMonitoringAsync()
    {
        if (!_isMonitoring) return;
        
        _isMonitoring = false;
        _inactivityTimer?.Stop();
        _inactivityTimer?.Dispose();
        
        // Remove JS event listeners
        await _jsRuntime.InvokeVoidAsync("inactivityMonitor.destroy");
        
        _dotNetRef?.Dispose();
        _logger.LogInformation("Inactivity monitoring stopped");
    }
    
    [JSInvokable]
    public void UpdateActivity()
    {
        _lastActivity = DateTime.UtcNow;
        _logger.LogDebug("User activity detected");
    }
    
    private void CheckInactivity(object? sender, ElapsedEventArgs e)
    {
        var inactiveTime = DateTime.UtcNow - _lastActivity;
        
        if (inactiveTime.TotalMilliseconds >= InactivityTimeout)
        {
            _logger.LogWarning("User inactivity detected after {Minutes} minutes", inactiveTime.TotalMinutes);
            OnInactivityDetected?.Invoke();
            
            // Stop the timer until re-authentication
            _inactivityTimer?.Stop();
        }
    }
    
    public void ResetTimer()
    {
        _lastActivity = DateTime.UtcNow;
        _inactivityTimer?.Start();
        _logger.LogInformation("Inactivity timer reset");
    }
    
    public void Dispose()
    {
        _ = StopMonitoringAsync();
        _dotNetRef?.Dispose();
        _inactivityTimer?.Dispose();
    }
}