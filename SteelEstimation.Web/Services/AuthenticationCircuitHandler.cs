using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Server.Circuits;

namespace SteelEstimation.Web.Services;

public class AuthenticationCircuitHandler : CircuitHandler
{
    private readonly AuthenticationStateProvider _authenticationStateProvider;
    private readonly ILogger<AuthenticationCircuitHandler> _logger;

    public AuthenticationCircuitHandler(
        AuthenticationStateProvider authenticationStateProvider,
        ILogger<AuthenticationCircuitHandler> logger)
    {
        _authenticationStateProvider = authenticationStateProvider;
        _logger = logger;
    }

    public override async Task OnConnectionUpAsync(Circuit circuit, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Circuit {CircuitId} connected", circuit.Id);
        
        // Force authentication state refresh on circuit connection
        var authState = await _authenticationStateProvider.GetAuthenticationStateAsync();
        _logger.LogInformation("Circuit {CircuitId} authentication state: {IsAuthenticated}", 
            circuit.Id, authState.User.Identity?.IsAuthenticated ?? false);
    }

    public override Task OnConnectionDownAsync(Circuit circuit, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Circuit {CircuitId} disconnected", circuit.Id);
        return Task.CompletedTask;
    }

    public override Task OnCircuitOpenedAsync(Circuit circuit, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Circuit {CircuitId} opened", circuit.Id);
        return Task.CompletedTask;
    }

    public override Task OnCircuitClosedAsync(Circuit circuit, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Circuit {CircuitId} closed", circuit.Id);
        return Task.CompletedTask;
    }
}