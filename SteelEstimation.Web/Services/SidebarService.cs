using Microsoft.JSInterop;

namespace SteelEstimation.Web.Services
{
    public class SidebarService
    {
        private readonly IJSRuntime _jsRuntime;
        private bool _isOpen = true; // Default to open
        
        public event Action? OnChange;
        
        public bool IsOpen 
        { 
            get => _isOpen;
            private set
            {
                if (_isOpen != value)
                {
                    _isOpen = value;
                    NotifyStateChanged();
                }
            }
        }
        
        public SidebarService(IJSRuntime jsRuntime)
        {
            _jsRuntime = jsRuntime;
        }
        
        public async Task InitializeAsync()
        {
            try
            {
                // Get saved state from localStorage, default to open
                var savedState = await _jsRuntime.InvokeAsync<string>("localStorage.getItem", "sidebarOpen");
                IsOpen = string.IsNullOrEmpty(savedState) ? true : savedState.ToLower() == "true";
                
                // Update DOM to match the state
                await UpdateDomAsync();
            }
            catch
            {
                IsOpen = true; // Default to open on error
                try
                {
                    await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "sidebarOpen", "true");
                    await UpdateDomAsync();
                }
                catch { }
            }
        }
        
        public async Task ToggleAsync()
        {
            IsOpen = !IsOpen;
            
            try
            {
                await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "sidebarOpen", IsOpen.ToString().ToLower());
                
                // Update DOM using proper JS interop instead of eval
                await UpdateDomAsync();
            }
            catch { }
        }
        
        public async Task UpdateDomAsync()
        {
            try
            {
                // Use proper JS interop method instead of eval
                await _jsRuntime.InvokeVoidAsync("updateSidebarState", IsOpen);
            }
            catch { }
        }
        
        private void NotifyStateChanged() => OnChange?.Invoke();
    }
}